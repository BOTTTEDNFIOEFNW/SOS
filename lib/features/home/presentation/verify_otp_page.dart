import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../routes/app_routes.dart';
import '../../auth/controller/auth_controller.dart';

class VerifyOtpPage extends StatefulWidget {
  const VerifyOtpPage({super.key});

  @override
  State<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends State<VerifyOtpPage> {
  final List<TextEditingController> otpControllers =
      List.generate(6, (_) => TextEditingController());

  Timer? _resendTimer;
  int _remainingSeconds = 60;

  @override
  void initState() {
    super.initState();
    _startResendCountdown();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();

    for (var c in otpControllers) {
      c.dispose();
    }
    super.dispose();
  }

  String get otpCode => otpControllers.map((e) => e.text).join();

  bool get canResend => _remainingSeconds <= 0;

  void _startResendCountdown() {
    _resendTimer?.cancel();

    setState(() {
      _remainingSeconds = 60;
    });

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
        });
        return;
      }

      setState(() {
        _remainingSeconds -= 1;
      });
    });
  }

  String _formatCountdown(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    final mm = minutes.toString().padLeft(2, '0');
    final ss = remainingSeconds.toString().padLeft(2, '0');

    return '$mm:$ss';
  }

  Future<void> verifyOtp(String phoneNumber) async {
    if (otpCode.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP harus 6 digit')),
      );
      return;
    }

    final authController = context.read<AuthController>();

    final success = await authController.verifyForgotPasswordOtp(
      phoneNumber: phoneNumber,
      otp: otpCode,
    );

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authController.errorMessage ?? 'OTP tidak valid',
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('OTP berhasil diverifikasi')),
    );

    Navigator.pushNamed(
      context,
      AppRoutes.resetPassword,
      arguments: {
        'phoneNumber': phoneNumber,
        'otp': otpCode,
      },
    );
  }

  Future<void> resendOtp(String phoneNumber) async {
    if (!canResend) return;

    final authController = context.read<AuthController>();

    final success = await authController.requestForgotPasswordOtp(
      phoneNumber: phoneNumber,
    );

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authController.errorMessage ?? 'Gagal kirim ulang OTP',
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('OTP berhasil dikirim ulang')),
    );

    _startResendCountdown();
  }

  @override
  Widget build(BuildContext context) {
    final phone = ModalRoute.of(context)!.settings.arguments as String?;
    final authController = context.watch<AuthController>();

    debugPrint('RECEIVED PHONE IN VERIFY OTP: $phone');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Verifikasi OTP"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Text(
              "Masukkan Kode OTP",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Kode dikirim ke ${phone ?? '-'}",
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 45,
                  child: TextField(
                    controller: otpControllers[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    decoration: InputDecoration(
                      counterText: "",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 5) {
                        FocusScope.of(context).nextFocus();
                      }

                      if (value.isEmpty && index > 0) {
                        FocusScope.of(context).previousFocus();
                      }
                    },
                  ),
                );
              }),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed:
                    authController.isForgotPasswordLoading || phone == null
                        ? null
                        : () => verifyOtp(phone),
                child: authController.isForgotPasswordLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Verifikasi"),
              ),
            ),
            const SizedBox(height: 20),
            if (!canResend)
              Text(
                'Kirim ulang dalam ${_formatCountdown(_remainingSeconds)}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              )
            else
              TextButton(
                onPressed:
                    authController.isForgotPasswordLoading || phone == null
                        ? null
                        : () => resendOtp(phone),
                child: const Text("Kirim ulang OTP"),
              ),
          ],
        ),
      ),
    );
  }
}
