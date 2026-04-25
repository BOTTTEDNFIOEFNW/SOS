import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sos/services/location_service.dart';

import '../../../core/utils/dialog_utils.dart';
import '../../../routes/app_routes.dart';
import '../../auth/controller/auth_controller.dart';
import '../../report/presentation/emergency_report_form_page.dart';

import '../../../data/models/service_model.dart';
import '../../../core/utils/file_url_helper.dart';
import '../controller/service_controller.dart';

class _ServiceActionCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback? onTap;

  const _ServiceActionCard({
    required this.service,
    this.onTap,
  });

  Color get serviceColor {
    final hex = service.colorHex;

    if (hex == null || hex.isEmpty) {
      return const Color(0xFFFFC928);
    }

    final cleaned = hex.replaceAll('#', '');

    if (cleaned.length != 6) {
      return const Color(0xFFFFC928);
    }

    return Color(int.parse('FF$cleaned', radix: 16));
  }

  IconData get iconFromDatabase {
    final iconName = (service.iconName ?? '').toLowerCase().trim();
    final code = service.serviceCode.toUpperCase();

    if (iconName.contains('ambulance')) return Icons.local_hospital_rounded;
    if (iconName.contains('fire')) return Icons.local_fire_department_rounded;
    if (iconName.contains('police') || iconName.contains('shield')) {
      return Icons.shield_outlined;
    }
    if (iconName.contains('hospital')) return Icons.medical_services_outlined;
    if (iconName.contains('sos')) return Icons.sos;
    if (iconName.contains('emergency')) return Icons.emergency_rounded;

    if (code.contains('AMBULANCE')) return Icons.local_hospital_rounded;
    if (code.contains('FIRE')) return Icons.local_fire_department_rounded;
    if (code.contains('POLICE') || code.contains('CRIME')) {
      return Icons.shield_outlined;
    }
    if (code.contains('HOSPITAL')) return Icons.medical_services_outlined;

    return Icons.emergency_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final iconUrl = resolveFileUrl(service.iconUrl);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 142,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.10),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 66,
                height: 66,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: serviceColor.withValues(alpha: 0.32),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: iconUrl.isNotEmpty
                    ? Image.network(
                        iconUrl,
                        fit: BoxFit.contain,
                        width: 54,
                        height: 54,
                        errorBuilder: (_, __, ___) {
                          return Icon(
                            iconFromDatabase,
                            color: Colors.white,
                            size: 38,
                          );
                        },
                      )
                    : Icon(
                        iconFromDatabase,
                        color: Colors.white,
                        size: 38,
                      ),
              ),
              const Spacer(),
              Text(
                service.serviceName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DynamicServicesGrid extends StatelessWidget {
  final ServiceController controller;

  const _DynamicServicesGrid({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }

    if (controller.errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.10),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFFFC928),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Gagal memuat layanan',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: controller.fetchActiveServices,
              child: const Text(
                'Coba Lagi',
                style: TextStyle(
                  color: Color(0xFFFFC928),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (controller.services.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.10),
          ),
        ),
        child: Text(
          'Belum ada layanan aktif',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.80),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return GridView.builder(
      itemCount: controller.services.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.12,
      ),
      itemBuilder: (context, index) {
        final service = controller.services[index];

        return _ServiceActionCard(
          service: service,
          onTap: () {
            if (!service.requiresDispatch) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${service.serviceName} belum membutuhkan laporan dispatch',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EmergencyReportFormPage(
                  serviceId: service.id,
                  initialEmergencyType: service.serviceCode,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class UserDashboardPage extends StatefulWidget {
  const UserDashboardPage({super.key});

  @override
  State<UserDashboardPage> createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends State<UserDashboardPage> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<ServiceController>().fetchActiveServices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final serviceController = context.watch<ServiceController>();

    final userName = authController.currentUser?.fullName.isNotEmpty == true
        ? authController.currentUser!.fullName
        : 'Pengguna';

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
              color: const Color(0xFF2D6858),
              backgroundColor: const Color(0xFFF4BB00),
              onRefresh: () async {
                await context.read<ServiceController>().fetchActiveServices();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 34),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _UserDashboardHeader(
                      userName: userName,
                      onLogoutTap: () async {
                        await showLogoutConfirmation(
                          context,
                          () async {
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
                    const SizedBox(height: 28),
                    const _UserLocationCard(),
                    const SizedBox(height: 18),
                    const _SectionTitle(title: 'Layanan Cepat'),
                    const SizedBox(height: 12),
                    _DynamicServicesGrid(
                      controller: serviceController,
                    ),
                    const SizedBox(height: 16),
                    _WideActionCard(
                      title: 'Riwayat Laporan',
                      subtitle: 'Lihat status dan detail laporan Anda',
                      icon: Icons.receipt_long_outlined,
                      iconColor: const Color(0xFF2D6858),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.reportHistory,
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    const _VerificationCard(),
                    const SizedBox(height: 26),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserDashboardHeader extends StatelessWidget {
  final String userName;
  final VoidCallback onLogoutTap;

  const _UserDashboardHeader({
    required this.userName,
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
                'Selamat Datang',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.78),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                userName,
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

class _UserLocationCard extends StatefulWidget {
  const _UserLocationCard();

  @override
  State<_UserLocationCard> createState() => _UserLocationCardState();
}

class _UserLocationCardState extends State<_UserLocationCard> {
  String locationText = 'Mendeteksi lokasi...';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    try {
      final position = await LocationService.getCurrentPosition();

      final address = await LocationService.getAddressFromLatLng(
        position.latitude,
        position.longitude,
      );

      setState(() {
        locationText = address;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        locationText = 'Lokasi tidak tersedia';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 98,
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: const DecorationImage(
          image: AssetImage('assets/images/dashboard/loc-component.png'),
          fit: BoxFit.cover,
          alignment: Alignment.center,
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
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white.withValues(alpha: 0.20),
            child: const Icon(
              Icons.location_on_outlined,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lokasi Aktif',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  locationText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : IconButton(
                  onPressed: _loadLocation,
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: Color(0xFFFFC928),
                    size: 25,
                  ),
                ),
        ],
      ),
    );
  }
}

class _WideActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;

  const _WideActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF4BB00),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF2D6858).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF2D6858),
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF173B2D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF173B2D).withValues(alpha: 0.72),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF173B2D),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerificationCard extends StatelessWidget {
  const _VerificationCard();

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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7).withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.verified_rounded,
              color: Color(0xFF16A34A),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status Akun',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.68),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Terverifikasi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF86EFAC),
            size: 24,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
