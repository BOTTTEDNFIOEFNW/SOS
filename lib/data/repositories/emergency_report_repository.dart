import '../models/report/create_emergency_report_request_model.dart';
import '../models/report/dispatch_model.dart';
import '../models/report/emergency_report_model.dart';
import '../models/report/pagination_meta_model.dart';
import '../services/emergency_report_api_service.dart';
import '../models/report/officer_location_model.dart';

class EmergencyReportRepository {
  final EmergencyReportApiService emergencyReportApiService;

  EmergencyReportRepository({
    required this.emergencyReportApiService,
  });

  Future<void> createReport(CreateEmergencyReportRequestModel request) async {
    await emergencyReportApiService.createReport(request);
  }

  Future<({List<EmergencyReportModel> items, PaginationMetaModel meta})>
      getMyReports({
    int page = 1,
    int limit = 20,
  }) async {
    return emergencyReportApiService.getMyReports(
      page: page,
      limit: limit,
    );
  }

  Future<EmergencyReportModel> getReportDetail(String reportId) async {
    return emergencyReportApiService.getReportDetail(reportId);
  }

  Future<List<DispatchModel>> getDispatchByReport(String reportId) async {
    return emergencyReportApiService.getDispatchByReport(reportId);
  }

  Future<OfficerLocationModel?> getLatestOfficerLocation(
    String reportId,
  ) async {
    return emergencyReportApiService.getLatestOfficerLocation(reportId);
  }
}
