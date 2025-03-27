import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexabill/data/bill_data.dart';
import 'package:nexabill/providers/bill_verification_provider.dart';
import 'package:nexabill/models/payment_model.dart';

final paymentsProvider =
    StateNotifierProvider<PaymentsNotifier, List<PaymentModel>>(
      (ref) => PaymentsNotifier(ref),
    );

class PaymentsNotifier extends StateNotifier<List<PaymentModel>> {
  final Ref ref;

  PaymentsNotifier(this.ref) : super(_initialPayments);

  void addPaymentFromBillData() {
    final sealStatus = ref.read(billVerificationProvider).sealStatus;

    final newPayment = PaymentModel(
      customerName: BillData.customerName,
      customerMobile: BillData.customerMobile,
      txnId: BillData.billNo.replaceAll("BILL#", "TXN"),
      billDate: BillData.billDate,
      billItems: BillData.products,
      amountPaid: BillData.amountPaid,
      balanceAmount: BillData.getBalanceAmount(),
      sealStatus: sealStatus,
      martName: BillData.martName,
    );
    state = [...state, newPayment];
  }

  void clearPayments() {
    state = [];
  }
}

final List<PaymentModel> _initialPayments = [
  PaymentModel(
    customerName: BillData.customerName,
    customerMobile: BillData.customerMobile,
    txnId: BillData.billNo.replaceAll("BILL#", "TXN"),
    billDate: BillData.billDate,
    billItems: BillData.products,
    amountPaid: BillData.amountPaid,
    balanceAmount: BillData.getBalanceAmount(),
    sealStatus: BillSealStatus.sealed,
    martName: BillData.martName,
  ),
];
