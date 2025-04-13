// This file saves the bill after successful payment into the customer's Firestore
// collection and also into the shared "otps" collection for OTP-based lookup

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nexabill/data/bill_data.dart';
import 'dart:math';

Future<void> saveBillToFirestore() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception("User not logged in");
  }

  final String customerUid = user.uid;
  final String billNo = BillData.billNo;

  // Generate a random 6-digit OTP
  final String otp = (100000 + Random().nextInt(900000)).toString();

  // Save bill in customer's profile
  await FirebaseFirestore.instance
      .collection("users")
      .doc(customerUid)
      .collection("my_bills")
      .doc(billNo)
      .set({
        "products": BillData.products,
        "amountPaid": BillData.amountPaid,
        "timestamp": FieldValue.serverTimestamp(),
        "otp": otp,
        "billNo": billNo,
      });

  // Save OTP mapping in global collection
  await FirebaseFirestore.instance.collection("otps").doc(billNo).set({
    "otp": otp,
    "amountPaid": BillData.amountPaid,
    "customerId": customerUid,
    "timestamp": FieldValue.serverTimestamp(),
  });

  print("✅ Bill and OTP saved successfully: $billNo -> $otp");
}
