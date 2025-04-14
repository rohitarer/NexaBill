import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexabill/data/bill_data.dart';
import 'package:nexabill/providers/bill_cashier_provider.dart';

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

  static Future<void> saveSealStatus(String sealStatus) async {
    final customerId = BillData.customerId;
    final billNo = BillData.billNo;

    if (customerId.isEmpty || billNo.isEmpty) {
      print("⚠️ Missing customerId or billNo");
      return;
    }

    try {
      final billRef = FirebaseFirestore.instance
          .collection('users')
          .doc(customerId)
          .collection('my_bills')
          .doc(billNo);

      await billRef.update({
        'sealStatus': sealStatus, // 'sealed' or 'rejected'
      });

      print("✅ Seal status '\$sealStatus' saved successfully.");
    } catch (e) {
      print("❌ Error saving seal status: \$e");
    }
  }
}

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:nexabill/data/bill_data.dart';
// import 'package:nexabill/providers/bill_cashier_provider.dart';

// class CashierInfoHandler {
//   static Future<void> updateCashierAndCounterIfMissing(WidgetRef ref) async {
//     try {
//       if (BillData.customerId.isEmpty) {
//         print("⚠️ customerId is empty, skipping cashier update.");
//         return;
//       }

//       final userDoc =
//           await FirebaseFirestore.instance
//               .collection("users")
//               .doc(BillData.customerId)
//               .collection("my_bills")
//               .doc(BillData.billNo)
//               .get();

//       if (!userDoc.exists) {
//         print("⚠️ Bill document does not exist for cashier update.");
//         return;
//       }

//       final data = userDoc.data();
//       if (data != null) {
//         final cashier = data['cashier'] ?? BillData.cashier;
//         final counter = data['counterNo'] ?? BillData.counterNo;

//         BillData.cashier = cashier;
//         BillData.counterNo = counter;

//         ref.read(billCashierProvider.notifier).update(cashier, counter);

//         print("✅ Cashier Info Updated via Handler:");
//         print("  • Cashier: $cashier");
//         print("  • Counter: $counter");
//       }
//     } catch (e, st) {
//       print("❌ Error fetching cashier info: $e");
//       print("📍 StackTrace: $st");
//     }
//   }
//   static Future<void> saveSealStatus(String sealStatus) async {
//     final customerId = BillData.customerId;
//     final billNo = BillData.billNo;

//     if (customerId.isEmpty || billNo.isEmpty) {
//       print("⚠️ Missing customerId or billNo");
//       return;
//     }

//     try {
//       final billRef = FirebaseFirestore.instance
//           .collection('users')
//           .doc(customerId)
//           .collection('my_bills')
//           .doc(billNo);

//       await billRef.update({
//         'sealStatus': sealStatus, // 'sealed' or 'rejected'
//       });

//       print("✅ Seal status '\$sealStatus' saved successfully.");
//     } catch (e) {
//       print("❌ Error saving seal status: \$e");
//     }
//   }

// }
