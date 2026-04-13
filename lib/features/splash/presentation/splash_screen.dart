import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../../auth/controller/auth_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authController = context.read<AuthController>();
    final hasSession = await authController.hasSession();

    if (!mounted) return;

    Navigator.pushReplacementNamed(
      context,
      hasSession ? AppRoutes.home : AppRoutes.login,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: Center(
        child: Image.asset(
          AppAssets.logo,
          width: 180,
        ),
      ),
    );
  }
}
