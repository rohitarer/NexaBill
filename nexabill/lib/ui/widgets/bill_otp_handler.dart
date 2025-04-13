import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OtpHandler extends StatefulWidget {
  final String billNo;
  final void Function(String otp, double amount) onOtpReceived;

  const OtpHandler({
    super.key,
    required this.billNo,
    required this.onOtpReceived,
  });

  @override
  State<OtpHandler> createState() => _OtpHandlerState();
}

class _OtpHandlerState extends State<OtpHandler> {
  String? _otp;
  bool _waiting = true;
  int _attempts = 0;
  final int _maxAttempts = 10;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _pollOtp());
  }

  Future<void> _pollOtp() async {
    while (_waiting && _attempts < _maxAttempts) {
      _attempts++;
      final snapshot =
          await FirebaseFirestore.instance
              .collection("otps")
              .doc(widget.billNo)
              .get();

      if (snapshot.exists) {
        final data = snapshot.data();
        final otp = data?["otp"]?.toString();
        final amount = double.tryParse("${data?["amountPaid"] ?? "0.0"}");

        if (otp != null && otp.length == 6) {
          setState(() {
            _otp = otp;
            _waiting = false;
          });
          widget.onOtpReceived(otp, amount ?? 0.0);
          return;
        }
      }

      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (mounted) {
      setState(() {
        _waiting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child:
          _waiting
              ? const Text(
                "Verificaton Code:",
                key: ValueKey("waiting"),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              )
              : Text(
                "Verification Code: $_otp",
                key: ValueKey("otp"),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
    );
  }
}
