import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nexabill/data/bill_data.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayService {
  static final _razorpay = Razorpay();

  static void init(BuildContext context) {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (res) {
      _handleSuccess(context, res);
    });

    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (res) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Payment Failed: \${res.message}")),
      );
    });

    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (res) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("💼 Wallet Selected: \${res.walletName}")),
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

  static String _generateOtp() {
    final rand = Random();
    return (100000 + rand.nextInt(900000)).toString();
  }

  static Future<void> _storeOtp({
    required String billNo,
    required String otp,
    required double amount,
    required String uid,
  }) async {
    final otpDoc = {
      'otp': otp,
      'uid': uid, // ✅ Store user ID properly
      'amountPaid': amount,
      'timestamp': FieldValue.serverTimestamp(),
      'expiresAt':
          DateTime.now().add(const Duration(minutes: 10)).toIso8601String(),
    };

    await FirebaseFirestore.instance.collection('otps').doc(billNo).set(otpDoc);
    debugPrint("✅ OTP stored in 'otps': \$otpDoc");
  }

  static Future<void> _handleSuccess(
    BuildContext context,
    PaymentSuccessResponse res,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint("❌ User not authenticated.");
      return;
    }

    final uid = user.uid;
    final billNo = BillData.billNo;
    final amount = BillData.amountPaid;
    final otp = _generateOtp();

    try {
      await _storeOtp(billNo: billNo, otp: otp, amount: amount, uid: uid);

      final billData = {
        'billNo': billNo,
        'products': BillData.billItems,
        'customerName': BillData.customerName,
        'customerMobile': BillData.customerMobile,
        'martName': BillData.martName,
        'martAddress': BillData.martAddress,
        'billDate': BillData.billDate,
        'session': BillData.session,
        'counterNo': BillData.counterNo,
        'martContact': BillData.martContact,
        'martGSTIN': BillData.martGSTIN,
        'martCIN': BillData.martCIN,
        'amountPaid': amount,
        'otp': otp,
        'uid': uid, // ✅ Store UID in bill also if needed
        'timestamp': FieldValue.serverTimestamp(),
        'paymentId': res.paymentId,
        'orderId': res.orderId,
        'signature': res.signature,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('my_bills')
          .doc(billNo)
          .set(billData);

      BillData.otp = otp;
      debugPrint("✅ Bill saved to Firestore: \$billData");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Payment Success: \${res.paymentId}")),
      );
    } catch (e) {
      debugPrint("❌ Firestore Save Error: \$e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Failed to save bill data.")),
      );
    }
  }
}

// import 'dart:math';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:nexabill/data/bill_data.dart'; // ✅ Needed for bill info
// import 'package:razorpay_flutter/razorpay_flutter.dart';

// class RazorpayService {
//   static final _razorpay = Razorpay();

//   static void init(BuildContext context) {
//     _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (res) {
//       _handleSuccess(context, res);
//     });

//     _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (res) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("❌ Payment Failed: ${res.message}")),
//       );
//     });

//     _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (res) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("💼 Wallet Selected: ${res.walletName}")),
//       );
//     });
//   }

//   static void openCheckout({
//     required int amountPaise,
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

//   // 🔐 Generate 6-digit OTP
//   static String _generateOtp() {
//     final rand = Random();
//     return (100000 + rand.nextInt(900000)).toString();
//   }

//   // 📝 Store OTP in Firestore
//   static Future<void> _storeOtp(
//     String billNo,
//     String otp,
//     double amount,
//   ) async {
//     await FirebaseFirestore.instance.collection('otps').doc(billNo).set({
//       'otp': otp,
//       'amountPaid': amount,
//       'timestamp': FieldValue.serverTimestamp(),
//       'expiresAt':
//           DateTime.now().add(const Duration(minutes: 10)).toIso8601String(),
//     });
//   }

//   // ✅ Payment success handler
//   static Future<void> _handleSuccess(
//     BuildContext context,
//     PaymentSuccessResponse res,
//   ) async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;

//     final uid = user.uid;
//     final billNo = BillData.billNo;
//     final amount = BillData.amountPaid;
//     final otp = _generateOtp();

//     try {
//       // Save OTP
//       await _storeOtp(billNo, otp, amount);

//       // Save bill to user's collection
//       final billData = {
//         'billNo': billNo,
//         'products': BillData.billItems,
//         'customerName': BillData.customerName,
//         'customerMobile': BillData.customerMobile,
//         'martName': BillData.martName,
//         'martAddress': BillData.martAddress,
//         'amountPaid': amount,
//         'otp': otp,
//         'timestamp': DateTime.now().toIso8601String(),
//         'paymentId': res.paymentId,
//         'orderId': res.orderId,
//         'signature': res.signature,
//       };

//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(uid)
//           .collection('my_bills')
//           .doc(billNo)
//           .set(billData);

//       // ✅ Optionally update in BillData for UI reflection
//       BillData.otp = otp;

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("✅ Payment Success: ${res.paymentId}")),
//       );
//     } catch (e) {
//       debugPrint("❌ Firestore Save Error: $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("❌ Failed to save bill data.")),
//       );
//     }
//   }
// }
