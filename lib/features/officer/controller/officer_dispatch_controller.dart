import 'package:flutter/material.dart';

import '../../../core/network/app_exception.dart';
import '../../../data/models/report/dispatch_model.dart';
import '../../../data/repositories/officer_dispatch_repository.dart';

class OfficerDispatchController extends ChangeNotifier {
  final OfficerDispatchRepository officerDispatchRepository;

  OfficerDispatchController({
    required this.officerDispatchRepository,
  });

  bool isLoading = false;
  bool isActionLoading = false;
  String? errorMessage;
  List<DispatchModel> dispatches = [];
  String officerStatus = 'AVAILABLE';
  bool isStatusLoading = false;

  Future<bool> fetchDispatches() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      dispatches = await officerDispatchRepository.getAllDispatches();
      return true;
    } on AppException catch (error) {
      errorMessage = error.message;
      return false;
    } catch (_) {
      errorMessage = 'Failed to load dispatches.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> acceptDispatch(String dispatchId) async {
    try {
      isActionLoading = true;
      errorMessage = null;
      notifyListeners();

      await officerDispatchRepository.acceptDispatch(dispatchId);
      await fetchDispatches();
      return true;
    } on AppException catch (error) {
      errorMessage = error.message;
      return false;
    } catch (_) {
      errorMessage = 'Failed to accept dispatch.';
      return false;
    } finally {
      isActionLoading = false;
      notifyListeners();
    }
  }

  Future<bool> startDispatch(String dispatchId) async {
    try {
      isActionLoading = true;
      errorMessage = null;
      notifyListeners();

      await officerDispatchRepository.startDispatch(dispatchId);
      await fetchDispatches();
      return true;
    } on AppException catch (error) {
      errorMessage = error.message;
      return false;
    } catch (_) {
      errorMessage = 'Failed to start dispatch.';
      return false;
    } finally {
      isActionLoading = false;
      notifyListeners();
    }
  }

  Future<bool> arriveDispatch(String dispatchId) async {
    try {
      isActionLoading = true;
      errorMessage = null;
      notifyListeners();

      await officerDispatchRepository.arriveDispatch(dispatchId);
      await fetchDispatches();
      return true;
    } on AppException catch (error) {
      errorMessage = error.message;
      return false;
    } catch (_) {
      errorMessage = 'Failed to update arrival.';
      return false;
    } finally {
      isActionLoading = false;
      notifyListeners();
    }
  }

  Future<bool> completeDispatch({
    required String dispatchId,
    String? notes,
  }) async {
    try {
      isActionLoading = true;
      errorMessage = null;
      notifyListeners();

      await officerDispatchRepository.completeDispatch(
        dispatchId: dispatchId,
        notes: notes,
      );
      await fetchDispatches();
      return true;
    } on AppException catch (error) {
      errorMessage = error.message;
      return false;
    } catch (_) {
      errorMessage = 'Failed to complete dispatch.';
      return false;
    } finally {
      isActionLoading = false;
      notifyListeners();
    }
  }

  Future<bool> rejectDispatch({
    required String dispatchId,
    String? notes,
  }) async {
    try {
      isActionLoading = true;
      errorMessage = null;
      notifyListeners();

      await officerDispatchRepository.rejectDispatch(
        dispatchId: dispatchId,
        notes: notes,
      );

      await fetchDispatches();
      return true;
    } on AppException catch (error) {
      errorMessage = error.message;
      return false;
    } catch (_) {
      errorMessage = 'Failed to reject dispatch.';
      return false;
    } finally {
      isActionLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateOfficerStatus(String status) async {
    try {
      isStatusLoading = true;
      errorMessage = null;
      notifyListeners();

      await officerDispatchRepository.updateOfficerStatus(status);

      officerStatus = status;

      return true;
    } on AppException catch (error) {
      errorMessage = error.message;
      return false;
    } catch (_) {
      errorMessage = 'Failed to update officer status.';
      return false;
    } finally {
      isStatusLoading = false;
      notifyListeners();
    }
  }
}
