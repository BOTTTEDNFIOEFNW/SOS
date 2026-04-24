import '../../core/storage/secure_storage_service.dart';
import '../models/auth/login_request_model.dart';
import '../models/auth/login_response_model.dart';
import '../models/auth/register_request_model.dart';
import '../models/auth/user_model.dart';
import '../services/auth_api_service.dart';
import '../models/auth/forgot_password_request_model.dart';
import '../models/auth/verify_otp_request_model.dart';
import '../models/auth/reset_forgot_password_request_model.dart';

class AuthRepository {
  final AuthApiService authApiService;
  final SecureStorageService secureStorageService;

  AuthRepository({
    required this.authApiService,
    required this.secureStorageService,
  });

  Future<LoginResponseModel> loginUser({
    required String phoneNumber,
    required String password,
  }) async {
    final result = await authApiService.loginUser(
      LoginRequestModel(
        phoneNumber: phoneNumber,
        password: password,
      ),
    );

    await secureStorageService.saveAccessToken(result.accessToken);
    await secureStorageService.saveRefreshToken(result.refreshToken);
    await secureStorageService.saveUserType(result.user.type);

    return result;
  }

  Future<LoginResponseModel> loginOfficer({
    required String email,
    required String password,
  }) async {
    final result = await authApiService.loginOfficer(
      LoginRequestModel(
        email: email,
        password: password,
      ),
    );

    await secureStorageService.saveAccessToken(result.accessToken);
    await secureStorageService.saveRefreshToken(result.refreshToken);
    await secureStorageService.saveUserType(result.user.type);

    return result;
  }

  Future<void> register({
    required String fullName,
    required String nik,
    required String phoneNumber,
    required String address,
    required String password,
  }) async {
    await authApiService.register(
      RegisterRequestModel(
        fullName: fullName,
        nik: nik,
        phoneNumber: phoneNumber,
        address: address,
        password: password,
      ),
    );
  }

  Future<UserModel> getMe() async {
    return authApiService.getMe();
  }

  Future<bool> hasSession() async {
    final token = await secureStorageService.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    final refreshToken = await secureStorageService.getRefreshToken();

    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await authApiService.logout(refreshToken: refreshToken);
      }
    } catch (_) {
      // backend logout failure should not block local logout
    } finally {
      await secureStorageService.clearSession();
    }
  }

  Future<void> clearSession() async {
    await secureStorageService.clearSession();
  }

  Future<String?> getAccessToken() async {
    return secureStorageService.getAccessToken();
  }

  Future<void> requestForgotPasswordOtp({
    required String phoneNumber,
  }) async {
    await authApiService.requestForgotPasswordOtp(
      ForgotPasswordRequestModel(
        phoneNumber: phoneNumber,
      ),
    );
  }

  Future<void> verifyForgotPasswordOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    await authApiService.verifyForgotPasswordOtp(
      VerifyOtpRequestModel(
        phoneNumber: phoneNumber,
        otp: otp,
      ),
    );
  }

  Future<void> resetForgotPassword({
    required String phoneNumber,
    required String otp,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await authApiService.resetForgotPassword(
      ResetForgotPasswordRequestModel(
        phoneNumber: phoneNumber,
        otp: otp,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      ),
    );
  }

  Future<LoginResponseModel> loginMobile({
    required String identifier,
    required String password,
  }) async {
    final result = await authApiService.loginMobile(
      LoginRequestModel(
        identifier: identifier,
        password: password,
      ),
    );

    await secureStorageService.saveAccessToken(result.accessToken);
    await secureStorageService.saveRefreshToken(result.refreshToken);
    await secureStorageService.saveUserType(result.user.type);

    return result;
  }
}
