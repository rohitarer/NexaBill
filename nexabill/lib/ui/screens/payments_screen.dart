import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nexabill/core/bill_data.dart';
import 'package:nexabill/providers/payments_provider.dart';
import 'package:nexabill/providers/profile_provider.dart';
import 'package:nexabill/ui/screens/bill_details_screen.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      Future.microtask(() {
        ref
            .read(paymentsProvider.notifier)
            .fetchCustomerPayments(currentUser.uid);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final payments = ref.watch(paymentsProvider);
    final profileAsync = ref.watch(profileFutureProvider);

    return profileAsync.when(
      data: (profile) {
        final role = profile['role'] ?? 'customer';

        final sortedPayments = [...payments];
        sortedPayments.sort((a, b) {
          final aNum =
              int.tryParse(a['billNo'].toString().replaceAll("BILL#", "")) ?? 0;
          final bNum =
              int.tryParse(b['billNo'].toString().replaceAll("BILL#", "")) ?? 0;
          return bNum.compareTo(aNum);
        });

        return Scaffold(
          appBar:
              role == 'customer'
                  ? AppBar(title: const Text('Payment History'))
                  : null,
          body:
              sortedPayments.isEmpty
                  ? const Center(child: Text('No payments found.'))
                  : ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: sortedPayments.length,
                    itemBuilder: (context, index) {
                      final bill = sortedPayments[index];
                      final products = List<Map<String, dynamic>>.from(
                        bill['products'],
                      );

                      final totalAmount = products.fold(0.0, (sum, item) {
                        final price =
                            double.tryParse(item['price'].toString()) ?? 0.0;
                        final qty =
                            int.tryParse(item['quantity'].toString()) ?? 1;
                        return sum + price * qty;
                      });

                      final totalGST = products.fold(0.0, (sum, item) {
                        final gst =
                            double.tryParse(item['gst'].toString()) ?? 0.0;
                        final price =
                            double.tryParse(item['price'].toString()) ?? 0.0;
                        final qty =
                            int.tryParse(item['quantity'].toString()) ?? 1;
                        return sum + (gst * price * qty) / 100;
                      });

                      final balance =
                          (totalAmount + totalGST) -
                          (bill['amountPaid'] as num).toDouble();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    bill['customerName'],
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    bill['billDate'],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),

                              // Bill No, Mobile, and Paid aligned horizontally
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Bill No: ${bill['billNo']}",
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      Text(
                                        "Mobile: ${bill['customerMobile']}",
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text(
                                        "Paid",
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      Text(
                                        "₹${(bill['amountPaid'] as num).toDouble().toStringAsFixed(2)}",
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => BillDetailsScreen(
                                              customerUid: bill['customerId'],
                                              billNo: bill['billNo'],
                                            ),
                                      ),
                                    );
                                  },
                                  child: const Text("View More"),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
        );
      },
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text("❌ Error: $e"))),
    );
  }
}
