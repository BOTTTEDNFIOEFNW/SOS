class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String nik;
  final String address;
  final String role;
  final String type;
  final String status;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.nik,
    required this.address,
    required this.role,
    required this.type,
    required this.status,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      nik: json['nik']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      type: json['type']?.toString() ?? 'USER',
      status: json['status']?.toString() ?? '',
    );
  }
}
