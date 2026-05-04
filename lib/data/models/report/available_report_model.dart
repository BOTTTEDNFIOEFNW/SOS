class AvailableReportModel {
  final String id;
  final String reportCode;
  final String status;
  final String emergencyType;
  final String? serviceId;
  final String? description;
  final String? latitude;
  final String? longitude;
  final String? addressSnapshot;
  final String? photoUrl;
  final DateTime? requestedAt;
  final Map<String, dynamic>? service;
  final Map<String, dynamic>? user;

  AvailableReportModel({
    required this.id,
    required this.reportCode,
    required this.status,
    required this.emergencyType,
    this.serviceId,
    this.description,
    this.latitude,
    this.longitude,
    this.addressSnapshot,
    this.photoUrl,
    this.requestedAt,
    this.service,
    this.user,
  });

  factory AvailableReportModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    return AvailableReportModel(
      id: json['id']?.toString() ?? '',
      reportCode: json['reportCode']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      emergencyType: json['emergencyType']?.toString() ?? '',
      serviceId: json['serviceId']?.toString(),
      description: json['description']?.toString(),
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      addressSnapshot: json['addressSnapshot']?.toString(),
      photoUrl: json['photoUrl']?.toString(),
      requestedAt: parseDate(json['requestedAt']),
      service: json['service'] is Map
          ? Map<String, dynamic>.from(json['service'])
          : null,
      user:
          json['user'] is Map ? Map<String, dynamic>.from(json['user']) : null,
    );
  }

  String get serviceName {
    return service?['serviceName']?.toString() ?? emergencyType;
  }

  String get serviceCode {
    return service?['serviceCode']?.toString() ?? '-';
  }

  String get userName {
    return user?['fullName']?.toString() ?? 'User';
  }

  String get userPhone {
    return user?['phoneNumber']?.toString() ?? '-';
  }
}
