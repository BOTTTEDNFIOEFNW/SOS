import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static bool _isRedirectingToLogin = false;

  static Future<void> redirectToLogin() async {
    if (_isRedirectingToLogin) return;

    _isRedirectingToLogin = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = navigatorKey.currentState;

      if (navigator != null) {
        navigator.pushNamedAndRemoveUntil(
          AppRoutes.login,
          (route) => false,
        );
      }

      Future.delayed(const Duration(milliseconds: 500), () {
        _isRedirectingToLogin = false;
      });
    });
  }
}
