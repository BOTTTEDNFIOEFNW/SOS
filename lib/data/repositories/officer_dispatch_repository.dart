import '../models/report/dispatch_model.dart';
import '../services/officer_dispatch_api_service.dart';

class OfficerDispatchRepository {
  final OfficerDispatchApiService officerDispatchApiService;

  OfficerDispatchRepository({
    required this.officerDispatchApiService,
  });

  Future<List<DispatchModel>> getAllDispatches() {
    return officerDispatchApiService.getAllDispatches();
  }

  Future<void> acceptDispatch(String dispatchId) {
    return officerDispatchApiService.acceptDispatch(dispatchId);
  }

  Future<void> startDispatch(String dispatchId) {
    return officerDispatchApiService.startDispatch(dispatchId);
  }

  Future<void> arriveDispatch(String dispatchId) {
    return officerDispatchApiService.arriveDispatch(dispatchId);
  }

  Future<void> completeDispatch({
    required String dispatchId,
    String? notes,
  }) {
    return officerDispatchApiService.completeDispatch(
      dispatchId: dispatchId,
      notes: notes,
    );
  }
}
