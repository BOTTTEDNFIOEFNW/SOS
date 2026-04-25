import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/network/app_exception.dart';
import '../../../data/models/report/create_emergency_report_request_model.dart';
import '../../../data/models/report/dispatch_model.dart';
import '../../../data/models/report/emergency_report_model.dart';
import '../../../data/models/report/officer_location_model.dart';
import '../../../data/models/report/pagination_meta_model.dart';
import '../../../data/repositories/emergency_report_repository.dart';

class EmergencyReportController extends ChangeNotifier {
  final EmergencyReportRepository emergencyReportRepository;

  EmergencyReportController({
    required this.emergencyReportRepository,
  });

  bool isSubmitting = false;
  bool isLoadingHistory = false;
  bool isLoadingDetail = false;
  bool isLoadingDispatch = false;
  bool isLoadingOfficerLocation = false;
  bool isCancellingReport = false;

  String? errorMessage;

  List<EmergencyReportModel> reports = [];
  PaginationMetaModel? historyMeta;
  EmergencyReportModel? selectedReport;
  OfficerLocationModel? latestOfficerLocation;
  List<DispatchModel> dispatches = [];

  Future<EmergencyReportModel?> submitReport({
    String? serviceId,
    required String emergencyType,
    required String description,
    required String latitude,
    required String longitude,
    required String addressSnapshot,
    required DateTime photoCapturedAt,
    required File photo,
  }) async {
    try {
      isSubmitting = true;
      errorMessage = null;
      notifyListeners();

      final report = await emergencyReportRepository.createReport(
        CreateEmergencyReportRequestModel(
          serviceId: serviceId,
          emergencyType: emergencyType,
          description: description,
          latitude: latitude,
          longitude: longitude,
          addressSnapshot: addressSnapshot,
          photoCapturedAt: photoCapturedAt,
          photo: photo,
        ),
      );

      selectedReport = report;

      return report;
    } on AppException catch (error) {
      errorMessage = error.message;
      return null;
    } catch (_) {
      errorMessage = 'Gagal mengirim laporan. Silakan coba lagi.';
      return null;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> fetchMyReports({
    int page = 1,
    int limit = 20,
    bool showLoading = true,
  }) async {
    if (isLoadingHistory) return false;

    try {
      if (showLoading) {
        isLoadingHistory = true;
        notifyListeners();
      }

      errorMessage = null;

      final result = await emergencyReportRepository.getMyReports(
        page: page,
        limit: limit,
      );

      reports = result.items;
      historyMeta = result.meta;

      return true;
    } on AppException catch (error) {
      errorMessage = error.message;
      return false;
    } catch (_) {
      errorMessage = 'Gagal memuat riwayat laporan.';
      return false;
    } finally {
      isLoadingHistory = false;
      notifyListeners();
    }
  }

  Future<bool> fetchReportDetail(
    String reportId, {
    bool showLoading = true,
  }) async {
    if (isLoadingDetail) return false;

    try {
      if (showLoading) {
        isLoadingDetail = true;
        notifyListeners();
      }

      errorMessage = null;

      selectedReport = await emergencyReportRepository.getReportDetail(
        reportId,
      );

      return true;
    } on AppException catch (error) {
      errorMessage = error.message;
      return false;
    } catch (_) {
      errorMessage = 'Gagal memuat detail laporan.';
      return false;
    } finally {
      isLoadingDetail = false;
      notifyListeners();
    }
  }

  Future<bool> fetchDispatchByReport(
    String reportId, {
    bool showLoading = true,
  }) async {
    if (isLoadingDispatch) return false;

    try {
      if (showLoading) {
        isLoadingDispatch = true;
        notifyListeners();
      }

      errorMessage = null;

      dispatches = await emergencyReportRepository.getDispatchByReport(
        reportId,
      );

      return true;
    } on AppException catch (error) {
      errorMessage = error.message;
      return false;
    } catch (_) {
      errorMessage = 'Gagal memuat data dispatch.';
      return false;
    } finally {
      isLoadingDispatch = false;
      notifyListeners();
    }
  }

  Future<bool> fetchLatestOfficerLocation(
    String reportId, {
    bool showLoading = true,
  }) async {
    if (isLoadingOfficerLocation) return false;

    try {
      if (showLoading) {
        isLoadingOfficerLocation = true;
        notifyListeners();
      }

      errorMessage = null;

      latestOfficerLocation =
          await emergencyReportRepository.getLatestOfficerLocation(reportId);

      return true;
    } on AppException catch (error) {
      errorMessage = error.message;
      return false;
    } catch (_) {
      errorMessage = 'Gagal memuat lokasi officer.';
      return false;
    } finally {
      isLoadingOfficerLocation = false;
      notifyListeners();
    }
  }

  Future<bool> refreshReportDetailData(
    String reportId, {
    bool showLoading = false,
  }) async {
    final detailResult = await fetchReportDetail(
      reportId,
      showLoading: showLoading,
    );

    final dispatchResult = await fetchDispatchByReport(
      reportId,
      showLoading: showLoading,
    );

    await fetchLatestOfficerLocation(
      reportId,
      showLoading: showLoading,
    );

    return detailResult && dispatchResult;
  }

  void clearSelectedReport() {
    selectedReport = null;
    dispatches = [];
    latestOfficerLocation = null;
    notifyListeners();
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  Future<bool> cancelReport({
    required String reportId,
    String? notes,
  }) async {
    try {
      isCancellingReport = true;
      errorMessage = null;
      notifyListeners();

      final updatedReport = await emergencyReportRepository.cancelReport(
        reportId: reportId,
        notes: notes,
      );

      selectedReport = updatedReport;

      await fetchDispatchByReport(
        reportId,
        showLoading: false,
      );

      return true;
    } on AppException catch (error) {
      errorMessage = error.message;
      return false;
    } catch (_) {
      errorMessage = 'Gagal membatalkan laporan.';
      return false;
    } finally {
      isCancellingReport = false;
      notifyListeners();
    }
  }
}
