import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nexabill/data/bill_data.dart';

Future<void> saveBillToFirestore() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception("User not logged in");
  }

  final String customerUid = user.uid;
  final String billNo = BillData.billNo;

  // Generate a random 6-digit OTP
  final String otp = (100000 + Random().nextInt(900000)).toString();

  // 🔹 Save bill in customer's profile
  final billData = {
    "products": BillData.products,
    "amountPaid": BillData.amountPaid,
    "timestamp": FieldValue.serverTimestamp(),
    "otp": otp,
    "billNo": billNo,
    "customerName": BillData.customerName,
    "customerMobile": BillData.customerMobile,
    "martName": BillData.martName,
    "martAddress": BillData.martAddress,
    "billDate": BillData.billDate,
    "session": BillData.session,
    "counterNo": BillData.counterNo,
    "martContact": BillData.martContact,
    "martGSTIN": BillData.martGSTIN,
    "martCIN": BillData.martCIN,
    "uid": customerUid, // 🔐 Also storing UID for traceability
  };

  await FirebaseFirestore.instance
      .collection("users")
      .doc(customerUid)
      .collection("my_bills")
      .doc(billNo)
      .set(billData);

  // 🔹 Save OTP mapping in global "otps" collection
  final otpData = {
    "otp": otp,
    "uid": customerUid, // ✅ Must match what BillVerificationScreen expects
    "amountPaid": BillData.amountPaid,
    "timestamp": FieldValue.serverTimestamp(),
    "expiresAt":
        DateTime.now().add(const Duration(minutes: 10)).toIso8601String(),
  };

  await FirebaseFirestore.instance.collection("otps").doc(billNo).set(otpData);

  print("✅ Bill and OTP saved successfully:");
  print("   - Bill No: \$billNo");
  print("   - OTP: \$otp");
  print("   - UID: \$customerUid");
}
