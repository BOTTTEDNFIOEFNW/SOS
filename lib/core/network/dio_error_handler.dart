import 'package:dio/dio.dart';
import 'app_exception.dart';

class DioErrorHandler {
  static AppException handle(dynamic error) {
    if (error is DioException) {
      final response = error.response;
      final statusCode = response?.statusCode;
      final data = response?.data;

      String message = 'Something went wrong. Please try again.';

      if (data is Map<String, dynamic>) {
        if (data['message'] != null &&
            data['message'].toString().trim().isNotEmpty) {
          message = data['message'].toString().trim();
        } else if (data['error'] != null &&
            data['error'].toString().trim().isNotEmpty) {
          message = data['error'].toString().trim();
        }
      }

      switch (statusCode) {
        case 400:
          return AppException(
            message: message.isNotEmpty
                ? message
                : 'Invalid request. Please check your input.',
            statusCode: statusCode,
          );

        case 401:
          return AppException(
            message: message.isNotEmpty
                ? message
                : 'Unauthorized. Please login again.',
            statusCode: statusCode,
          );

        case 403:
          return AppException(
            message: message.isNotEmpty
                ? message
                : 'You do not have permission to do this action.',
            statusCode: statusCode,
          );

        case 404:
          return AppException(
            message:
                message.isNotEmpty ? message : 'Requested data was not found.',
            statusCode: statusCode,
          );

        case 409:
          return AppException(
            message: message.isNotEmpty ? message : 'This data already exists.',
            statusCode: statusCode,
          );

        case 422:
          return AppException(
            message: _extractValidationMessage(data) ??
                'Please check the form fields again.',
            statusCode: statusCode,
          );

        case 500:
          return AppException(
            message: 'Server error. Please try again later.',
            statusCode: statusCode,
          );

        default:
          return AppException(
            message: message,
            statusCode: statusCode,
          );
      }
    }

    return AppException(
      message: 'Unexpected error occurred. Please try again.',
    );
  }

  static String? _extractValidationMessage(dynamic data) {
    if (data is! Map<String, dynamic>) return null;

    final errors = data['errors'];

    if (errors is List && errors.isNotEmpty) {
      final first = errors.first;

      if (first is Map<String, dynamic>) {
        final fieldMessage = first['message'];
        if (fieldMessage != null && fieldMessage.toString().trim().isNotEmpty) {
          return fieldMessage.toString().trim();
        }
      }
    }

    final message = data['message'];
    if (message != null && message.toString().trim().isNotEmpty) {
      return message.toString().trim();
    }

    return null;
  }
}
