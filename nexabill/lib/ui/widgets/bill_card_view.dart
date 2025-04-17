import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexabill/data/bill_data.dart';
import 'package:nexabill/providers/bill_verification_provider.dart';
import 'package:nexabill/providers/customer_home_provider.dart';
import 'package:nexabill/providers/bill_details_provider.dart';
import 'package:nexabill/ui/screens/customer_home_screen.dart';
import 'package:nexabill/ui/widgets/verification_stamp.dart';
import 'package:nexabill/ui/widgets/bill_otp_handler.dart';
import 'package:nexabill/ui/widgets/cahier_info_handler.dart';
import 'package:intl/intl.dart';

class BillCardView extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> billItems;

  const BillCardView({super.key, required this.billItems});

  @override
  _BillCardViewState createState() => _BillCardViewState();
}

class _BillCardViewState extends ConsumerState<BillCardView> {
  // final GlobalKey repaintKey = GlobalKey();
  @override
  void initState() {
    super.initState();
    final params = BillDetailsParams(
      customerUid: BillData.customerId,
      billNo: BillData.billNo,
    );

    ref.read(billDetailsProvider(params).future).then((success) {
      if (success == true) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final sealStatus = ref.watch(billVerificationProvider).sealStatus;

    final billFetched = ref.watch(
      billDetailsProvider(
        BillDetailsParams(
          customerUid: BillData.customerId,
          billNo: BillData.billNo,
        ),
      ),
    );

    return billFetched.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text("❌ Error: $e")),
      data: (success) {
        if (!success) {
          return const Center(
            child: Text(
              "🧾 Bill has been generated but is not yet paid or verified.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.black),
            ),
          );
        }

        return Center(
          // child: RepaintBoundary(
          // key: repaintKey,
          child: _buildBillCardUI(context, isDarkMode, sealStatus),
          // ),
        );
      },
    );
  }

  Widget _buildBillCardUI(
    BuildContext context,
    bool isDarkMode,
    BillSealStatus sealStatus,
  ) {
    return Card(
      margin: const EdgeInsets.all(2),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[900] : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(isDarkMode),
                  const Divider(thickness: 1.5),
                  _buildCustomerDetails(),
                  const Divider(thickness: 1.5),
                  _buildProductList(isDarkMode),
                  const Divider(thickness: 1.5),
                  _buildBillSummary(isDarkMode),
                  const Divider(thickness: 1.5),
                  _buildPaymentDetails(isDarkMode),
                  const Divider(thickness: 1.5),
                  _buildFooterQuote(isDarkMode),
                  const SizedBox(height: 40),
                ],
              ),
            ),
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
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "🛒 ${BillData.martName.toUpperCase()} 🛒",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
            letterSpacing: 1.2,
          ),
        ),
        Text(
          BillData.martAddress,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 3),
        Text(
          "📞 ${BillData.martContact}  |  🏢 GSTIN: ${BillData.martGSTIN}",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
        Text(
          "🔹 CIN: ${BillData.martCIN}",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              30,
              (index) => Text(
                "-",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        Text(
          "**** CUSTOMER COPY ****",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white70 : Colors.black87,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          "TXN ID: #${BillData.billNo.replaceAll("BILL#", "")}",
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.blueAccent,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          "📆 ${BillData.billDate}  |  🕒 ${BillData.session}  |  💼 Counter No:${BillData.counterNo}",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              30,
              (index) => Text(
                "-",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerDetails() {
    int hour;
    try {
      if (BillData.session.isNotEmpty) {
        final time = DateFormat('hh:mm a').parse(BillData.session);
        hour = time.hour;
      } else {
        hour = DateTime.now().hour;
      }
    } catch (e) {
      debugPrint("❌ Error parsing BillData.session: $e");
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
          "🧾 ${BillData.billNo} | 💼 Counter No:${BillData.counterNo}",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          "${BillData.billDate}  |  🕒 ${BillData.session}  |  Session: $sessionLabel",
          style: const TextStyle(fontSize: 15),
        ),
        const SizedBox(height: 5),
        Text(
          "Customer: ${BillData.customerName}",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          "Mobile: ${BillData.customerMobile}",
          style: const TextStyle(fontSize: 15),
        ),
        const SizedBox(height: 5),
        Text(
          "Cashier: ${BillData.cashier}",
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildProductList(bool isDarkMode) {
    return Column(
      children:
          widget.billItems.map((item) {
            final serial = item["serial"] ?? 0;
            final name = item["name"] ?? "";
            final qty = item["quantity"] ?? 1;
            final price = item["price"] ?? 0.0;
            final gst = item["gst"] ?? "0%";
            final discount = item["discount"] ?? "0%";
            final finalPrice = item["finalPrice"] ?? price;
            final total = (finalPrice as double) * (qty as int);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
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
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        Text(
                          "Qty: $qty | Price/unit: ₹$price | GST: $gst | Discount: $discount",
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "₹${total.toStringAsFixed(2)}",
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildBillSummary(bool isDarkMode) {
    double totalFinalAmount = 0.0;
    int totalQuantity = 0;

    for (var item in widget.billItems) {
      final price = item["finalPrice"] ?? item["price"] ?? 0.0;
      final quantity = item["quantity"] ?? 1;
      totalFinalAmount += (price as double) * (quantity as int);
      totalQuantity += quantity as int;
    }

    final balance = totalFinalAmount - BillData.amountPaid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _billSummaryRow("Total Items:", "$totalQuantity"),
        _billSummaryRow(
          "Total Amount:",
          "₹${totalFinalAmount.toStringAsFixed(2)}",
          isBold: true,
        ),
        _billSummaryRow(
          "Net Amount Due:",
          "₹${balance.toStringAsFixed(2)}",
          isBold: true,
        ),
      ],
    );
  }

  Widget _buildPaymentDetails(bool isDarkMode) {
    double total = widget.billItems.fold(0.0, (sum, item) {
      final p = item["finalPrice"] ?? item["price"] ?? 0.0;
      final q = item["quantity"] ?? 1;
      return sum + (p as double) * (q as int);
    });

    final balance = total - BillData.amountPaid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _billSummaryRow(
          "Amount Paid:",
          "₹${BillData.amountPaid.toStringAsFixed(2)}",
          isBold: true,
        ),
        _billSummaryRow(
          "Balance Amount:",
          "₹${balance.toStringAsFixed(2)}",
          isBold: true,
        ),
        if (BillData.otp.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: _billSummaryRow(
              "Verification Code:",
              BillData.otp,
              isBold: true,
            ),
          ),
      ],
    );
  }

  Widget _buildFooterQuote(bool isDarkMode) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 10),
          Text(
            "💡 \"Shop smart, save more!\" 💡",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _billSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: isBold ? Colors.green[800] : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
