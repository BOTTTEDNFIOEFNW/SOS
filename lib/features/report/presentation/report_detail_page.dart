import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/report/emergency_report_model.dart';
import '../controller/emergency_report_controller.dart';
import '../../../core/utils/file_url_helper.dart';
import "../../../routes/app_routes.dart";

class ReportDetailPage extends StatefulWidget {
  final String reportId;

  const ReportDetailPage({
    super.key,
    required this.reportId,
  });

  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<EmergencyReportController>().refreshReportDetailData(
            widget.reportId,
            showLoading: true,
          );
    });
  }

  bool _canCancelReport(String status) {
    return ['REPORTED', 'ASSIGNED'].contains(status.toUpperCase());
  }

  Future<void> _showCancelReportDialog(EmergencyReportModel report) async {
    String notesValue = '';

    final notes = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Batalkan Laporan?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            maxLines: 4,
            onChanged: (value) => notesValue = value,
            decoration: const InputDecoration(
              hintText: 'Alasan pembatalan...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, null),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  notesValue.trim().isEmpty
                      ? 'Laporan dibatalkan oleh user'
                      : notesValue.trim(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
              ),
              child: const Text('Batalkan'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    if (notes == null) return;

    final controller = context.read<EmergencyReportController>();

    final success = await controller.cancelReport(
      reportId: report.id,
      notes: notes,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Laporan berhasil dibatalkan'
              : (controller.errorMessage ?? 'Gagal membatalkan laporan'),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: success ? AppColors.primary : AppColors.danger,
      ),
    );
  }

  @override
  void dispose() {
    context.read<EmergencyReportController>().clearSelectedReport();
    super.dispose();
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '-';
    return DateFormat('dd MMM yyyy • HH:mm').format(value.toLocal());
  }

  ({Color bg, Color text}) _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'REPORTED':
        return (
          bg: const Color(0xFFF3E8FF),
          text: const Color(0xFF9333EA),
        );
      case 'ASSIGNED':
        return (
          bg: const Color(0xFFFFEDD5),
          text: const Color(0xFFEA580C),
        );
      case 'ON_THE_WAY':
        return (
          bg: const Color(0xFFDBEAFE),
          text: const Color(0xFF2563EB),
        );
      case 'ARRIVED':
        return (
          bg: const Color(0xFFDCFCE7),
          text: const Color(0xFF16A34A),
        );
      case 'HANDLING':
        return (
          bg: const Color(0xFFFEF3C7),
          text: const Color(0xFFD97706),
        );
      case 'COMPLETED':
        return (
          bg: const Color(0xFFE2E8F0),
          text: const Color(0xFF334155),
        );
      case 'CANCELLED':
        return (
          bg: const Color(0xFFFEE2E2),
          text: const Color(0xFFDC2626),
        );
      default:
        return (
          bg: const Color(0xFFE2E8F0),
          text: const Color(0xFF475569),
        );
    }
  }

  List<_TimelineStep> _buildTimeline(EmergencyReportModel report) {
    final status = report.status.toUpperCase();

    bool active(String target) {
      const order = [
        'REPORTED',
        'ASSIGNED',
        'ON_THE_WAY',
        'ARRIVED',
        'HANDLING',
        'COMPLETED',
      ];

      final currentIndex = order.indexOf(status);
      final targetIndex = order.indexOf(target);

      if (currentIndex == -1 || targetIndex == -1) return false;
      return currentIndex >= targetIndex;
    }

    return [
      _TimelineStep(
        title: 'Dilaporkan',
        subtitle: _formatDate(report.requestedAt),
        isActive: active('REPORTED'),
      ),
      _TimelineStep(
        title: 'Ditugaskan',
        subtitle: _formatDate(report.assignedAt),
        isActive: active('ASSIGNED'),
      ),
      _TimelineStep(
        title: 'Dalam Perjalanan',
        subtitle: status == 'ON_THE_WAY' || active('ON_THE_WAY')
            ? 'Petugas menuju lokasi'
            : '-',
        isActive: active('ON_THE_WAY'),
      ),
      _TimelineStep(
        title: 'Tiba di Lokasi',
        subtitle: _formatDate(report.arrivedAt),
        isActive: active('ARRIVED'),
      ),
      _TimelineStep(
        title: 'Selesai',
        subtitle: _formatDate(report.completedAt),
        isActive: active('COMPLETED'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<EmergencyReportController>();
    final report = controller.selectedReport;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const Text(
          'Detail Laporan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            if (controller.isLoadingDetail) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (controller.errorMessage != null && report == null) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: _DetailErrorState(
                  message: controller.errorMessage!,
                  onRetry: () async {
                    await context
                        .read<EmergencyReportController>()
                        .fetchReportDetail(widget.reportId);
                  },
                ),
              );
            }

            if (report == null) {
              return const Center(
                child: Text('Data laporan tidak ditemukan'),
              );
            }

            final imageUrl = resolveFileUrl(report.photoUrl);
            final statusStyle = _statusColor(report.status);
            final timeline = _buildTimeline(report);

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailHeroCard(
                    reportCode: report.reportCode,
                    emergencyType: report.emergencyType,
                    status: report.status,
                    statusBg: statusStyle.bg,
                    statusTextColor: statusStyle.text,
                    requestedAt: _formatDate(report.requestedAt),
                  ),
                  const SizedBox(height: 16),
                  if (report.photoUrl != null &&
                      report.photoUrl!.trim().isNotEmpty) ...[
                    _SectionCard(
                      title: 'Foto Bukti',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.network(
                                imageUrl,
                                width: double.infinity,
                                height: 220,
                                fit: BoxFit.cover,
                                errorBuilder: (_, error, stackTrace) {
                                  debugPrint('IMAGE ERROR: $error');
                                  debugPrint('FAILED URL: $imageUrl');

                                  return Container(
                                    height: 220,
                                    alignment: Alignment.center,
                                    child: const Text('Gagal memuat foto'),
                                  );
                                },
                              )),
                          const SizedBox(height: 12),
                          _InfoRow(
                            label: 'Waktu Foto',
                            value: _formatDate(report.photoCapturedAt),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _SectionCard(
                    title: 'Informasi Laporan',
                    child: Column(
                      children: [
                        _InfoRow(
                          label: 'Jenis Emergency',
                          value: report.emergencyType.replaceAll('_', ' '),
                        ),
                        _InfoRow(
                          label: 'Deskripsi',
                          value: report.description?.isNotEmpty == true
                              ? report.description!
                              : '-',
                        ),
                        _InfoRow(
                          label: 'Alamat',
                          value: report.addressSnapshot?.isNotEmpty == true
                              ? report.addressSnapshot!
                              : '-',
                        ),
                        _InfoRow(
                          label: 'Latitude',
                          value: report.latitude ?? '-',
                        ),
                        _InfoRow(
                          label: 'Longitude',
                          value: report.longitude ?? '-',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Timeline Status',
                    child: Column(
                      children: timeline
                          .map((item) => _TimelineTile(step: item))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.tracking,
                          arguments: report.id,
                        );
                      },
                      icon: const Icon(Icons.map_outlined),
                      label: const Text(
                        'Lihat Live Tracking',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                  if (_canCancelReport(report.status)) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: controller.isCancellingReport
                            ? null
                            : () => _showCancelReportDialog(report),
                        icon: controller.isCancellingReport
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.cancel_outlined),
                        label: Text(
                          controller.isCancellingReport
                              ? 'Membatalkan...'
                              : 'Batalkan Laporan',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: const BorderSide(color: AppColors.danger),
                          minimumSize: const Size.fromHeight(54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DetailHeroCard extends StatelessWidget {
  final String reportCode;
  final String emergencyType;
  final String status;
  final Color statusBg;
  final Color statusTextColor;
  final String requestedAt;

  const _DetailHeroCard({
    required this.reportCode,
    required this.emergencyType,
    required this.status,
    required this.statusBg,
    required this.statusTextColor,
    required this.requestedAt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2563EB),
            Color(0xFF1D4ED8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reportCode,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            emergencyType.replaceAll('_', ' '),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
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
                    color: statusTextColor,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                requestedAt,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final _TimelineStep step;

  const _TimelineTile({
    required this.step,
  });

  @override
  Widget build(BuildContext context) {
    final color = step.isActive ? AppColors.primary : AppColors.border;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: step.isActive ? AppColors.primary : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
            ),
            Container(
              width: 2,
              height: 44,
              color: color,
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 0, bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: step.isActive
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step.subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _DetailErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: AppColors.danger,
          ),
          const SizedBox(height: 12),
          const Text(
            'Gagal memuat detail laporan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}

class _TimelineStep {
  final String title;
  final String subtitle;
  final bool isActive;

  _TimelineStep({
    required this.title,
    required this.subtitle,
    required this.isActive,
  });
}
