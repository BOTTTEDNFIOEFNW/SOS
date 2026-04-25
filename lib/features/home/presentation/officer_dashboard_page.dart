import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/dialog_utils.dart';
import '../../../data/models/report/dispatch_model.dart';
import '../../../routes/app_routes.dart';
import '../../auth/controller/auth_controller.dart';
import '../../officer/controller/officer_dispatch_controller.dart';
import '../../officer/controller/officer_location_controller.dart';

class OfficerDashboardPage extends StatefulWidget {
  const OfficerDashboardPage({super.key});

  @override
  State<OfficerDashboardPage> createState() => _OfficerDashboardPageState();
}

class _OfficerDashboardPageState extends State<OfficerDashboardPage> {
  static const Color yellow = Color(0xFFF4BB00);
  static const Color softGreen = Color(0xFF2D6858);

  List<DispatchModel> _visibleDispatches(List<DispatchModel> items) {
    final filtered = items.where((item) {
      final status = item.dispatchStatus.toUpperCase();

      return ![
        'COMPLETED',
        'CANCELLED',
      ].contains(status);
    }).toList();

    filtered.sort((a, b) {
      int priority(String status) {
        switch (status.toUpperCase()) {
          case 'ON_THE_WAY':
            return 1;
          case 'ARRIVED':
            return 2;
          case 'HANDLING':
            return 3;
          case 'ACCEPTED':
            return 4;
          case 'ASSIGNED':
            return 5;
          default:
            return 50;
        }
      }

      DateTime dateOf(DispatchModel item) {
        return item.startedAt ??
            item.acceptedAt ??
            item.assignedAt ??
            item.arrivedAt ??
            item.completedAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
      }

      final priorityCompare =
          priority(a.dispatchStatus).compareTo(priority(b.dispatchStatus));

      if (priorityCompare != 0) return priorityCompare;

      return dateOf(b).compareTo(dateOf(a));
    });

    return filtered;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<OfficerDispatchController>().fetchDispatches();
    });
  }

  void _openReportDetail(DispatchModel dispatch) {
    Navigator.pushNamed(
      context,
      AppRoutes.reportDetail,
      arguments: dispatch.reportId,
    );
  }

  Future<void> _openNavigation(DispatchModel dispatch) async {
    final lat = dispatch.report?['latitude']?.toString();
    final lng = dispatch.report?['longitude']?.toString();

    if (lat == null || lng == null || lat.isEmpty || lng.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Koordinat laporan tidak tersedia'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );

    final canOpen = await canLaunchUrl(uri);

    if (!mounted) return;

    if (canOpen) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tidak bisa membuka Google Maps'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showRejectNotesDialog(DispatchModel dispatch) async {
    final notesController = TextEditingController();

    final notes = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            decoration: BoxDecoration(
              color: const Color(0xFF063B25).withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.close_rounded,
                  color: Color(0xFFF87171),
                  size: 42,
                ),
                const SizedBox(height: 14),
                const Text(
                  'Reject Dispatch',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Berikan alasan kenapa dispatch ini ditolak.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: notesController,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Contoh: Sedang tidak bisa menuju lokasi.',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: Color(0xFFF87171),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext, null),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final value = notesController.text.trim();

                          Navigator.pop(
                            dialogContext,
                            value.isEmpty
                                ? 'Dispatch rejected by officer'
                                : value,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF87171),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'Reject',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    notesController.dispose();

    if (!mounted) return;
    if (notes == null) return;

    final dispatchController = context.read<OfficerDispatchController>();

    final success = await dispatchController.rejectDispatch(
      dispatchId: dispatch.id,
      notes: notes,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Dispatch ditolak'
              : (dispatchController.errorMessage ?? 'Gagal reject dispatch'),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showCompleteNotesDialog(DispatchModel dispatch) async {
    final notesController = TextEditingController();

    final notes = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            decoration: BoxDecoration(
              color: const Color(0xFF063B25).withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.task_alt_rounded,
                  color: Color(0xFFF4BB00),
                  size: 42,
                ),
                const SizedBox(height: 14),
                const Text(
                  'Selesaikan Dispatch',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Isi catatan penyelesaian tugas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: notesController,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Contoh: Pasien sudah dibantu dan aman.',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: Color(0xFFF4BB00),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext, null),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final value = notesController.text.trim();

                          if (value.isEmpty) {
                            Navigator.pop(
                              dialogContext,
                              'Dispatch completed by officer',
                            );
                            return;
                          }

                          Navigator.pop(dialogContext, value);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF4BB00),
                          foregroundColor: const Color(0xFF173B2D),
                        ),
                        child: const Text(
                          'Selesai',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    notesController.dispose();

    if (!mounted) return;
    if (notes == null) return;

    await _handleCompleteWithNotes(dispatch, notes);
  }

  Future<void> _handleCompleteWithNotes(
    DispatchModel dispatch,
    String notes,
  ) async {
    final dispatchController = context.read<OfficerDispatchController>();
    final locationController = context.read<OfficerLocationController>();

    final success = await dispatchController.completeDispatch(
      dispatchId: dispatch.id,
      notes: notes,
    );

    if (!mounted) return;

    if (success) {
      await locationController.stopLiveTracking();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dispatch selesai'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          dispatchController.errorMessage ?? 'Gagal menyelesaikan dispatch',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _refresh() async {
    if (!mounted) return;

    final controller = context.read<OfficerDispatchController>();

    await controller.fetchDispatches();

    if (!mounted) return;
  }

  ({Color bg, Color text}) _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ASSIGNED':
        return (bg: const Color(0xFFFFEDD5), text: const Color(0xFFEA580C));
      case 'ACCEPTED':
        return (bg: const Color(0xFFE0F2FE), text: const Color(0xFF0284C7));
      case 'ON_THE_WAY':
        return (bg: const Color(0xFFDBEAFE), text: const Color(0xFF2563EB));
      case 'ARRIVED':
        return (bg: const Color(0xFFDCFCE7), text: const Color(0xFF16A34A));
      case 'HANDLING':
        return (bg: const Color(0xFFFEF3C7), text: const Color(0xFFD97706));
      case 'COMPLETED':
        return (bg: const Color(0xFFE2E8F0), text: const Color(0xFF334155));
      case 'CANCELLED':
        return (bg: const Color(0xFFFEE2E2), text: const Color(0xFFDC2626));
      default:
        return (bg: const Color(0xFFE2E8F0), text: const Color(0xFF475569));
    }
  }

  Future<void> _handleAccept(DispatchModel dispatch) async {
    final dispatchController = context.read<OfficerDispatchController>();
    final success = await dispatchController.acceptDispatch(dispatch.id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Dispatch berhasil diterima'
              : (dispatchController.errorMessage ?? 'Gagal menerima dispatch'),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleStart(DispatchModel dispatch) async {
    final dispatchController = context.read<OfficerDispatchController>();
    final locationController = context.read<OfficerLocationController>();

    final success = await dispatchController.startDispatch(dispatch.id);

    if (success) {
      await locationController.startLiveTracking(
        reportId: dispatch.reportId,
        interval: const Duration(seconds: 10),
      );
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Dispatch dimulai, live tracking aktif'
              : (dispatchController.errorMessage ?? 'Gagal memulai dispatch'),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleArrive(DispatchModel dispatch) async {
    final dispatchController = context.read<OfficerDispatchController>();
    final success = await dispatchController.arriveDispatch(dispatch.id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Status tiba di lokasi berhasil diperbarui'
              : (dispatchController.errorMessage ?? 'Gagal update arrival'),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  int _activeDispatchCount(List<DispatchModel> dispatches) {
    return dispatches
        .where(
          (item) => ![
            'COMPLETED',
            'CANCELLED',
          ].contains(item.dispatchStatus.toUpperCase()),
        )
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final dispatchController = context.watch<OfficerDispatchController>();
    final locationController = context.watch<OfficerLocationController>();

    final officerName = authController.currentUser?.fullName.isNotEmpty == true
        ? authController.currentUser!.fullName
        : 'Officer';

    final activeCount = _activeDispatchCount(dispatchController.dispatches);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/dashboard/home-page.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          SafeArea(
            child: RefreshIndicator(
              color: softGreen,
              backgroundColor: yellow,
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 34),
                children: [
                  _OfficerHeader(
                    officerName: officerName,
                    onLogoutTap: () async {
                      await showLogoutConfirmation(
                        context,
                        () async {
                          await locationController.stopLiveTracking();
                          await authController.logout();

                          if (!context.mounted) return;

                          Navigator.pushReplacementNamed(
                            context,
                            AppRoutes.login,
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  _OfficerSummaryCard(
                    activeDispatchCount: activeCount,
                    totalDispatchCount: dispatchController.dispatches.length,
                    isSharingLocation: locationController.isSharingLocation,
                  ),
                  const SizedBox(height: 16),
                  _DutyStatusCard(
                    isSharingLocation: locationController.isSharingLocation,
                    errorMessage: locationController.errorMessage,
                  ),
                  const SizedBox(height: 20),
                  const _SectionTitle(title: 'Dispatch Masuk'),
                  const SizedBox(height: 12),
                  if (dispatchController.isLoading &&
                      dispatchController.dispatches.isEmpty)
                    const _LoadingCard()
                  else if (dispatchController.errorMessage != null &&
                      dispatchController.dispatches.isEmpty)
                    _ErrorCard(
                      message: dispatchController.errorMessage!,
                      onRetry: _refresh,
                    )
                  else if (_visibleDispatches(dispatchController.dispatches)
                      .isEmpty)
                    const _EmptyDispatchCard()
                  else
                    ..._visibleDispatches(dispatchController.dispatches)
                        .map((dispatch) {
                      final style = _statusColor(dispatch.dispatchStatus);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _DispatchActionCard(
                          dispatch: dispatch,
                          statusBg: style.bg,
                          statusText: style.text,
                          isActionLoading: dispatchController.isActionLoading,
                          onDetail: () => _openReportDetail(dispatch),
                          onNavigate: () => _openNavigation(dispatch),
                          onAccept: () => _handleAccept(dispatch),
                          onReject: () => _showRejectNotesDialog(dispatch),
                          onStart: () => _handleStart(dispatch),
                          onArrive: () => _handleArrive(dispatch),
                          onComplete: () => _showCompleteNotesDialog(dispatch),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfficerHeader extends StatelessWidget {
  final String officerName;
  final VoidCallback onLogoutTap;

  const _OfficerHeader({
    required this.officerName,
    required this.onLogoutTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Officer Dashboard',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.78),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                officerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: onLogoutTap,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            child: const Icon(
              Icons.logout_rounded,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _OfficerSummaryCard extends StatelessWidget {
  final int activeDispatchCount;
  final int totalDispatchCount;
  final bool isSharingLocation;

  const _OfficerSummaryCard({
    required this.activeDispatchCount,
    required this.totalDispatchCount,
    required this.isSharingLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _SummaryItem(
            label: 'Aktif',
            value: activeDispatchCount.toString(),
            icon: Icons.local_shipping_outlined,
          ),
          Container(
            width: 1,
            height: 50,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            color: Colors.white.withValues(alpha: 0.14),
          ),
          _SummaryItem(
            label: 'Total',
            value: totalDispatchCount.toString(),
            icon: Icons.assignment_outlined,
          ),
          Container(
            width: 1,
            height: 50,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            color: Colors.white.withValues(alpha: 0.14),
          ),
          _SummaryItem(
            label: 'Tracking',
            value: isSharingLocation ? 'ON' : 'OFF',
            icon: Icons.location_searching_rounded,
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            color: const Color(0xFFF4BB00),
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.68),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DutyStatusCard extends StatelessWidget {
  final bool isSharingLocation;
  final String? errorMessage;

  const _DutyStatusCard({
    required this.isSharingLocation,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor =
        isSharingLocation ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isSharingLocation
            ? const Color(0xFF16A34A).withValues(alpha: 0.22)
            : Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: activeColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              isSharingLocation
                  ? Icons.location_searching_rounded
                  : Icons.location_disabled_outlined,
              color: activeColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Live Tracking',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.70),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isSharingLocation ? 'Aktif Mengirim Lokasi' : 'Tidak Aktif',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                if (errorMessage != null && errorMessage!.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    errorMessage!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFFCA5A5),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isSharingLocation
                  ? const Color(0xFF86EFAC)
                  : Colors.white.withValues(alpha: 0.40),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _DispatchActionCard extends StatelessWidget {
  final DispatchModel dispatch;
  final Color statusBg;
  final Color statusText;
  final bool isActionLoading;
  final VoidCallback onAccept;
  final VoidCallback onStart;
  final VoidCallback onArrive;
  final VoidCallback onComplete;
  final VoidCallback onDetail;
  final VoidCallback onNavigate;
  final VoidCallback onReject;

  const _DispatchActionCard(
      {required this.dispatch,
      required this.statusBg,
      required this.statusText,
      required this.isActionLoading,
      required this.onAccept,
      required this.onStart,
      required this.onDetail,
      required this.onNavigate,
      required this.onArrive,
      required this.onComplete,
      required this.onReject});

  String _formatText(String value) {
    return value.replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final reportCode =
        dispatch.report?['reportCode']?.toString() ?? 'No report code';
    final emergencyType = dispatch.report?['emergencyType']?.toString() ?? '-';
    final address = dispatch.report?['addressSnapshot']?.toString() ?? '-';
    final status = dispatch.dispatchStatus.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D6858).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.emergency_share_outlined,
                  color: Color(0xFF2D6858),
                  size: 28,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reportCode,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF173B2D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatText(emergencyType),
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFF173B2D).withValues(alpha: 0.70),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _formatText(status),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: statusText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: Color(0xFF2D6858),
                  size: 22,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF475569),
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniActionButton(
                  label: 'Detail',
                  icon: Icons.description_outlined,
                  onTap: onDetail,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniActionButton(
                  label: 'Navigate',
                  icon: Icons.navigation_outlined,
                  onTap: onNavigate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (status == 'ASSIGNED')
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'Reject',
                    icon: Icons.close_rounded,
                    onPressed: isActionLoading ? null : onReject,
                    bgColor: const Color(0xFFF87171),
                    textColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    label: 'Terima',
                    icon: Icons.check_circle_outline_rounded,
                    onPressed: isActionLoading ? null : onAccept,
                    bgColor: const Color(0xFFF4BB00),
                    textColor: const Color(0xFF173B2D),
                  ),
                ),
              ],
            ),
          if (status == 'ACCEPTED')
            _ActionButton(
              label: 'Mulai Menuju Lokasi',
              icon: Icons.navigation_outlined,
              onPressed: isActionLoading ? null : onStart,
              bgColor: const Color(0xFF2D6858),
              textColor: Colors.white,
            ),
          if (status == 'ON_THE_WAY')
            _ActionButton(
              label: 'Tandai Sudah Tiba',
              icon: Icons.place_outlined,
              onPressed: isActionLoading ? null : onArrive,
              bgColor: const Color(0xFF16A34A),
              textColor: Colors.white,
            ),
          if (status == 'ARRIVED' || status == 'HANDLING')
            _ActionButton(
              label: 'Selesaikan Dispatch',
              icon: Icons.task_alt_rounded,
              onPressed: isActionLoading ? null : onComplete,
              bgColor: const Color(0xFF173B2D),
              textColor: Colors.white,
            ),
          if (status == 'COMPLETED')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Dispatch Selesai',
                style: TextStyle(
                  color: Color(0xFF16A34A),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color bgColor;
  final Color textColor;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          disabledBackgroundColor: bgColor.withValues(alpha: 0.52),
          disabledForegroundColor: textColor.withValues(alpha: 0.70),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
      ),
    );
  }
}

class _MiniActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _MiniActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF2D6858),
          side: BorderSide(
            color: const Color(0xFF2D6858).withValues(alpha: 0.28),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: const CircularProgressIndicator(
        color: Color(0xFFF4BB00),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFF4BB00),
            size: 36,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'Coba Lagi',
              style: TextStyle(
                color: Color(0xFFF4BB00),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDispatchCard extends StatelessWidget {
  const _EmptyDispatchCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 26),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: const Color(0xFFF4BB00).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.inbox_outlined,
              size: 34,
              color: Color(0xFFF4BB00),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Belum Ada Dispatch',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Dispatch baru akan muncul di sini saat admin atau sistem auto assign menugaskan Anda.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.72),
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
