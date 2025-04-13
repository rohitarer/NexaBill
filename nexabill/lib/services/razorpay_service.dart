import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nexabill/core/otp_display_page.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayService {
  static final _razorpay = Razorpay();

  static void init(BuildContext context) {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (res) {
      _handleSuccess(context, res);
    });

    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (res) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Payment Failed: ${res.message}")),
      );
    });

    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (res) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("💼 Wallet Selected: ${res.walletName}")),
      );
    });
  }

  static void openCheckout({
    required int amountPaise,
    required String name,
    required String contact,
    required String email,
  }) {
    var options = {
      'key': 'rzp_test_CYtWPQqiG0GETR',
      'amount': amountPaise,
      'name': name,
      'description': 'Bill Payment',
      'prefill': {'contact': contact, 'email': email},
      'external': {
        'wallets': ['paytm'],
      },
    };

    _razorpay.open(options);
  }

  static void dispose() {
    _razorpay.clear();
  }

  // 🔐 Generate 6-digit OTP
  static String _generateOtp() {
    final rand = Random();
    return (100000 + rand.nextInt(900000)).toString();
  }

  // 📝 Store OTP in Firestore
  static Future<void> _storeOtp(String uid, String otp) async {
    await FirebaseFirestore.instance.collection('otps').doc(uid).set({
      'otp': otp,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // ✅ Payment success handler
  static Future<void> _handleSuccess(
    BuildContext context,
    PaymentSuccessResponse res,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final otp = _generateOtp();
    await _storeOtp(user.uid, otp);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("✅ Payment Success: ${res.paymentId}")),
    );

    // Navigate to OTP display screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OtpDisplayPage(otp: otp)),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:razorpay_flutter/razorpay_flutter.dart';

// class RazorpayService {
//   static final _razorpay = Razorpay();

//   static void init({
//     required void Function(PaymentSuccessResponse) onSuccess,
//     required void Function(PaymentFailureResponse) onFailure,
//     required void Function(ExternalWalletResponse) onExternalWallet,
//   }) {
//     _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, onSuccess);
//     _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, onFailure);
//     _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, onExternalWallet);
//   }

//   static void openCheckout({
//     required int amountPaise, // ₹100 = 10000
//     required String name,
//     required String contact,
//     required String email,
//   }) {
//     var options = {
//       'key': 'rzp_test_CYtWPQqiG0GETR',
//       'amount': amountPaise,
//       'name': name,
//       'description': 'Bill Payment',
//       'prefill': {'contact': contact, 'email': email},
//       'external': {
//         'wallets': ['paytm'],
//       },
//     };

//     _razorpay.open(options);
//   }

//   static void dispose() {
//     _razorpay.clear();
//   }
// }
