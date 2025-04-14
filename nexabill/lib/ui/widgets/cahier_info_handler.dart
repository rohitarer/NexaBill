import 'package:flutter/material.dart';
import 'package:nexabill/core/theme.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexabill/providers/bill_cashier_provider.dart';
import 'package:nexabill/providers/bill_verification_provider.dart';
import 'package:nexabill/ui/widgets/cahier_info_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nexabill/data/bill_data.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CashierInfoHandler {
  static Future<void> updateCashierAndCounterIfMissing(WidgetRef ref) async {
    try {
      if (BillData.customerId.isEmpty) {
        print("⚠️ customerId is empty, skipping cashier update.");
        return;
      }

      final userDoc =
          await FirebaseFirestore.instance
              .collection("users")
              .doc(BillData.customerId)
              .collection("my_bills")
              .doc(BillData.billNo)
              .get();

      if (!userDoc.exists) {
        print("⚠️ Bill document does not exist for cashier update.");
        return;
      }

      final data = userDoc.data();
      if (data != null) {
        final cashier = data['cashier'] ?? BillData.cashier;
        final counter = data['counterNo'] ?? BillData.counterNo;

        BillData.cashier = cashier;
        BillData.counterNo = counter;

        ref.read(billCashierProvider.notifier).update(cashier, counter);

        print("✅ Cashier Info Updated via Handler:");
        print("  • Cashier: $cashier");
        print("  • Counter: $counter");
      }
    } catch (e, st) {
      print("❌ Error fetching cashier info: $e");
      print("📍 StackTrace: $st");
    }
  }

  static Future<void> saveSealStatus(BillSealStatus sealStatus) async {
    final customerName = BillData.customerName;
    final billNo = BillData.billNo;

    if (customerName.isEmpty || billNo.isEmpty) {
      print("⚠️ Missing customerName or billNo");
      return;
    }

    try {
      final cashierUid = FirebaseAuth.instance.currentUser?.uid;
      if (cashierUid == null) {
        print("❌ No cashier UID available.");
        return;
      }

      // 🔍 Fetch customer ID from Firestore based on customerName (first match)
      final userQuery =
          await FirebaseFirestore.instance
              .collection('users')
              .where('fullName', isEqualTo: customerName)
              .limit(1)
              .get();

      if (userQuery.docs.isEmpty) {
        print("❌ Customer not found by name: $customerName");
        return;
      }

      final customerId = userQuery.docs.first.id;
      BillData.customerId = customerId;

      final updateFields = {
        'sealStatus': sealStatus.value,
        'cashier': BillData.cashier,
        'counterNo': BillData.counterNo,
        'cashierCounter': BillData.counterNo,
      };

      final customerBillRef = FirebaseFirestore.instance
          .collection('users')
          .doc(customerId)
          .collection('my_bills')
          .doc(billNo);

      final cashierBillRef = FirebaseFirestore.instance
          .collection('users')
          .doc(cashierUid)
          .collection('my_bills')
          .doc(billNo);

      // ✅ Ensure customer bill is updated or created with merge
      await customerBillRef.set(updateFields, SetOptions(merge: true));

      // ✅ Ensure cashier bill is updated
      await cashierBillRef.set(updateFields, SetOptions(merge: true));

      BillData.sealStatus = sealStatus.value;
      print("✅ Seal status '${sealStatus.value}' saved in both accounts.");
    } catch (e, st) {
      print("❌ Error saving seal status: $e");
      print("📍 StackTrace: $st");
    }
  }
}
