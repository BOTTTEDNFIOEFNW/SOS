class RegisterRequestModel {
  final String fullName;
  final String nik;
  final String phoneNumber;
  final String address;
  final String password;

  RegisterRequestModel({
    required this.fullName,
    required this.nik,
    required this.phoneNumber,
    required this.address,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'nik': nik,
      'phoneNumber': phoneNumber,
      'address': address,
      'password': password,
    };
  }
}
