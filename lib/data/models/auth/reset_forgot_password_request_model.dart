class ResetForgotPasswordRequestModel {
  final String phoneNumber;
  final String otp;
  final String newPassword;
  final String confirmPassword;

  ResetForgotPasswordRequestModel({
    required this.phoneNumber,
    required this.otp,
    required this.newPassword,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'phoneNumber': phoneNumber,
      'otp': otp,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword, // 🔥 WAJIB
    };
  }
}
