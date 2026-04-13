import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/app_exception.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/dio_error_handler.dart';
import '../models/auth/login_request_model.dart';
import '../models/auth/login_response_model.dart';
import '../models/auth/register_request_model.dart';

class AuthApiService {
  final DioClient dioClient;

  AuthApiService({required this.dioClient});

  Future<LoginResponseModel> loginUser(LoginRequestModel request) async {
    try {
      final Response response = await dioClient.dio.post(
        ApiConstants.userLogin,
        data: request.toUserJson(),
      );

      return LoginResponseModel.fromJson(response.data);
    } catch (error) {
      if (error is DioException && error.error is AppException) {
        throw error.error as AppException;
      }

      throw DioErrorHandler.handle(error);
    }
  }

  Future<LoginResponseModel> loginOfficer(LoginRequestModel request) async {
    try {
      final Response response = await dioClient.dio.post(
        ApiConstants.officerLogin,
        data: request.toOfficerJson(),
      );

      return LoginResponseModel.fromJson(response.data);
    } catch (error) {
      if (error is DioException && error.error is AppException) {
        throw error.error as AppException;
      }

      throw DioErrorHandler.handle(error);
    }
  }

  Future<void> register(RegisterRequestModel request) async {
    try {
      await dioClient.dio.post(
        ApiConstants.userRegister,
        data: request.toJson(),
      );
    } catch (error) {
      if (error is DioException && error.error is AppException) {
        throw error.error as AppException;
      }

      throw DioErrorHandler.handle(error);
    }
  }
}
