import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/app_exception.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/dio_error_handler.dart';
import '../models/report/create_emergency_report_request_model.dart';
import '../models/report/dispatch_model.dart';
import '../models/report/emergency_report_model.dart';
import '../models/report/pagination_meta_model.dart';
import '../models/report/officer_location_model.dart';

class EmergencyReportApiService {
  final DioClient dioClient;

  EmergencyReportApiService({required this.dioClient});

  Future<void> createReport(CreateEmergencyReportRequestModel request) async {
    try {
      final fileName = request.photo.path.split('/').last;

      final formData = FormData.fromMap({
        if (request.serviceId != null && request.serviceId!.trim().isNotEmpty)
          'serviceId': request.serviceId,
        'emergencyType': request.emergencyType,
        'description': request.description,
        'latitude': request.latitude,
        'longitude': request.longitude,
        'addressSnapshot': request.addressSnapshot,
        'photoCapturedAt': request.photoCapturedAt.toIso8601String(),
        'photo': await MultipartFile.fromFile(
          request.photo.path,
          filename: fileName,
        ),
      });

      await dioClient.dio.post(
        ApiConstants.emergencyReport,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
    } catch (error) {
      if (error is DioException && error.error is AppException) {
        throw error.error as AppException;
      }

      throw DioErrorHandler.handle(error);
    }
  }

  Future<({List<EmergencyReportModel> items, PaginationMetaModel meta})>
      getMyReports({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await dioClient.dio.get(
        '${ApiConstants.emergencyReport}/me',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      final rawData = response.data['data'] as List? ?? [];
      final rawMeta = response.data['meta'] as Map<String, dynamic>? ?? {};

      final items = rawData
          .map(
            (item) => EmergencyReportModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();

      final meta = PaginationMetaModel.fromJson(rawMeta);

      return (items: items, meta: meta);
    } catch (error) {
      if (error is DioException && error.error is AppException) {
        throw error.error as AppException;
      }

      throw DioErrorHandler.handle(error);
    }
  }

  Future<EmergencyReportModel> getReportDetail(String reportId) async {
    try {
      final response = await dioClient.dio.get(
        '${ApiConstants.emergencyReport}/$reportId',
      );

      final rawData = Map<String, dynamic>.from(
        response.data['data'] as Map? ?? {},
      );

      return EmergencyReportModel.fromJson(rawData);
    } catch (error) {
      if (error is DioException && error.error is AppException) {
        throw error.error as AppException;
      }

      throw DioErrorHandler.handle(error);
    }
  }

  Future<List<DispatchModel>> getDispatchByReport(String reportId) async {
    try {
      final response = await dioClient.dio.get(
        '${ApiConstants.dispatch}/report/$reportId',
      );

      final rawData = response.data['data'] as List? ?? [];

      return rawData
          .map(
            (item) => DispatchModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (error) {
      if (error is DioException && error.error is AppException) {
        throw error.error as AppException;
      }

      throw DioErrorHandler.handle(error);
    }
  }

  Future<OfficerLocationModel?> getLatestOfficerLocation(
    String reportId,
  ) async {
    try {
      final response = await dioClient.dio.get(
        '${ApiConstants.officerLocations}/latest/$reportId',
      );

      final data = response.data['data'];
      if (data == null) return null;

      return OfficerLocationModel.fromJson(
        Map<String, dynamic>.from(data as Map),
      );
    } catch (error) {
      if (error is DioException && error.error is AppException) {
        throw error.error as AppException;
      }

      throw DioErrorHandler.handle(error);
    }
  }
}
