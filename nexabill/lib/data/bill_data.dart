import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexabill/providers/bill_cashier_provider.dart';

class BillData {
  // 🔹 Mart Information (loaded from admin's profile)
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

  // 🔹 Product List
  static List<Map<String, dynamic>> products = [];
  static List<Map<String, dynamic>> get billItems => products;

  // 🔹 Amount Calculations
  static double amountPaid = 0.0;

  static double getTotalAmount() => products.fold(0.0, (sum, item) {
    final price = item["finalPrice"] ?? item["price"] ?? 0.0;
    final quantity = item["quantity"] ?? 1;
    return sum + (price as double) * (quantity as int);
  });

  static int getTotalQuantity() =>
      products.fold(0, (sum, item) => sum + (item["quantity"] as int));
  static double getTotalGST() => getTotalAmount() * 0.05;
  static double getNetAmountDue() => getTotalAmount() - getTotalGST();
  static double getBalanceAmount() {
    final balance = amountPaid - getTotalAmount();
    return balance < 0 ? balance.abs() : balance;
  }

  // 🔹 OTP
  static String otp = "";

  // 🔹 Seal Status (newly added)
  static String sealStatus = ""; // values: 'sealed', 'rejected', or ''

  // 🔹 Footer
  static const String footerMessage = "THANK YOU, VISIT AGAIN!";

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
          final cashier = data['cashier'] ?? "";
          final counter = data['counterNo'] ?? "";
          final seal = data['sealStatus'] ?? "";
          BillData.cashier = cashier;
          BillData.counterNo = counter;
          BillData.sealStatus = seal;

          ref.read(billCashierProvider.notifier).update(cashier, counter);

          debugPrint("✅ Cashier Info Updated via Handler:");
          debugPrint("  • Cashier: $cashier");
          debugPrint("  • Counter: $counter");
          debugPrint("  • Seal: $seal");
        }
      }
    } catch (e, st) {
      debugPrint("❌ Error fetching cashier info: $e");
      debugPrint("📍 StackTrace: $st");
    }
  }
}
