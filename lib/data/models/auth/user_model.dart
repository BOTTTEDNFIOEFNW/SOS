class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final String type;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.type,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      type: json['type']?.toString() ?? 'USER',
    );
  }
}
