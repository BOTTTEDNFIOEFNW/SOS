import 'package:flutter/material.dart';

import '../../../data/models/service_model.dart';
import '../../../data/repositories/service_repository.dart';

class ServiceController extends ChangeNotifier {
  final ServiceRepository _serviceRepository;

  ServiceController(this._serviceRepository);

  bool isLoading = false;
  String? errorMessage;
  List<ServiceModel> services = [];

  Future<void> fetchActiveServices() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      services = await _serviceRepository.getActiveServices();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
