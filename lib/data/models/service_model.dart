class ServiceModel {
  final String id;
  final String serviceCode;
  final String serviceName;
  final String? description;
  final String? iconName;
  final String? iconUrl;
  final String? colorHex;
  final bool requiresDispatch;
  final String autoAcceptMode;
  final int acceptTimeoutSeconds;
  final bool isActive;

  ServiceModel({
    required this.id,
    required this.serviceCode,
    required this.serviceName,
    this.description,
    this.iconName,
    this.iconUrl,
    this.colorHex,
    required this.requiresDispatch,
    required this.autoAcceptMode,
    required this.acceptTimeoutSeconds,
    required this.isActive,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] ?? '',
      serviceCode: json['serviceCode'] ?? '',
      serviceName: json['serviceName'] ?? '',
      description: json['description'],
      iconName: json['iconName'],
      iconUrl: json['iconUrl'],
      colorHex: json['colorHex'],
      requiresDispatch: json['requiresDispatch'] ?? true,
      autoAcceptMode: json['autoAcceptMode'] ?? 'CONFIRM',
      acceptTimeoutSeconds: json['acceptTimeoutSeconds'] ?? 15,
      isActive: json['isActive'] ?? true,
    );
  }
}
