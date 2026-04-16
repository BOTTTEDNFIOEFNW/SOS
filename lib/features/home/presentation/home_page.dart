import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/controller/auth_controller.dart';
import 'officer_dashboard_page.dart';
import 'user_dashboard_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  bool _isOfficer(String userType, String role) {
    const officerRoles = {
      'AMBULANCE_DRIVER',
      'PARAMEDIC',
      'FIRE_OFFICER',
      'POLICE',
    };

    return userType == 'OFFICER' || officerRoles.contains(role);
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();

    final userType = authController.currentUser?.type.toUpperCase() ?? 'USER';
    final role = authController.currentUser?.role.toUpperCase() ?? '';

    final isOfficer = _isOfficer(userType, role);

    if (isOfficer) {
      return const OfficerDashboardPage();
    }

    return const UserDashboardPage();
  }
}
