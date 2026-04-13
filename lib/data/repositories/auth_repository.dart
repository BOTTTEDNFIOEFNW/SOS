import '../../core/storage/secure_storage_service.dart';
import '../models/auth/login_request_model.dart';
import '../models/auth/login_response_model.dart';
import '../models/auth/register_request_model.dart';
import '../services/auth_api_service.dart';

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

  Future<bool> hasSession() async {
    final token = await secureStorageService.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    await secureStorageService.clearSession();
  }
}
