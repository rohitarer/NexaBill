import 'package:flutter/material.dart';
import 'package:nexabill/core/theme.dart';
import 'package:nexabill/data/bill_data.dart';

class BillContainer extends StatefulWidget {
  final ScrollController scrollController;
  final List<Map<String, dynamic>> billItems;
  final bool isKeyboardOpen;

  const BillContainer({
    super.key,
    required this.scrollController,
    required this.billItems,
    required this.isKeyboardOpen,
  });

  @override
  _BillContainerState createState() => _BillContainerState();
}

class _BillContainerState extends State<BillContainer> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // ✅ Get available screen height dynamically
    double screenHeight = MediaQuery.of(context).size.height;
    double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    double bottomPadding = widget.isKeyboardOpen ? keyboardHeight : 0;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 250),
      left: 0,
      right: 0,
      bottom: bottomPadding,
      child: SizedBox(
        height: screenHeight * 0.95,
        child: DraggableScrollableSheet(
          initialChildSize: 0.4,
          minChildSize: 0.4,
          maxChildSize: 0.98,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.black : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    spreadRadius: 2,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ✅ **Optimized & Attractive DMart Bill Header**
  Widget _buildHeader(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ─────────────── DMart Logo/Title ───────────────
        Text(
          "🛒 ${BillData.martName.toUpperCase()} 🛒",
          style: TextStyle(
            fontSize: 24, // Highlighted store name
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
            letterSpacing: 1.2,
          ),
        ),

        // 📍 Address (Compact Format)
        Text(
          BillData.martAddress,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),

        // ☎ Contact & GSTIN (Formatted Properly)
        const SizedBox(height: 3),
        Text(
          "📞 ${BillData.martContact}  |  🏢 GSTIN: ${BillData.martGSTIN}",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),

        // 🏢 CIN Number in Single Line
        Text(
          "🔹 CIN: ${BillData.martCIN}",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),

        // ✂️ **Separator Line with Dotted Style for a Receipt Feel**
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

        // 📜 **Customer Copy / Transaction Receipt Label**
        Text(
          "**** CUSTOMER COPY ****",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white70 : Colors.black87,
            letterSpacing: 1.1,
          ),
        ),

        // 🔻 Transaction Code (Like Real Receipts)
        const SizedBox(height: 3),
        Text(
          "TXN ID: #${BillData.billNo.replaceAll("BILL#", "")}",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.blueAccent,
          ),
        ),

        // 🕒 Bill Date & Counter Information
        const SizedBox(height: 3),
        Text(
          "📆 ${BillData.billDate}  |  💼 ${BillData.counterNo}",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),

        // ✂️ **Final Separator Line**
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

  // ✅ **Customer & Bill Details**
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
        const SizedBox(height: 5), // ✅ Adding space before cashier name
        Text(
          BillData.cashier, // ✅ Adding Cashier Name
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // // ✅ **Customer & Bill Details**
  // Widget _buildCustomerDetails() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         "${BillData.billNo} | ${BillData.counterNo}",
  //         style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  //       ),
  //       Text(
  //         "${BillData.billDate}  |  ${BillData.session}",
  //         style: const TextStyle(fontSize: 15),
  //       ),
  //       const SizedBox(height: 5),
  //       Text(
  //         "${BillData.customerName}",
  //         style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  //       ),
  //       Text(
  //         "${BillData.customerMobile}",
  //         style: const TextStyle(fontSize: 15),
  //       ),
  //     ],
  //   );
  // }

  // ✅ **Scrollable Product List with Price per Unit**
  Widget _buildProductList(bool isDarkMode) {
    return Column(
      children:
          widget.billItems.map((item) {
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
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        Text(
                          "Qty: ${item["quantity"]} | Price/unit: ₹${item["price"]} | GST: ${item["gst"]} | Discount: ${item["discount"]}",
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

  // ✅ **Bill Summary**
  Widget _buildBillSummary(bool isDarkMode) {
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

  // ✅ **Payment Details**
  Widget _buildPaymentDetails(bool isDarkMode) {
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

  // ✅ **Footer Quote**
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
          const SizedBox(height: 5),
          Text(
            BillData.footerMessage,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
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

// import 'package:flutter/material.dart';
// import 'package:nexabill/core/theme.dart';
// import 'package:nexabill/data/bill_data.dart';

// class BillContainer extends StatefulWidget {
//   final ScrollController scrollController;
//   final List<Map<String, dynamic>> billItems;
//   final bool isKeyboardOpen;

//   const BillContainer({
//     super.key,
//     required this.scrollController,
//     required this.billItems,
//     required this.isKeyboardOpen,
//   });

//   @override
//   _BillContainerState createState() => _BillContainerState();
// }

// class _BillContainerState extends State<BillContainer> {
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final isDarkMode = theme.brightness == Brightness.dark;

//     // ✅ Get available screen height dynamically
//     double screenHeight = MediaQuery.of(context).size.height;
//     double keyboardHeight =
//         MediaQuery.of(context).viewInsets.bottom; // ✅ Dynamic keyboard height
//     double bottomPadding =
//         widget.isKeyboardOpen
//             ? keyboardHeight
//             : 0; // ✅ Adjust only when keyboard opens

//     return AnimatedPositioned(
//       duration: const Duration(milliseconds: 250),
//       left: 0,
//       right: 0,
//       bottom: bottomPadding, // ✅ Move just above the keyboard dynamically
//       child: SizedBox(
//         height: screenHeight * 0.95, // ✅ Maximize height usage
//         child: DraggableScrollableSheet(
//           initialChildSize: 0.4, // ✅ Start at 40% of the screen
//           minChildSize: 0.4, // ✅ Minimum when collapsed
//           maxChildSize: 0.98, // ✅ Expand almost full screen
//           expand: false, // ✅ Prevent infinite height issues
//           builder: (context, scrollController) {
//             return Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: isDarkMode ? Colors.black : Colors.white,
//                 borderRadius: const BorderRadius.vertical(
//                   top: Radius.circular(16),
//                 ),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.1),
//                     blurRadius: 8,
//                     spreadRadius: 2,
//                     offset: const Offset(0, -4),
//                   ),
//                 ],
//               ),
//               child: SingleChildScrollView(
//                 controller: scrollController,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     _buildHeader(isDarkMode),
//                     const Divider(thickness: 1.5),
//                     _buildCustomerDetails(),
//                     const Divider(thickness: 1.5),
//                     _buildProductList(isDarkMode),
//                     const Divider(thickness: 1.5),
//                     _buildBillSummary(isDarkMode),
//                     const Divider(thickness: 1.5),
//                     _buildPaymentDetails(isDarkMode),
//                     const Divider(thickness: 1.5),
//                     _buildFooterQuote(isDarkMode),
//                     const SizedBox(height: 20),
//                   ],
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }

//   // ✅ **Header (Mart Information)**
//   Widget _buildHeader(bool isDarkMode) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//         Text(
//           BillData.martName,
//           style: TextStyle(
//             fontSize: 26,
//             fontWeight: FontWeight.bold,
//             color: isDarkMode ? Colors.white : Colors.black,
//           ),
//         ),
//         const SizedBox(height: 5),
//         Text(
//           BillData.martAddress,
//           style: const TextStyle(fontSize: 15, color: Colors.grey),
//         ),
//         Text(
//           "Contact: ${BillData.martContact}",
//           style: const TextStyle(fontSize: 15, color: Colors.grey),
//         ),
//         Text(
//           "GSTIN: ${BillData.martGSTIN}  |  CIN: ${BillData.martCIN}",
//           style: const TextStyle(fontSize: 13, color: Colors.grey),
//         ),
//       ],
//     );
//   }

//   // ✅ **Customer & Bill Details**
//   Widget _buildCustomerDetails() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           "${BillData.billNo} | ${BillData.counterNo}",
//           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//         ),
//         Text(
//           "${BillData.billDate}  |  ${BillData.session}",
//           style: const TextStyle(fontSize: 15),
//         ),
//         const SizedBox(height: 5),
//         Text(
//           "${BillData.customerName}",
//           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//         ),
//         Text(
//           "${BillData.customerMobile}",
//           style: const TextStyle(fontSize: 15),
//         ),
//       ],
//     );
//   }

//   // ✅ **Scrollable Product List**
//   Widget _buildProductList(bool isDarkMode) {
//     return Column(
//       children:
//           widget.billItems.map((item) {
//             return Padding(
//               padding: const EdgeInsets.symmetric(vertical: 6),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Expanded(
//                     flex: 2,
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           "${item["serial"]}. ${item["name"]}",
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                             color: isDarkMode ? Colors.white : Colors.black,
//                           ),
//                         ),
//                         Text(
//                           "Qty: ${item["quantity"]} | GST: ${item["gst"]} | Discount: ${item["discount"]}",
//                           style: TextStyle(
//                             fontSize: 14,
//                             color: isDarkMode ? Colors.white70 : Colors.black54,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   Expanded(
//                     child: Text(
//                       "₹${(item["price"] as double) * (item["quantity"] as int)}",
//                       textAlign: TextAlign.right,
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.green[700],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           }).toList(),
//     );
//   }

//   // ✅ **Bill Summary**
//   Widget _buildBillSummary(bool isDarkMode) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         _billSummaryRow("Total Items:", "${BillData.getTotalQuantity()}"),
//         _billSummaryRow(
//           "Total Amount:",
//           "₹${BillData.getTotalAmount().toStringAsFixed(2)}",
//           isBold: true,
//         ),
//         _billSummaryRow(
//           "GST (5%):",
//           "₹${BillData.getTotalGST().toStringAsFixed(2)}",
//         ),
//         _billSummaryRow(
//           "Net Amount Due:",
//           "₹${BillData.getNetAmountDue().toStringAsFixed(2)}",
//           isBold: true,
//         ),
//       ],
//     );
//   }

//   // ✅ **Payment Details**
//   Widget _buildPaymentDetails(bool isDarkMode) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         _billSummaryRow(
//           "Amount Paid:",
//           "₹${BillData.amountPaid.toStringAsFixed(2)}",
//           isBold: true,
//         ),
//         _billSummaryRow(
//           "Balance Amount:",
//           "₹${BillData.getBalanceAmount().toStringAsFixed(2)}",
//           isBold: true,
//         ),
//       ],
//     );
//   }

//   // ✅ **Footer Quote**
//   Widget _buildFooterQuote(bool isDarkMode) {
//     return Center(
//       child: Column(
//         children: [
//           const SizedBox(height: 10),
//           Text(
//             "💡 \"Shop smart, save more!\" 💡",
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: isDarkMode ? Colors.white70 : Colors.black87,
//             ),
//           ),
//           const SizedBox(height: 5),
//           Text(
//             BillData.footerMessage,
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//               color: isDarkMode ? Colors.white54 : Colors.black54,
//             ),
//           ),
//           const SizedBox(height: 20),
//         ],
//       ),
//     );
//   }

//   // ✅ **Bill Summary Row**
//   Widget _billSummaryRow(String label, String value, {bool isBold = false}) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 5),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             label,
//             style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
//           ),
//           Text(
//             value,
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
//               color: isBold ? Colors.green[800] : null,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
