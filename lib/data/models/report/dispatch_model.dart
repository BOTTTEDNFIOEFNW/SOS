class DispatchModel {
  final String id;
  final String dispatchStatus;
  final DateTime? assignedAt;
  final DateTime? acceptedAt;
  final DateTime? startedAt;
  final DateTime? arrivedAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? officer;
  final Map<String, dynamic>? ambulance;

  DispatchModel({
    required this.id,
    required this.dispatchStatus,
    this.assignedAt,
    this.acceptedAt,
    this.startedAt,
    this.arrivedAt,
    this.completedAt,
    this.officer,
    this.ambulance,
  });

  factory DispatchModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    return DispatchModel(
      id: json['id']?.toString() ?? '',
      dispatchStatus: json['dispatchStatus']?.toString() ?? '',
      assignedAt: parseDate(json['assignedAt']),
      acceptedAt: parseDate(json['acceptedAt']),
      startedAt: parseDate(json['startedAt']),
      arrivedAt: parseDate(json['arrivedAt']),
      completedAt: parseDate(json['completedAt']),
      officer: json['officer'] is Map
          ? Map<String, dynamic>.from(json['officer'])
          : null,
      ambulance: json['ambulance'] is Map
          ? Map<String, dynamic>.from(json['ambulance'])
          : null,
    );
  }
}
