import 'package:flutter/material.dart';
import 'verify_otp_page.dart';
import '../../../routes/app_routes.dart'; // 🔥 tambah ini


class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  bool isLoading = false;

  // 🔥 TAMBAH CONTROLLER
  final TextEditingController phoneController = TextEditingController();

  // 🔥 FUNCTION PINDAH KE OTP
  void goToOtp() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const VerifyOtpPage(),
    ),
  );
}

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 30),

            const Text(
              "Lupa Password?",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            // 🔥 INPUT NOMOR (PAKAI CONTROLLER)
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: "Masukkan No Handphone (628xxx)",
                prefixIcon: const Icon(Icons.phone_android),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🔥 BUTTON (PINDAH KE OTP)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: goToOtp, // 🔥 ganti ini
                child: const Text("Kirim OTP"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
