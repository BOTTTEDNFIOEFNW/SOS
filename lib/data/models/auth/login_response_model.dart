import 'user_model.dart';

class LoginResponseModel {
  final String accessToken;
  final String refreshToken;
  final UserModel user;

  LoginResponseModel({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;

    return LoginResponseModel(
      accessToken: data['accessToken']?.toString() ?? '',
      refreshToken: data['refreshToken']?.toString() ?? '',
      user: UserModel.fromJson(
        data['account'] ??
            data['user'] ??
            data['officer'] ??
            data['admin'] ??
            {},
      ),
    );
  }
}
