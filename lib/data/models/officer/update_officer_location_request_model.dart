class UpdateOfficerLocationRequestModel {
  final String reportId;
  final double latitude;
  final double longitude;

  UpdateOfficerLocationRequestModel({
    required this.reportId,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'reportId': reportId,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
