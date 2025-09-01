import 'dart:async';

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
  final bool _waiting = true;
  final int _attempts = 0;
  final int _maxAttempts = 10;
  Timer? _pollTimer;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    // Future.microtask(() => _pollOtp());
    // Future.microtask(() {
    //   if (!mounted) return;
    //   if (widget.billNo.isEmpty) return; // guard
    //   _pollOtp();
    // });

    // No bill? Don't start anything.
    if (widget.billNo.isEmpty) return;
    _startPolling();
  }

  void _startPolling() {
    if (_started) return;
    _started = true;

    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _pollOtp());
  }

  // Future<void> _pollOtp() async {
  //   if (widget.billNo.isEmpty) return; // guard again
  //   final docRef = FirebaseFirestore.instance
  //       .collection('otps')
  //       .doc(widget.billNo);

  //   while (_waiting && _attempts < _maxAttempts) {
  //     _attempts++;
  //     final snapshot =
  //         await FirebaseFirestore.instance
  //             .collection("otps")
  //             .doc(widget.billNo)
  //             .get();

  //     if (snapshot.exists) {
  //       final data = snapshot.data();
  //       final otp = data?["otp"]?.toString();
  //       final amount = double.tryParse("${data?["amountPaid"] ?? "0.0"}");

  //       if (otp != null && otp.length == 6) {
  //         setState(() {
  //           _otp = otp;
  //           _waiting = false;
  //         });
  //         widget.onOtpReceived(otp, amount ?? 0.0);
  //         return;
  //       }
  //     }

  //     await Future.delayed(const Duration(milliseconds: 500));
  //   }

  //   if (mounted) {
  //     setState(() {
  //       _waiting = false;
  //     });
  //   }
  // }

  Future<void> _pollOtp() async {
    // Guard again; bill number might be reset while logged out / switching roles.
    if (!mounted || widget.billNo.isEmpty) return;
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection("otps")
              .doc(widget.billNo)
              .get();

      if (!doc.exists) return;

      final data = doc.data()!;
      final otp = (data['otp'] as String?)?.trim();
      final amountPaid = (data['amountPaid'] ?? 0).toDouble();
      if (otp != null && otp.isNotEmpty) {
        widget.onOtpReceived(otp, amountPaid);
        // stop polling once handled
        _pollTimer?.cancel();
        _pollTimer = null;
      }
    } catch (e) {
      debugPrint("❌ OtpHandler poll error: $e");
    }
  }

  @override
  void didUpdateWidget(covariant OtpHandler oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If billNo changes from empty → non-empty, (re)start polling
    if (!_started && widget.billNo.isNotEmpty) {
      _startPolling();
    }
    // If billNo becomes empty, stop polling
    if (widget.billNo.isEmpty) {
      _pollTimer?.cancel();
      _pollTimer = null;
      _started = false;
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.billNo.isEmpty) return const SizedBox.shrink();
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child:
          _waiting
              ? const Text(
                "Verificaton Code:",
                key: ValueKey("waiting"),
                style: TextStyle(
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
