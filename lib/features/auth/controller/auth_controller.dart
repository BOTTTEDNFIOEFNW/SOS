import 'package:flutter/material.dart';
import '../../../core/network/app_exception.dart';
import '../../../data/models/auth/user_model.dart';
import '../../../data/repositories/auth_repository.dart';

class AuthController extends ChangeNotifier {
  final AuthRepository authRepository;

  AuthController({required this.authRepository});

  bool isLoading = false;
  String? errorMessage;
  UserModel? currentUser;
  String? accessToken;

  Future<bool> loginUser({
    required String phoneNumber,
    required String password,
  }) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final result = await authRepository.loginUser(
        phoneNumber: phoneNumber,
        password: password,
      );

      currentUser = result.user;
      accessToken = result.accessToken;
      return true;
    } on AppException catch (error) {
      errorMessage = error.message;
      return false;
    } catch (_) {
      errorMessage = 'Login failed. Please try again.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loginOfficer({
    required String email,
    required String password,
  }) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final result = await authRepository.loginOfficer(
        email: email,
        password: password,
      );

      currentUser = result.user;
      accessToken = result.accessToken;
      return true;
    } on AppException catch (error) {
      errorMessage = error.message;
      return false;
    } catch (_) {
      errorMessage = 'Officer login failed. Please try again.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String fullName,
    required String nik,
    required String phoneNumber,
    required String address,
    required String password,
  }) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      await authRepository.register(
        fullName: fullName,
        nik: nik,
        phoneNumber: phoneNumber,
        address: address,
        password: password,
      );

      return true;
    } on AppException catch (error) {
      errorMessage = error.message;
      return false;
    } catch (_) {
      errorMessage = 'Registration failed. Please try again.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> hydrateUser() async {
    try {
      final user = await authRepository.getMe();
      final token = await authRepository.getAccessToken();

      currentUser = user;
      accessToken = token;

      notifyListeners();
      return true;
    } catch (_) {
      currentUser = null;
      accessToken = null;
      notifyListeners();
      return false;
    }
  }

  Future<bool> checkSessionAndHydrate() async {
    final hasSession = await authRepository.hasSession();

    if (!hasSession) {
      currentUser = null;
      accessToken = null;
      notifyListeners();
      return false;
    }

    final hydrated = await hydrateUser();

    if (!hydrated) {
      await authRepository.clearSession();
      currentUser = null;
      accessToken = null;
      notifyListeners();
      return false;
    }

    return true;
  }

  Future<bool> hasSession() async {
    return authRepository.hasSession();
  }

  Future<void> logout() async {
    await authRepository.logout();
    currentUser = null;
    accessToken = null;
    notifyListeners();
  }
}
