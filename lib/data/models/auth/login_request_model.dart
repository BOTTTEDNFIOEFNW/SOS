class LoginRequestModel {
  final String? phoneNumber;
  final String? email;
  final String? identifier;
  final String password;

  LoginRequestModel({
    this.phoneNumber,
    this.email,
    this.identifier,
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

  Map<String, dynamic> toMobileJson() {
    return {
      'identifier': identifier,
      'password': password,
    };
  }
}
