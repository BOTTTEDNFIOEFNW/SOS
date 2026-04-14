import 'package:flutter/material.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/officer_login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/home/presentation/home_page.dart';
import '../features/splash/presentation/splash_screen.dart';
import "../features/report/presentation/emergency_report_form_page.dart";
import "../features/report/presentation/tracking_page.dart";
import "../features/report/presentation/report_history_page.dart";
import "../features/report/presentation/report_detail_page.dart";
import 'app_routes.dart';

class AppPages {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case AppRoutes.register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      case AppRoutes.officerLogin:
        return MaterialPageRoute(builder: (_) => const OfficerLoginScreen());

      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const HomePage());

      case AppRoutes.emergencyReportForm:
        return MaterialPageRoute(
            builder: (_) => const EmergencyReportFormPage());

      case AppRoutes.reportHistory:
        return MaterialPageRoute(
          builder: (_) => const ReportHistoryPage(),
        );

      case AppRoutes.tracking:
        final reportId = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => TrackingPage(reportId: reportId ?? ''),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('Route not found'),
            ),
          ),
        );
    }
  }
}
