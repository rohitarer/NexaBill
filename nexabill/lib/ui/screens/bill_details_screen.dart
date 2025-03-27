import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexabill/providers/payments_provider.dart';
import 'package:nexabill/ui/widgets/bill_card_view.dart';
import 'package:nexabill/providers/bill_verification_provider.dart';

class BillDetailsScreen extends ConsumerWidget {
  final int billIndex;

  const BillDetailsScreen({super.key, required this.billIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(billVerificationProvider);
    final payments = ref.watch(paymentsProvider);
    final bill = payments[billIndex];

    return Scaffold(
      appBar: AppBar(title: const Text("Bill Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: BillCardView(
          billItems: bill.billItems,
          sealStatus: bill.sealStatus,
        ),
      ),
    );
  }
}
