import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexabill/data/bill_data.dart';
import 'package:nexabill/providers/bill_verification_provider.dart';
import 'package:intl/intl.dart';
import 'package:nexabill/ui/widgets/verification_stamp.dart';

class BillCardForPrint extends ConsumerWidget {
  final List<Map<String, dynamic>> billItems;
  final GlobalKey repaintKey;

  const BillCardForPrint({
    super.key,
    required this.billItems,
    required this.repaintKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sealStatus = ref.watch(billVerificationProvider).sealStatus;

    return RepaintBoundary(
      key: repaintKey,
      child: Container(
        width: double.infinity,
        color: Colors.white,
        padding: const EdgeInsets.all(20),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const Divider(thickness: 1.5),
                _buildCustomerDetails(),
                const Divider(thickness: 1.5),
                _buildProductList(),
                const Divider(thickness: 1.5),
                _buildBillSummary(),
                const Divider(thickness: 1.5),
                _buildPaymentDetails(),
                const Divider(thickness: 1.5),
                _buildFooterQuote(),
                const SizedBox(height: 40),
              ],
            ),
            if (sealStatus == BillSealStatus.sealed ||
                sealStatus == BillSealStatus.rejected)
              VerificationStamp(
                type:
                    sealStatus == BillSealStatus.sealed
                        ? StampType.verified
                        : StampType.rejected,
                martName: BillData.martName,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "🛒 ${BillData.martName.toUpperCase()} 🛒",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(
          BillData.martAddress,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 3),
        Text(
          "📞 ${BillData.martContact}  |  🏢 GSTIN: ${BillData.martGSTIN}",
          textAlign: TextAlign.center,
        ),
        Text("🔹 CIN: ${BillData.martCIN}", textAlign: TextAlign.center),
        const SizedBox(height: 5),
        Text(
          "**** CUSTOMER COPY ****",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          "TXN ID: #${BillData.billNo.replaceAll("BILL#", "")}",
          style: const TextStyle(color: Colors.blueAccent),
        ),
        Text(
          "📆 ${BillData.billDate} | 🕒 ${BillData.session} | 💼 Counter No: ${BillData.counterNo}",
        ),
      ],
    );
  }

