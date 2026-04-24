import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String baseUrl = dotenv.env['BASE_URL'] ?? '';
  static String fileBaseUrl = dotenv.env['FILE_BASE_URL'] ?? '';
  static String socketBaseUrl = dotenv.env['SOCKET_URL'] ?? '';

  static const String userLogin = '/auth/login';
  static const String mobileLogin = '/auth/mobile/login';
  static const String userRegister = '/auth/register';
  static const String officerLogin = '/auth/officer/login';

  static const String forgotPasswordRequestOtp =
      '/auth/forgot-password/request-otp';
  static const String forgotPasswordVerifyOtp =
      '/auth/forgot-password/verify-otp';
  static const String forgotPasswordReset = '/auth/forgot-password/reset';

  static const String me = '/auth/me';
  static const String logout = '/auth/logout';

  static const String emergencyReport = '/emergency-reports';
  static const String dispatch = '/dispatches';
  static const String officerLocations = '/officer-locations';
}
