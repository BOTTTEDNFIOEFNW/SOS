import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/report/emergency_report_model.dart';
import '../../../routes/app_routes.dart';
import '../controller/emergency_report_controller.dart';

class ReportHistoryPage extends StatefulWidget {
  const ReportHistoryPage({super.key});

  @override
  State<ReportHistoryPage> createState() => _ReportHistoryPageState();
}

class _ReportHistoryPageState extends State<ReportHistoryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmergencyReportController>().fetchMyReports();
    });
  }

  Future<void> _refresh() async {
    await context.read<EmergencyReportController>().fetchMyReports();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<EmergencyReportController>();

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
          'Riwayat Laporan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: Builder(
            builder: (context) {
              if (controller.isLoadingHistory && controller.reports.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.errorMessage != null &&
                  controller.reports.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  children: [
                    const SizedBox(height: 80),
                    _ErrorState(
                      message: controller.errorMessage!,
                      onRetry: _refresh,
                    ),
                  ],
                );
              }

              if (controller.reports.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  children: const [
                    SizedBox(height: 80),
                    _EmptyState(),
                  ],
                );
              }

              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
                itemCount: controller.reports.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final report = controller.reports[index];
                  return _ReportHistoryCard(report: report);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ReportHistoryCard extends StatelessWidget {
  final EmergencyReportModel report;

  const _ReportHistoryCard({required this.report});

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd MMM yyyy • HH:mm').format(date);
  }

  ({Color bg, Color text}) _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'REPORTED':
        return (bg: const Color(0xFFF3E8FF), text: const Color(0xFF9333EA));
      case 'ASSIGNED':
        return (bg: const Color(0xFFFFEDD5), text: const Color(0xFFEA580C));
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

  @override
  Widget build(BuildContext context) {
    final statusStyle = _statusColor(report.status);

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.reportDetail,
          arguments: report.id,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF4FF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.description_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.reportCode,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    report.emergencyType.replaceAll('_', ' '),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    report.addressSnapshot?.isNotEmpty == true
                        ? report.addressSnapshot!
                        : '-',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: statusStyle.bg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          report.status.replaceAll('_', ' '),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusStyle.text,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(report.requestedAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
          Icon(Icons.inbox_outlined, size: 48, color: AppColors.textSecondary),
          SizedBox(height: 12),
          Text(
            'Belum ada laporan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Riwayat laporan Anda akan muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({
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
          const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
          const SizedBox(height: 12),
          const Text(
            'Gagal memuat riwayat',
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
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}
