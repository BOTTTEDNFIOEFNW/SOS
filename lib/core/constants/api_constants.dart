import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String baseUrl = dotenv.env['BASE_URL'] ?? '';

  static const String userLogin = '/auth/login';
  static const String userRegister = '/auth/register';
  static const String officerLogin = '/auth/officer/login';
  static const String me = '/auth/me';
  static const String logout = '/auth/logout';
  static const String emergencyReport = '/emergency-reports';
  static const String dispatch = '/dispatch';
  static const String officerLocations = '/officer-location';
}
