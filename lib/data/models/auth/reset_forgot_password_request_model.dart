class ResetForgotPasswordRequestModel {
  final String phoneNumber;
  final String otpCode;
  final String newPassword;

  ResetForgotPasswordRequestModel({
    required this.phoneNumber,
    required this.otpCode,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'phoneNumber': phoneNumber,
      'otpCode': otpCode,
      'newPassword': newPassword,
    };
  }
}
