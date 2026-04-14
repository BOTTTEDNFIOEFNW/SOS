class EmergencyReportModel {
  final String id;
  final String reportCode;
  final String emergencyType;
  final String status;
  final String? description;
  final String? addressSnapshot;
  final String? photoUrl;
  final DateTime? photoCapturedAt;
  final DateTime? requestedAt;
  final DateTime? assignedAt;
  final DateTime? arrivedAt;
  final DateTime? completedAt;
  final String? latitude;
  final String? longitude;

  EmergencyReportModel({
    required this.id,
    required this.reportCode,
    required this.emergencyType,
    required this.status,
    this.description,
    this.addressSnapshot,
    this.photoUrl,
    this.photoCapturedAt,
    this.requestedAt,
    this.assignedAt,
    this.arrivedAt,
    this.completedAt,
    this.latitude,
    this.longitude,
  });

  factory EmergencyReportModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    return EmergencyReportModel(
      id: json['id']?.toString() ?? '',
      reportCode: json['reportCode']?.toString() ?? '',
      emergencyType: json['emergencyType']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      description: json['description']?.toString(),
      addressSnapshot: json['addressSnapshot']?.toString(),
      photoUrl: json['photoUrl']?.toString(),
      photoCapturedAt: parseDate(json['photoCapturedAt']),
      requestedAt: parseDate(json['requestedAt']),
      assignedAt: parseDate(json['assignedAt']),
      arrivedAt: parseDate(json['arrivedAt']),
      completedAt: parseDate(json['completedAt']),
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
    );
  }
}
