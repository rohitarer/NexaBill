import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexabill/providers/bill_cashier_provider.dart';

class BillData {
  // 🔹 Mart Information
  static String martName = "";
  static String martAddress = "";
  static String martState = "";
  static String martContact = "";
  static String martGSTIN = "";
  static String martCIN = "";
  static String martNote = "No returns after 7 days with a valid bill.";

  // 🔹 Bill Header Details
  static String billNo = "";
  static String counterNo = "";
  static String billDate = "";
  static String session = "";

  // 🔹 Customer + Cashier Details
  static String customerName = "";
  static String customerMobile = "";
  static String cashier = "";
  static String customerId = "";
  static String adminUid = "";

  // 🔹 Product List
  static List<Map<String, dynamic>> products = [];
  static List<Map<String, dynamic>> get billItems => products;

  // 🔹 Amounts
  static double amountPaid = 0.0;

  // 🔹 OTP + Seal Status
  static String otp = "";
  static String sealStatus = "";

  // 🔹 Reset Flag
  static bool hasResetAfterSeal = false;

  // 🔹 Footer
  static const String footerMessage = "THANK YOU, VISIT AGAIN!";

  // 🔹 Utility Methods
  static double getTotalAmount() {
    return products.fold(0.0, (sum, item) {
      final price = item["finalPrice"] ?? item["price"] ?? 0.0;
      final quantity = item["quantity"] ?? 1;
      return sum + (price as double) * (quantity as int);
    });
  }

  static int getTotalQuantity() {
    return products.fold(0, (sum, item) => sum + (item["quantity"] as int));
  }

  static double getTotalGST() => getTotalAmount() * 0.05;

  static double getNetAmountDue() => getTotalAmount() - getTotalGST();

  static double getBalanceAmount() {
    final balance = getTotalAmount() - amountPaid;
    return balance < 0 ? 0 : balance;
  }

  static void printSummary() {
    debugPrint("📋 BILL SUMMARY:");
    debugPrint("• Bill No     : $billNo");
    debugPrint("• Customer    : $customerName | $customerMobile");
    debugPrint("• Cashier     : $cashier | Counter: $counterNo");
    debugPrint("• Mart        : $martName");
    debugPrint("• Address     : $martAddress, $martState");
    debugPrint("• Contact     : $martContact");
    debugPrint("• GSTIN/CIN   : $martGSTIN / $martCIN");
    debugPrint("• Date/Time   : $billDate at $session");
    debugPrint("• OTP         : $otp");
    debugPrint("• Seal Status : $sealStatus");
    debugPrint("• Products    : ${products.length} items");
    debugPrint("• Amount Paid : ₹$amountPaid");
    debugPrint("• Total Amount: ₹${getTotalAmount().toStringAsFixed(2)}");
    debugPrint("• Balance Due : ₹${getBalanceAmount().toStringAsFixed(2)}");
  }

  static void resetBillData({bool preserveCustomerId = true}) {
    final preservedCustomerId = customerId;
    martName = "";
    martAddress = "";
    martState = "";
    martContact = "";
    martGSTIN = "";
    martCIN = "";
    billNo = "";
    counterNo = "";
    billDate = "";
    session = "";
    customerName = "";
    customerMobile = "";
    cashier = "";
    customerId = preserveCustomerId ? preservedCustomerId : "";
    adminUid = "";
    products = [];
    amountPaid = 0.0;
    otp = "";
    sealStatus = "";
    hasResetAfterSeal = false;
  }

  static Future<void> reloadCashierAndCounterIfOtpVerified(
    WidgetRef ref,
  ) async {
    if (customerId.isEmpty || billNo.isEmpty) {
      debugPrint("⚠️ customerId or billNo missing, skipping cashier update.");
      return;
    }

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(customerId)
              .collection('my_bills')
              .doc(billNo)
              .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          cashier = data['cashier'] ?? "";
          counterNo = data['counterNo'] ?? "";
          sealStatus = data['sealStatus'] ?? "";

          ref.read(billCashierProvider.notifier).update(cashier, counterNo);

          debugPrint("✅ Cashier Info Updated via Handler:");
          debugPrint("  • Cashier: $cashier");
          debugPrint("  • Counter: $counterNo");
          debugPrint("  • Seal: $sealStatus");
        }
      } else {
        debugPrint("⚠️ Bill document does not exist for cashier update.");
      }
    } catch (e, st) {
      debugPrint("❌ Error fetching cashier info: $e");
      debugPrint("📍 StackTrace: $st");
    }
  }
}

// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:nexabill/providers/bill_cashier_provider.dart';

// class BillData {
//   // 🔹 Mart Information
//   static String martName = "";
//   static String martAddress = "";
//   static String martState = "";
//   static String martContact = "";
//   static String martGSTIN = "";
//   static String martCIN = "";
//   static String martNote = "No returns after 7 days with a valid bill.";

