import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OfficerDispatchController>().fetchDispatches();
    });
  }

  Future<void> _refresh() async {
    await context.read<OfficerDispatchController>().fetchDispatches();
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
      case 'COMPLETED':
        return (bg: const Color(0xFFE2E8F0), text: const Color(0xFF334155));
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
              ? 'Dispatch accepted successfully'
              : (dispatchController.errorMessage ??
                  'Failed to accept dispatch'),
        ),
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
              ? 'Dispatch started successfully'
              : (dispatchController.errorMessage ?? 'Failed to start dispatch'),
        ),
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
              ? 'Arrival updated successfully'
              : (dispatchController.errorMessage ?? 'Failed to update arrival'),
        ),
      ),
    );
  }

  Future<void> _handleComplete(DispatchModel dispatch) async {
    final dispatchController = context.read<OfficerDispatchController>();
    final locationController = context.read<OfficerLocationController>();

    final success = await dispatchController.completeDispatch(
      dispatchId: dispatch.id,
      notes: 'Dispatch completed by officer',
    );

    if (success) {
      await locationController.stopLiveTracking();
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Dispatch completed successfully'
              : (dispatchController.errorMessage ??
                  'Failed to complete dispatch'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final dispatchController = context.watch<OfficerDispatchController>();
    final locationController = context.watch<OfficerLocationController>();

    final officerName = authController.currentUser?.fullName.isNotEmpty == true
        ? authController.currentUser!.fullName
        : 'Officer';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Column(
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
                    Navigator.pushReplacementNamed(context, AppRoutes.login);
                  },
                );
              },
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: Builder(
                  builder: (context) {
                    if (dispatchController.isLoading &&
                        dispatchController.dispatches.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (dispatchController.errorMessage != null &&
                        dispatchController.dispatches.isEmpty) {
                      return ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          const SizedBox(height: 80),
                          Center(
                            child: Text(
                              dispatchController.errorMessage!,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      );
                    }

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
                      children: [
                        _DutyStatusCard(
                          isSharingLocation:
                              locationController.isSharingLocation,
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Dispatch Inbox',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (dispatchController.dispatches.isEmpty)
                          const _EmptyDispatchCard(),
                        ...dispatchController.dispatches.map((dispatch) {
                          final style = _statusColor(dispatch.dispatchStatus);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _DispatchActionCard(
                              dispatch: dispatch,
                              statusBg: style.bg,
                              statusText: style.text,
                              isActionLoading:
                                  dispatchController.isActionLoading,
                              onAccept: () => _handleAccept(dispatch),
                              onStart: () => _handleStart(dispatch),
                              onArrive: () => _handleArrive(dispatch),
                              onComplete: () => _handleComplete(dispatch),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: const BoxDecoration(
        color: AppColors.secondary,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Officer Dashboard',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  officerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
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
                color: Colors.white10,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DutyStatusCard extends StatelessWidget {
  final bool isSharingLocation;

  const _DutyStatusCard({
    required this.isSharingLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: isSharingLocation
                ? const Color(0xFFDCFCE7)
                : const Color(0xFFE2E8F0),
            child: Icon(
              isSharingLocation
                  ? Icons.location_searching
                  : Icons.location_disabled_outlined,
              color: isSharingLocation
                  ? AppColors.success
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Live Tracking',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isSharingLocation ? 'Aktif' : 'Tidak Aktif',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
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

  const _DispatchActionCard({
    required this.dispatch,
    required this.statusBg,
    required this.statusText,
    required this.isActionLoading,
    required this.onAccept,
    required this.onStart,
    required this.onArrive,
    required this.onComplete,
  });

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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_shipping_outlined,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  reportCode,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status.replaceAll('_', ' '),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            emergencyType.replaceAll('_', ' '),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            address,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          if (status == 'ASSIGNED')
            _ActionButton(
              label: 'Accept Dispatch',
              onPressed: isActionLoading ? null : onAccept,
              bgColor: AppColors.warning,
              textColor: Colors.white,
            ),
          if (status == 'ACCEPTED')
            _ActionButton(
              label: 'Start Dispatch',
              onPressed: isActionLoading ? null : onStart,
              bgColor: AppColors.primary,
              textColor: Colors.white,
            ),
          if (status == 'ON_THE_WAY')
            _ActionButton(
              label: 'Mark Arrived',
              onPressed: isActionLoading ? null : onArrive,
              bgColor: AppColors.success,
              textColor: Colors.white,
            ),
          if (status == 'ARRIVED' || status == 'HANDLING')
            _ActionButton(
              label: 'Complete Dispatch',
              onPressed: isActionLoading ? null : onComplete,
              bgColor: AppColors.secondary,
              textColor: Colors.white,
            ),
          if (status == 'COMPLETED')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Dispatch Completed',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
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
  final VoidCallback? onPressed;
  final Color bgColor;
  final Color textColor;

  const _ActionButton({
    required this.label,
    required this.onPressed,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _EmptyDispatchCard extends StatelessWidget {
  const _EmptyDispatchCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 12),
          Text(
            'Belum ada dispatch',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Dispatch yang masuk akan muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