  Widget _buildCustomerDetails() {
    int hour;
    try {
      final time = DateFormat('hh:mm a').parse(BillData.session);
      hour = time.hour;
    } catch (_) {
      hour = DateTime.now().hour;
    }

    String sessionLabel =
        (hour >= 5 && hour < 12)
            ? "🌅 Morning"
            : (hour >= 12 && hour < 17)
            ? "☀️ Afternoon"
            : (hour >= 17 && hour < 21)
            ? "🌇 Evening"
            : "🌙 Night";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "🧾 ${BillData.billNo} | 💼 Counter No: ${BillData.counterNo}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          "${BillData.billDate} | 🕒 ${BillData.session} | Session: $sessionLabel",
        ),
        const SizedBox(height: 4),
        Text(
          "Customer: ${BillData.customerName}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text("Mobile: ${BillData.customerMobile}"),
        Text(
          "Cashier: ${BillData.cashier}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildProductList() {
    return Column(
      children:
          billItems.map((item) {
            final serial = item["serial"] ?? 0;
            final name = item["name"] ?? "";
            final qty = item["quantity"] ?? 1;
            final price = item["price"] ?? 0.0;
            final gst = item["gst"] ?? "0%";
            final discount = item["discount"] ?? "0%";
            final finalPrice = item["finalPrice"] ?? price;
            final total = (finalPrice as double) * (qty as int);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "$serial. $name",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Qty: $qty | Price: ₹$price | GST: $gst | Discount: $discount",
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "₹${total.toStringAsFixed(2)}",
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildBillSummary() {
    double totalAmount = 0.0;
    int totalQty = 0;

    for (var item in billItems) {
      final price = item["finalPrice"] ?? item["price"] ?? 0.0;
      final quantity = item["quantity"] ?? 1;
      totalAmount += (price as double) * (quantity as int);
      totalQty += quantity as int;
    }

    final balance = totalAmount - BillData.amountPaid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _summaryRow("Total Items:", "$totalQty"),
        _summaryRow(
          "Total Amount:",
          "₹${totalAmount.toStringAsFixed(2)}",
          bold: true,
        ),
        _summaryRow(
          "Net Amount Due:",
          "₹${balance.toStringAsFixed(2)}",
          bold: true,
        ),
      ],
    );
  }

  Widget _buildPaymentDetails() {
    double total = billItems.fold(0.0, (sum, item) {
      final p = item["finalPrice"] ?? item["price"] ?? 0.0;
      final q = item["quantity"] ?? 1;
      return sum + (p as double) * (q as int);
    });

    final balance = total - BillData.amountPaid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _summaryRow(
          "Amount Paid:",
          "₹${BillData.amountPaid.toStringAsFixed(2)}",
          bold: true,
        ),
        _summaryRow(
          "Balance Amount:",
          "₹${balance.toStringAsFixed(2)}",
          bold: true,
        ),
        if (BillData.otp.isNotEmpty)
          _summaryRow("Verification Code:", BillData.otp, bold: true),
      ],
    );
  }

  Widget _buildFooterQuote() {
    return Center(
      child: Text(
        "💡 \"Shop smart, save more!\" 💡",
        style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:nexabill/data/bill_data.dart';
// import 'package:nexabill/providers/bill_verification_provider.dart';
// import 'package:intl/intl.dart';
// import 'package:nexabill/ui/widgets/verification_stamp.dart';

// class BillCardForPrint extends ConsumerWidget {
//   final List<Map<String, dynamic>> billItems;

//   const BillCardForPrint({super.key, required this.billItems});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final isDarkMode = Theme.of(context).brightness == Brightness.dark;
//     final sealStatus = ref.watch(billVerificationProvider).sealStatus;

//     return Container(
//       width: double.infinity,
//       color: Colors.white,
//       padding: const EdgeInsets.all(20),
//       child: Stack(
//         alignment: Alignment.center,
//         children: [
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildHeader(),
//               const Divider(thickness: 1.5),
//               _buildCustomerDetails(),
//               const Divider(thickness: 1.5),
//               _buildProductList(),
//               const Divider(thickness: 1.5),
//               _buildBillSummary(),
//               const Divider(thickness: 1.5),
//               _buildPaymentDetails(),
//               const Divider(thickness: 1.5),
//               _buildFooterQuote(),
//               const SizedBox(height: 40),
//             ],
//           ),
//           if (sealStatus == BillSealStatus.sealed ||
//               sealStatus == BillSealStatus.rejected)
//             VerificationStamp(
//               type:
//                   sealStatus == BillSealStatus.sealed
//                       ? StampType.verified
//                       : StampType.rejected,
//               martName: BillData.martName,
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildHeader() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//         Text(
//           "🛒 ${BillData.martName.toUpperCase()} 🛒",
//           textAlign: TextAlign.center,
//           style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//         ),
//         Text(BillData.martAddress, textAlign: TextAlign.center),
//         Text("📞 ${BillData.martContact}  |  🏢 GSTIN: ${BillData.martGSTIN}"),
//         Text("🔹 CIN: ${BillData.martCIN}"),
//         const Divider(thickness: 1.0),
//         const Text(
//           "**** CUSTOMER COPY ****",
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         Text("TXN ID: #${BillData.billNo.replaceAll("BILL#", "")}"),
//         Text(
//           "📆 ${BillData.billDate} | 🕒 ${BillData.session} | 💼 Counter No: ${BillData.counterNo}",
//         ),
//       ],
//     );
//   }

//   Widget _buildCustomerDetails() {
//     int hour;
//     try {
//       hour =
//           BillData.session.isNotEmpty
//               ? DateFormat('hh:mm a').parse(BillData.session).hour
//               : DateTime.now().hour;
//     } catch (_) {
//       hour = DateTime.now().hour;
//     }

//     String sessionLabel =
//         (hour >= 5 && hour < 12)
//             ? "🌅 Morning"
//             : (hour >= 12 && hour < 17)
//             ? "☀️ Afternoon"
//             : (hour >= 17 && hour < 21)
//             ? "🌇 Evening"
//             : "🌙 Night";

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text("🧾 ${BillData.billNo} | 💼 Counter No: ${BillData.counterNo}"),
//         Text(
//           "${BillData.billDate} | 🕒 ${BillData.session} | Session: $sessionLabel",
//         ),
//         Text("Customer: ${BillData.customerName}"),
//         Text("Mobile: ${BillData.customerMobile}"),
//         Text("Cashier: ${BillData.cashier}"),
//       ],
//     );
//   }

//   Widget _buildProductList() {
//     return Column(
//       children:
//           billItems.map((item) {
//             final serial = item["serial"] ?? 0;
//             final name = item["name"] ?? "";
//             final qty = item["quantity"] ?? 1;
//             final price = item["price"] ?? 0.0;
//             final gst = item["gst"] ?? "0%";
//             final discount = item["discount"] ?? "0%";
//             final finalPrice = item["finalPrice"] ?? price;
//             final total = (finalPrice as double) * (qty as int);

//             return Padding(
//               padding: const EdgeInsets.symmetric(vertical: 4.0),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Expanded(
//                     flex: 3,
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           "$serial. $name",
//                           style: const TextStyle(fontWeight: FontWeight.bold),
//                         ),
//                         Text(
//                           "Qty: $qty | Price: ₹$price | GST: $gst | Discount: $discount",
//                         ),
//                       ],
//                     ),
//                   ),
//                   Expanded(
//                     child: Text(
//                       "₹${total.toStringAsFixed(2)}",
//                       textAlign: TextAlign.end,
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           }).toList(),
//     );
//   }

//   Widget _buildBillSummary() {
//     double totalFinalAmount = 0.0;
//     int totalQuantity = 0;
//     for (var item in billItems) {
//       final price = item["finalPrice"] ?? item["price"] ?? 0.0;
//       final quantity = item["quantity"] ?? 1;
//       totalFinalAmount += (price as double) * (quantity as int);
//       totalQuantity += quantity as int;
//     }
//     final balance = totalFinalAmount - BillData.amountPaid;

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text("Total Items: $totalQuantity"),
//         Text("Total Amount: ₹${totalFinalAmount.toStringAsFixed(2)}"),
//         Text("Net Amount Due: ₹${balance.toStringAsFixed(2)}"),
//       ],
//     );
//   }

//   Widget _buildPaymentDetails() {
//     double total = billItems.fold(0.0, (sum, item) {
//       final p = item["finalPrice"] ?? item["price"] ?? 0.0;
//       final q = item["quantity"] ?? 1;
//       return sum + (p as double) * (q as int);
//     });
//     final balance = total - BillData.amountPaid;

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text("Amount Paid: ₹${BillData.amountPaid.toStringAsFixed(2)}"),
//         Text("Balance Amount: ₹${balance.toStringAsFixed(2)}"),
//         if (BillData.otp.isNotEmpty) Text("Verification Code: ${BillData.otp}"),
//       ],
//     );
//   }

//   Widget _buildFooterQuote() {
//     return const Center(
//       child: Text(
//         "💡 \"Shop smart, save more!\" 💡",
//         style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//       ),
//     );
//   }
// }
