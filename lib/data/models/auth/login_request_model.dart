class LoginRequestModel {
  final String? phoneNumber;
  final String? email;
  final String password;

  LoginRequestModel({
    this.phoneNumber,
    this.email,
    required this.password,
  });

  Map<String, dynamic> toUserJson() {
    return {
      'phoneNumber': phoneNumber,
      'password': password,
    };
  }

  Map<String, dynamic> toOfficerJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}
