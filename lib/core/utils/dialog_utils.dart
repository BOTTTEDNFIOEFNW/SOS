import 'package:flutter/material.dart';

Future<void> showLogoutConfirmation(
  BuildContext context,
  Future<void> Function() onConfirm,
) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Keluar dari akun?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Anda yakin ingin logout dari aplikasi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      );
    },
  );

  if (result == true) {
    await onConfirm();
  }
}
