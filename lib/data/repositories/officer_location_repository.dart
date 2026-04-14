import '../models/officer/update_officer_location_request_model.dart';
import '../services/officer_location_api_service.dart';

class OfficerLocationRepository {
  final OfficerLocationApiService officerLocationApiService;

  OfficerLocationRepository({
    required this.officerLocationApiService,
  });

  Future<void> updateLocation(
    UpdateOfficerLocationRequestModel request,
  ) async {
    await officerLocationApiService.updateLocation(request);
  }
}