class ForgotPasswordRequestModel {
  final String phoneNumber;

  ForgotPasswordRequestModel({
    required this.phoneNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'phoneNumber': phoneNumber,
    };
  }
}
