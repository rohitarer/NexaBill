import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexabill/data/bill_data.dart';
import 'package:nexabill/providers/bill_details_provider.dart';
import 'package:nexabill/ui/widgets/bill_card_view.dart';

class BillDetailsScreen extends ConsumerWidget {
  final String customerUid;
  final String billNo;

  const BillDetailsScreen({
    super.key,
    required this.customerUid,
    required this.billNo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billAsync = ref.watch(
      billDetailsProvider(
        BillDetailsParams(customerUid: customerUid, billNo: billNo),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text("Bill Details")),
      body: billAsync.when(
        data: (_) {
          // ✅ Now we just use BillData (already populated)
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: BillCardView(billItems: List.from(BillData.billItems)),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (e, st) => Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  "Failed to load bill details\n\n$e",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            ),
      ),
    );
  }
}
