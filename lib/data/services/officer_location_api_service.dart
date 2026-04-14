import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/app_exception.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/dio_error_handler.dart';
import '../models/officer/update_officer_location_request_model.dart';

class OfficerLocationApiService {
  final DioClient dioClient;

  OfficerLocationApiService({
    required this.dioClient,
  });

  Future<void> updateLocation(
    UpdateOfficerLocationRequestModel request,
  ) async {
    try {
      await dioClient.dio.post(
        ApiConstants.officerLocations,
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