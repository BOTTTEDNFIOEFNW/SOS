class OfficerLocationModel {
  final String? reportId;
  final String? dispatchId;
  final String? officerId;
  final double latitude;
  final double longitude;
  final DateTime? recordedAt;

  OfficerLocationModel({
    this.reportId,
    this.dispatchId,
    this.officerId,
    required this.latitude,
    required this.longitude,
    this.recordedAt,
  });

  factory OfficerLocationModel.fromJson(Map<String, dynamic> json) {
    return OfficerLocationModel(
      reportId: json['reportId']?.toString(),
      dispatchId: json['dispatchId']?.toString(),
      officerId: json['officerId']?.toString(),
      latitude: double.tryParse(json['latitude']?.toString() ?? '') ?? 0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '') ?? 0,
      recordedAt: json['recordedAt'] != null
          ? DateTime.tryParse(json['recordedAt'].toString())
          : null,
    );
  }
}