import 'package:nexabill/providers/bill_verification_provider.dart';

class PaymentModel {
  final String customerName;
  final String customerMobile;
  final String txnId;
  final String billDate;
  final List<Map<String, dynamic>> billItems;
  final double amountPaid;
  final double balanceAmount;
  final BillSealStatus sealStatus;
  final String martName;

  PaymentModel({
    required this.customerName,
    required this.customerMobile,
    required this.txnId,
    required this.billDate,
    required this.billItems,
    required this.amountPaid,
    required this.balanceAmount,
    required this.sealStatus,
    required this.martName,
  });
}
