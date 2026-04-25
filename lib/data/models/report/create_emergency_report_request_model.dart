import 'dart:io';

class CreateEmergencyReportRequestModel {
  final String? serviceId;
  final String emergencyType;
  final String description;
  final String latitude;
  final String longitude;
  final String addressSnapshot;
  final DateTime photoCapturedAt;
  final File photo;

  CreateEmergencyReportRequestModel({
    this.serviceId,
    required this.emergencyType,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.addressSnapshot,
    required this.photoCapturedAt,
    required this.photo,
  });
}
