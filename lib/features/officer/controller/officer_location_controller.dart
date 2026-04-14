import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/network/app_exception.dart';
import '../../../data/models/officer/update_officer_location_request_model.dart';
import '../../../data/repositories/officer_location_repository.dart';

class OfficerLocationController extends ChangeNotifier {
  final OfficerLocationRepository officerLocationRepository;

  OfficerLocationController({
    required this.officerLocationRepository,
  });

  bool isSharingLocation = false;
  String? errorMessage;
  Timer? _timer;

  Future<bool> _ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      errorMessage = 'Location service is disabled.';
      notifyListeners();
      return false;
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      errorMessage = 'Location permission denied.';
      notifyListeners();
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      errorMessage = 'Location permission permanently denied.';
      notifyListeners();
      return false;
    }

    return true;
  }

  Future<Position?> _getCurrentPosition() async {
    final hasPermission = await _ensurePermission();
    if (!hasPermission) return null;

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (_) {
      errorMessage = 'Failed to get current location.';
      notifyListeners();
      return null;
    }
  }

  Future<bool> sendCurrentLocation({
    required String reportId,
  }) async {
    try {
      errorMessage = null;
      notifyListeners();

      final position = await _getCurrentPosition();
      if (position == null) return false;

      await officerLocationRepository.updateLocation(
        UpdateOfficerLocationRequestModel(
          reportId: reportId,
          latitude: position.latitude,
          longitude: position.longitude,
        ),
      );

      return true;
    } on AppException catch (error) {
      errorMessage = error.message;
      notifyListeners();
      return false;
    } catch (_) {
      errorMessage = 'Failed to update officer location.';
      notifyListeners();
      return false;
    }
  }

  Future<void> startLiveTracking({
    required String reportId,
    Duration interval = const Duration(seconds: 10),
  }) async {
    if (isSharingLocation) return;

    isSharingLocation = true;
    errorMessage = null;
    notifyListeners();

    await sendCurrentLocation(reportId: reportId);

    _timer = Timer.periodic(interval, (_) async {
      await sendCurrentLocation(reportId: reportId);
    });
  }

  Future<void> stopLiveTracking() async {
    _timer?.cancel();
    _timer = null;
    isSharingLocation = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
