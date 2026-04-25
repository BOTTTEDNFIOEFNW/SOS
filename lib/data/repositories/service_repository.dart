import '../models/service_model.dart';
import '../services/service_api_service.dart';

class ServiceRepository {
  final ServiceApiService serviceApiService;

  ServiceRepository(this.serviceApiService);

  Future<List<ServiceModel>> getActiveServices() {
    return serviceApiService.getActiveServices();
  }
}
