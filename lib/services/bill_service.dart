import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nexabill/data/bill_data.dart';

Future<void> saveBillToFirestore({required String adminUid}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw Exception("User not logged in");

  final String customerUid = user.uid;
  final String billNo = BillData.billNo;

  final String otp = (100000 + Random().nextInt(900000)).toString();

  final billData = {
    "products":
        BillData.products
            .map(
              (product) => {
                "name": product["name"],
                "price": product["price"],
                "quantity": product["quantity"],
                "gst": product["gst"],
                "discount": product["discount"],
                "productId": product["productId"],
                "variant": product["variant"],
                "finalPrice": product["finalPrice"],
              },
            )
            .toList(),
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
    "cashier": BillData.cashier,
    "martContact": BillData.martContact,
    "martGSTIN": BillData.martGSTIN,
    "martCIN": BillData.martCIN,
    "uid": customerUid,
  };

  // ✅ Save to customer's my_bills
  await FirebaseFirestore.instance
      .collection("users")
      .doc(customerUid)
      .collection("my_bills")
      .doc(billNo)
      .set(billData);

  // ✅ Also save to admin’s my_bills
  await FirebaseFirestore.instance
      .collection("users")
      .doc(adminUid)
      .collection("my_bills")
      .doc(billNo)
      .set(billData);

  // ✅ Save OTP
  final otpData = {
    "otp": otp,
    "uid": customerUid,
    "amountPaid": BillData.amountPaid,
    "timestamp": FieldValue.serverTimestamp(),
    "expiresAt":
        DateTime.now().add(const Duration(minutes: 10)).toIso8601String(),
  };

  await FirebaseFirestore.instance.collection("otps").doc(billNo).set(otpData);

  print("✅ Bill and OTP saved successfully:");
  print("   - Bill No: $billNo");
  print("   - OTP: $otp");
  print("   - Customer UID: $customerUid");
  print("   - Admin UID: $adminUid");
}
