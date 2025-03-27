import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexabill/data/bill_data.dart';
import 'package:nexabill/providers/bill_verification_provider.dart';
import 'package:nexabill/ui/widgets/verification_stamp.dart';

class BillCardView extends ConsumerWidget {
  final List<Map<String, dynamic>> billItems;
  final BillSealStatus sealStatus;

  const BillCardView({
    super.key,
    required this.billItems,
    required this.sealStatus,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildHeader(isDark),
              const Divider(thickness: 1.5),
              _buildCustomerDetails(),
              const Divider(thickness: 1.5),
              _buildProductList(isDark),
              const Divider(thickness: 1.5),
              _buildBillSummary(isDark),
              const Divider(thickness: 1.5),
              _buildPaymentDetails(isDark),
              const Divider(thickness: 1.5),
              _buildFooterQuote(isDark),
            ],
          ),
          if (sealStatus != BillSealStatus.none)
            Center(
              child: VerificationStamp(
                type:
                    sealStatus == BillSealStatus.sealed
                        ? StampType.verified
                        : StampType.rejected,
                martName: BillData.martName,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "🛒 ${BillData.martName.toUpperCase()} 🛒",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
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
        const SizedBox(height: 6),
        Text(
          "**** CUSTOMER COPY ****",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white70 : Colors.black87,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          "TXN ID: #${BillData.billNo.replaceAll("BILL#", "")} ",
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.blueAccent,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          "📆 ${BillData.billDate}  |  💼 ${BillData.counterNo}",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _buildCustomerDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "${BillData.billNo} | ${BillData.counterNo}",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          "${BillData.billDate}  |  ${BillData.session}",
          style: const TextStyle(fontSize: 15),
        ),
        const SizedBox(height: 5),
        Text(
          BillData.customerName,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(BillData.customerMobile, style: const TextStyle(fontSize: 15)),
        const SizedBox(height: 5),
        Text(
          BillData.cashier,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildProductList(bool isDark) {
    return Column(
      children:
          billItems.map((item) {
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
                          "${item["serial"]}. ${item["name"]}",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        Text(
                          "Qty: ${item["quantity"]} | Price/unit: ₹${item["price"]} | GST: ${item["gst"]} | Discount: ${item["discount"]}",
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "₹${(item["price"] as double) * (item["quantity"] as int)}",
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

  Widget _buildBillSummary(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _billSummaryRow("Total Items:", "${BillData.getTotalQuantity()}"),
        _billSummaryRow(
          "Total Amount:",
          "₹${BillData.getTotalAmount().toStringAsFixed(2)}",
          isBold: true,
        ),
        _billSummaryRow(
          "GST (5%):",
          "₹${BillData.getTotalGST().toStringAsFixed(2)}",
        ),
        _billSummaryRow(
          "Net Amount Due:",
          "₹${BillData.getNetAmountDue().toStringAsFixed(2)}",
          isBold: true,
        ),
      ],
    );
  }

  Widget _buildPaymentDetails(bool isDark) {
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
          "₹${BillData.getBalanceAmount().toStringAsFixed(2)}",
          isBold: true,
        ),
      ],
    );
  }

  Widget _buildFooterQuote(bool isDark) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 10),
          Text(
            "💡 \"Shop smart, save more!\" 💡",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            BillData.footerMessage,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(height: 20),
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
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? Colors.green[800] : null,
            ),
          ),
        ],
      ),
    );
  }
}
