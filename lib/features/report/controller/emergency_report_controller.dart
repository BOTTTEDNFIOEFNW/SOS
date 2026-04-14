import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/network/app_exception.dart';
import '../../../data/models/report/create_emergency_report_request_model.dart';
import '../../../data/models/report/dispatch_model.dart';
import '../../../data/models/report/emergency_report_model.dart';
import '../../../data/models/report/pagination_meta_model.dart';
import '../../../data/repositories/emergency_report_repository.dart';
import '../../../data/models/report/officer_location_model.dart';

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
  String? errorMessage;

  List<EmergencyReportModel> reports = [];
  PaginationMetaModel? historyMeta;
  EmergencyReportModel? selectedReport;
  OfficerLocationModel? latestOfficerLocation;
  List<DispatchModel> dispatches = [];

  Future<bool> submitReport({
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

      await emergencyReportRepository.createReport(
        CreateEmergencyReportRequestModel(
          emergencyType: emergencyType,
          description: description,
          latitude: latitude,
          longitude: longitude,
          addressSnapshot: addressSnapshot,
          photoCapturedAt: photoCapturedAt,
          photo: photo,
        ),
      );

      return true;
    } on AppException catch (error) {
      errorMessage = error.message;
      return false;
    } catch (_) {
      errorMessage = 'Gagal mengirim laporan. Silakan coba lagi.';
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> fetchMyReports({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      isLoadingHistory = true;
      errorMessage = null;
      notifyListeners();

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

  Future<bool> fetchReportDetail(String reportId) async {
    try {
      isLoadingDetail = true;
      errorMessage = null;
      notifyListeners();

      selectedReport =
          await emergencyReportRepository.getReportDetail(reportId);

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

  Future<bool> fetchDispatchByReport(String reportId) async {
    try {
      isLoadingDispatch = true;
      errorMessage = null;
      notifyListeners();

      dispatches =
          await emergencyReportRepository.getDispatchByReport(reportId);

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

  Future<bool> fetchLatestOfficerLocation(String reportId) async {
    try {
      isLoadingOfficerLocation = true;
      errorMessage = null;
      notifyListeners();

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

  void clearSelectedReport() {
    selectedReport = null;
    dispatches = [];
    latestOfficerLocation = null;
    notifyListeners();
  }
}
