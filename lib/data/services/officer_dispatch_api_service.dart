import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/app_exception.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/dio_error_handler.dart';
import '../models/report/dispatch_model.dart';

class OfficerDispatchApiService {
  final DioClient dioClient;

  OfficerDispatchApiService({
    required this.dioClient,
  });

  Future<List<DispatchModel>> getAllDispatches() async {
    try {
      final response = await dioClient.dio.get(
        ApiConstants.dispatch,
        queryParameters: {
          'page': 1,
          'limit': 50,
        },
      );

      final rawData = response.data['data'] as List? ?? [];

      return rawData
          .map((item) => DispatchModel.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList();
    } catch (error) {
      if (error is DioException && error.error is AppException) {
        throw error.error as AppException;
      }
      throw DioErrorHandler.handle(error);
    }
  }

  Future<void> acceptDispatch(String dispatchId) async {
    try {
      await dioClient.dio.patch('${ApiConstants.dispatch}/$dispatchId/accept');
    } catch (error) {
      if (error is DioException && error.error is AppException) {
        throw error.error as AppException;
      }
      throw DioErrorHandler.handle(error);
    }
  }

  Future<void> startDispatch(String dispatchId) async {
    try {
      await dioClient.dio.patch('${ApiConstants.dispatch}/$dispatchId/start');
    } catch (error) {
      if (error is DioException && error.error is AppException) {
        throw error.error as AppException;
      }
      throw DioErrorHandler.handle(error);
    }
  }

  Future<void> arriveDispatch(String dispatchId) async {
    try {
      await dioClient.dio.patch('${ApiConstants.dispatch}/$dispatchId/arrive');
    } catch (error) {
      if (error is DioException && error.error is AppException) {
        throw error.error as AppException;
      }
      throw DioErrorHandler.handle(error);
    }
  }

  Future<void> completeDispatch({
    required String dispatchId,
    String? notes,
  }) async {
    try {
      await dioClient.dio.patch(
        '${ApiConstants.dispatch}/$dispatchId/complete',
        data: {
          'notes': notes ?? 'Dispatch completed by officer',
        },
      );
    } catch (error) {
      if (error is DioException && error.error is AppException) {
        throw error.error as AppException;
      }
      throw DioErrorHandler.handle(error);
    }
  }

  Future<void> rejectDispatch({
    required String dispatchId,
    String? notes,
  }) async {
    try {
      await dioClient.dio.patch(
        '${ApiConstants.dispatch}/$dispatchId/reject',
        data: {
          'notes': notes ?? 'Dispatch rejected by officer',
        },
      );
    } catch (error) {
      if (error is DioException && error.error is AppException) {
        throw error.error as AppException;
      }

      throw DioErrorHandler.handle(error);
    }
  }

  Future<void> updateOfficerStatus(String status) async {
    try {
      await dioClient.dio.patch(
        ApiConstants.officerMeStatus,
        data: {
          'status': status,
        },
      );
    } catch (error) {
      if (error is DioException && error.error is AppException) {
        throw error.error as AppException;
      }

      throw DioErrorHandler.handle(error);
    }
  }
}
