import '../service_model.dart';

class EmergencyReportModel {
  final String id;
  final String reportCode;
  final String? serviceId;
  final ServiceModel? service;
  final String emergencyType;
  final String status;
  final String? description;
  final String? addressSnapshot;
  final String? photoUrl;
  final DateTime? photoCapturedAt;
  final DateTime? requestedAt;
  final DateTime? assignedAt;
  final DateTime? acceptedAt;
  final DateTime? arrivedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final DateTime? failedAt;
  final String? latitude;
  final String? longitude;

  EmergencyReportModel({
    required this.id,
    required this.reportCode,
    this.serviceId,
    this.service,
    required this.emergencyType,
    required this.status,
    this.description,
    this.addressSnapshot,
    this.photoUrl,
    this.photoCapturedAt,
    this.requestedAt,
    this.assignedAt,
    this.acceptedAt,
    this.arrivedAt,
    this.completedAt,
    this.cancelledAt,
    this.failedAt,
    this.latitude,
    this.longitude,
  });

  factory EmergencyReportModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    ServiceModel? parseService(dynamic value) {
      if (value == null) return null;
      if (value is! Map) return null;

      return ServiceModel.fromJson(
        Map<String, dynamic>.from(value),
      );
    }

    return EmergencyReportModel(
      id: json['id']?.toString() ?? '',
      reportCode: json['reportCode']?.toString() ?? '',
      serviceId: json['serviceId']?.toString(),
      service: parseService(json['service']),
      emergencyType: json['emergencyType']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      description: json['description']?.toString(),
      addressSnapshot: json['addressSnapshot']?.toString(),
      photoUrl: json['photoUrl']?.toString(),
      photoCapturedAt: parseDate(json['photoCapturedAt']),
      requestedAt: parseDate(json['requestedAt']),
      assignedAt: parseDate(json['assignedAt']),
      acceptedAt: parseDate(json['acceptedAt']),
      arrivedAt: parseDate(json['arrivedAt']),
      completedAt: parseDate(json['completedAt']),
      cancelledAt: parseDate(json['cancelledAt']),
      failedAt: parseDate(json['failedAt']),
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
    );
  }
}
