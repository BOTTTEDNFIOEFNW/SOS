import '../../core/network/dio_client.dart';
import '../models/service_model.dart';

class ServiceApiService {
  final DioClient dioClient;

  ServiceApiService(this.dioClient);

  Future<List<ServiceModel>> getActiveServices() async {
    final response = await dioClient.dio.get('/services/active');

    final List data = response.data['data'] ?? [];

    return data
        .map((item) => ServiceModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
