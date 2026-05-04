import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../navigation/navigation_service.dart';
import '../storage/secure_storage_service.dart';
import 'dio_error_handler.dart';

class DioClient {
  late final Dio dio;
  final SecureStorageService secureStorageService;

  DioClient({required this.secureStorageService}) {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },

        // Karena ini true untuk 401, response 401 masuk ke onResponse,
        // bukan onError. Jadi kita WAJIB handle 401 di onResponse juga.
        validateStatus: (status) {
          return status != null && status < 500;
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await secureStorageService.getAccessToken();

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          handler.next(options);
        },
        onResponse: (response, handler) async {
          final statusCode = response.statusCode ?? 0;

          if (statusCode == 401) {
            await _forceLogout();

            handler.reject(
              DioException(
                requestOptions: response.requestOptions,
                response: response,
                type: DioExceptionType.badResponse,
                error: response.data,
                message: 'Session expired. Please login again.',
              ),
            );
            return;
          }

          if (statusCode >= 400) {
            handler.reject(
              DioException(
                requestOptions: response.requestOptions,
                response: response,
                type: DioExceptionType.badResponse,
                error: response.data,
              ),
            );
            return;
          }

          handler.next(response);
        },
        onError: (error, handler) async {
          final statusCode = error.response?.statusCode ?? 0;

          if (statusCode == 401) {
            await _forceLogout();

            handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                response: error.response,
                type: error.type,
                error: error.error,
                message: 'Session expired. Please login again.',
              ),
            );
            return;
          }

          final handledError = DioErrorHandler.handle(error);

          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: handledError,
              message: handledError.message,
            ),
          );
        },
      ),
    );
  }

  Future<void> _forceLogout() async {
    await secureStorageService.clearSession();

    await NavigationService.redirectToLogin();
  }
}
