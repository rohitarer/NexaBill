import 'package:flutter/material.dart';

class OtpDisplayPage extends StatelessWidget {
  final String otp;

  const OtpDisplayPage({super.key, required this.otp});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Your OTP")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "🔐 Your 6-digit OTP is",
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            Text(
              otp,
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                letterSpacing: 10,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.check),
              label: const Text("Continue"),
            ),
          ],
        ),
      ),
    );
  }
}
