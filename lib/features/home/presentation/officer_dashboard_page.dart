import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/dialog_utils.dart';
import '../../../routes/app_routes.dart';
import '../../auth/controller/auth_controller.dart';

class OfficerDashboardPage extends StatelessWidget {
  const OfficerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
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
                    await authController.logout();
                    if (!context.mounted) return;
                    Navigator.pushReplacementNamed(context, AppRoutes.login);
                  },
                );
              },
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _DutyStatusCard(),
                    SizedBox(height: 18),
                    _OfficerSectionTitle(title: 'Tugas Aktif'),
                    SizedBox(height: 12),
                    _ActiveDispatchCard(),
                    SizedBox(height: 18),
                    _OfficerSectionTitle(title: 'Aksi Cepat'),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _CompactActionButton(
                            title: 'Accept',
                            bgColor: Color(0xFFFFEDD5),
                            textColor: Color(0xFFEA580C),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _CompactActionButton(
                            title: 'Start',
                            bgColor: Color(0xFFDBEAFE),
                            textColor: Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _CompactActionButton(
                            title: 'Arrive',
                            bgColor: Color(0xFFDCFCE7),
                            textColor: Color(0xFF16A34A),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _CompactActionButton(
                            title: 'Complete',
                            bgColor: Color(0xFFE2E8F0),
                            textColor: Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 18),
                    _OfficerSectionTitle(title: 'Dispatch Inbox'),
                    SizedBox(height: 12),
                    _DispatchInboxCard(
                      reportCode: 'EMG-20260413-001',
                      emergencyType: 'Ambulance',
                      requesterName: 'Ahmad Rizki',
                      location: 'Jl. Persatuan Raya',
                      statusText: 'ASSIGNED',
                      statusBg: Color(0xFFFFEDD5),
                      statusColor: Color(0xFFEA580C),
                    ),
                    SizedBox(height: 12),
                    _DispatchInboxCard(
                      reportCode: 'EMG-20260413-002',
                      emergencyType: 'Fire',
                      requesterName: 'Budi Santoso',
                      location: 'Jl. Sudirman',
                      statusText: 'ON THE WAY',
                      statusBg: Color(0xFFDBEAFE),
                      statusColor: Color(0xFF2563EB),
                    ),
                  ],
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
  const _DutyStatusCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Color(0xFFDCFCE7),
            child: Icon(
              Icons.check_circle_outline,
              color: AppColors.success,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status Shift',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'On Duty',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          _OfficerBadge(
            text: 'ACTIVE',
            bgColor: Color(0xFFDCFCE7),
            textColor: Color(0xFF16A34A),
          ),
        ],
      ),
    );
  }
}

class _ActiveDispatchCard extends StatelessWidget {
  const _ActiveDispatchCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EMG-20260413-001',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Lokasi: Jl. Persatuan Raya',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Requester: Ahmad Rizki',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 14),
          Row(
            children: [
              _OfficerBadge(
                text: 'ON THE WAY',
                bgColor: Color(0xFFDBEAFE),
                textColor: Color(0xFF2563EB),
              ),
              Spacer(),
              Text(
                'ETA 8 menit',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactActionButton extends StatelessWidget {
  final String title;
  final Color bgColor;
  final Color textColor;

  const _CompactActionButton({
    required this.title,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _DispatchInboxCard extends StatelessWidget {
  final String reportCode;
  final String emergencyType;
  final String requesterName;
  final String location;
  final String statusText;
  final Color statusBg;
  final Color statusColor;

  const _DispatchInboxCard({
    required this.reportCode,
    required this.emergencyType,
    required this.requesterName,
    required this.location,
    required this.statusText,
    required this.statusBg,
    required this.statusColor,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  reportCode,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _OfficerBadge(
                text: statusText,
                bgColor: statusBg,
                textColor: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Jenis: $emergencyType',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pelapor: $requesterName',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Lokasi: $location',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _OfficerBadge extends StatelessWidget {
  final String text;
  final Color bgColor;
  final Color textColor;

  const _OfficerBadge({
    required this.text,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _OfficerSectionTitle extends StatelessWidget {
  final String title;

  const _OfficerSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
