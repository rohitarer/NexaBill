import 'package:nexabill/providers/bill_verification_provider.dart';

class PaymentModel {
  final String customerId; // 🔹 UID of the customer
  final String customerName; // 🔹 Full name of the customer
  final String customerMobile; // 🔹 Mobile number
  final String txnId; // 🔹 TXN ID (formatted from BILL#)
  final String billDate; // 🔹 Date of the bill (dd-MM-yyyy)
  final List<Map<String, dynamic>> billItems; // 🔹 List of scanned items
  final double amountPaid; // 🔹 Amount paid by customer
  final double balanceAmount; // 🔹 Remaining amount if any
  final BillSealStatus sealStatus; // 🔹 Verified, Rejected, None
  final String martName; // 🔹 Name of the mart/store

  // 🔹 Newly added optional fields
  final String? counterNo; // 💼 Counter number
  final String? cashier; // 👨‍💼 Cashier name
  final String? otp; // 🔐 OTP used during verification

  PaymentModel({
    required this.customerId,
    required this.customerName,
    required this.customerMobile,
    required this.txnId,
    required this.billDate,
    required this.billItems,
    required this.amountPaid,
    required this.balanceAmount,
    required this.sealStatus,
    required this.martName,
    this.counterNo,
    this.cashier,
    this.otp,
  });
}