//   // 🔹 Bill Header Details
//   static String billNo = "";
//   static String counterNo = "";
//   static String billDate = "";
//   static String session = "";

//   // 🔹 Customer + Cashier Details
//   static String customerName = "";
//   static String customerMobile = "";
//   static String cashier = "";
//   static String customerId = "";
//   static String adminUid = "";

//   // 🔹 Product List
//   static List<Map<String, dynamic>> products = [];
//   static List<Map<String, dynamic>> get billItems => products;

//   // 🔹 Amounts
//   static double amountPaid = 0.0;

//   // 🔹 Role
//   static String userRole = "";

//   static double getTotalAmount() {
//     return products.fold(0.0, (sum, item) {
//       final price = item["finalPrice"] ?? item["price"] ?? 0.0;
//       final quantity = item["quantity"] ?? 1;
//       return sum + (price as double) * (quantity as int);
//     });
//   }

//   static int getTotalQuantity() {
//     return products.fold(0, (sum, item) => sum + (item["quantity"] as int));
//   }

//   static double getTotalGST() => getTotalAmount() * 0.05;

//   static double getNetAmountDue() => getTotalAmount() - getTotalGST();

//   static double getBalanceAmount() {
//     final balance = getTotalAmount() - amountPaid;
//     return balance < 0 ? 0 : balance;
//   }

//   // 🔹 OTP + Seal Status
//   static String otp = "";
//   static String sealStatus = "";

//   // 🔹 Reset Flag
//   static bool hasResetAfterSeal = false;

//   // 🔹 Footer
//   static const String footerMessage = "THANK YOU, VISIT AGAIN!";

//   static void printSummary() {
//     debugPrint("📋 BILL SUMMARY:");
//     debugPrint("• Bill No     : $billNo");
//     debugPrint("• Customer    : $customerName | $customerMobile");
//     debugPrint("• Cashier     : $cashier | Counter: $counterNo");
//     debugPrint("• Mart        : $martName");
//     debugPrint("• Address     : $martAddress, $martState");
//     debugPrint("• Contact     : $martContact");
//     debugPrint("• GSTIN/CIN   : $martGSTIN / $martCIN");
//     debugPrint("• Date/Time   : $billDate at $session");
//     debugPrint("• OTP         : $otp");
//     debugPrint("• Seal Status : $sealStatus");
//     debugPrint("• Products    : ${products.length} items");
//     debugPrint("• Amount Paid : ₹$amountPaid");
//     debugPrint("• Total Amount: ₹${getTotalAmount().toStringAsFixed(2)}");
//     debugPrint("• Balance Due : ₹${getBalanceAmount().toStringAsFixed(2)}");
//   }

//   static void resetBillData({bool preserveCustomerId = true}) {
//     final preservedCustomerId = customerId;
//     martName = "";
//     martAddress = "";
//     martState = "";
//     martContact = "";
//     martGSTIN = "";
//     martCIN = "";
//     billNo = "";
//     counterNo = "";
//     billDate = "";
//     session = "";
//     customerName = "";
//     customerMobile = "";
//     cashier = "";
//     customerId = preserveCustomerId ? preservedCustomerId : "";
//     adminUid = "";
//     products = [];
//     amountPaid = 0.0;
//     otp = "";
//     sealStatus = "";
//     hasResetAfterSeal = false;
//   }

//   static Future<void> reloadCashierAndCounterIfOtpVerified(
//     WidgetRef ref,
//   ) async {
//     if (customerId.isEmpty || billNo.isEmpty) {
//       debugPrint("⚠️ customerId or billNo missing, skipping cashier update.");
//       return;
//     }

//     try {
//       final doc =
//           await FirebaseFirestore.instance
//               .collection('users')
//               .doc(customerId)
//               .collection('my_bills')
//               .doc(billNo)
//               .get();

//       if (doc.exists) {
//         final data = doc.data();
//         if (data != null) {
//           cashier = data['cashier'] ?? "";
//           counterNo = data['counterNo'] ?? "";
//           sealStatus = data['sealStatus'] ?? "";

//           ref.read(billCashierProvider.notifier).update(cashier, counterNo);

//           debugPrint("✅ Cashier Info Updated via Handler:");
//           debugPrint("  • Cashier: $cashier");
//           debugPrint("  • Counter: $counterNo");
//           debugPrint("  • Seal: $sealStatus");
//         }
//       } else {
//         debugPrint("⚠️ Bill document does not exist for cashier update.");
//       }
//     } catch (e, st) {
//       debugPrint("❌ Error fetching cashier info: $e");
//       debugPrint("📍 StackTrace: $st");
//     }
//   }
// }
