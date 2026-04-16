class VerifyOtpRequestModel {
  final String phoneNumber;
  final String otpCode;

  VerifyOtpRequestModel({
    required this.phoneNumber,
    required this.otpCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'phoneNumber': phoneNumber,
      'otpCode': otpCode,
    };
  }
}
