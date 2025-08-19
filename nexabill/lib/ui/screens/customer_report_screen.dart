import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class CustomerReportScreen extends StatefulWidget {
  const CustomerReportScreen({super.key});

  @override
  State<CustomerReportScreen> createState() => _CustomerReportScreenState();
}

class _CustomerReportScreenState extends State<CustomerReportScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  String generatedInsight = '';
  List<Map<String, dynamic>> _reportData = [];
  Map<String, int> productFrequency = {};
  Map<String, String> martDetails = {
    "name": "",
    "address": "",
    "state": "",
    "phone": "",
    "gstin": "",
    "cin": "",
  };

  final model = GenerativeModel(
    model: 'gemini-1.5-pro',
    apiKey: 'AIzaSyCkU_JlG3NMFco_sCPywrJ9BWVtuHcBnGw', // Your Gemini API key
  );

  @override
  void initState() {
    super.initState();
    _loadMartDetails();
  }

  Future<void> _loadMartDetails() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final snapshot =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = snapshot.data();
    if (data != null) {
      setState(() {
        martDetails = {
          "name": data["martName"] ?? "Mart",
          "address": data["martAddress"] ?? "Address",
          "state": data["martCity"] ?? "State",
          "phone": data["martContact"] ?? "Phone",
          "gstin": data["martGstin"] ?? "GSTIN",
          "cin": data["martCin"] ?? "CIN",
        };
      });
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _generateReport() async {
    if (_startDate == null || _endDate == null) return;
    setState(() {
      _isLoading = true;
      _reportData.clear();
      productFrequency.clear();
      generatedInsight = '';
    });

    try {
      final users = await FirebaseFirestore.instance.collection('users').get();
      final allBills = <Map<String, dynamic>>[];
      final Map<String, int> tempProductFreq = {};

      for (var user in users.docs) {
        final userData = user.data();
        if ((userData['role'] ?? '').toLowerCase() == 'customer') {
          final bills =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.id)
                  .collection('my_bills')
                  .get();

          for (var bill in bills.docs) {
            final data = bill.data();
            final billDate = DateFormat("dd-MM-yyyy").parse(data['billDate']);
            if (billDate.isAfter(
                  _startDate!.subtract(const Duration(days: 1)),
                ) &&
                billDate.isBefore(_endDate!.add(const Duration(days: 1)))) {
              allBills.add({
                'amount': data['amountPaid'] ?? 0,
                'date': data['billDate'],
                'products': data['products'] ?? {},
              });

              final products = data['products'] as Map<String, dynamic>;
              for (var product in products.values) {
                final name = product['name'] ?? 'Unnamed';
                tempProductFreq[name] = (tempProductFreq[name] ?? 0) + 1;
              }
            }
          }
        }
      }

      setState(() {
        _reportData = allBills;
        productFrequency = tempProductFreq;
      });

      await _generateInsightFromGemini();
    } catch (e) {
      debugPrint("❌ Error generating report: $e");
    }

    setState(() => _isLoading = false);
  }

  Future<void> _generateInsightFromGemini() async {
    final totalRevenue = _reportData.fold<double>(
      0,
      (sum, item) => sum + (item['amount'] as num).toDouble(),
    );

    final topProducts =
        productFrequency.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    final prompt = '''
You are a professional data analyst preparing a formal financial and product performance report for a retail business.

Please generate an official summary document based on the following data:

- Total Number of Bills: ${_reportData.length}
- Total Revenue Generated: ₹${totalRevenue.toStringAsFixed(2)}
- Top Selling Products (by frequency): ${topProducts.take(5).map((e) => e.key).join(', ')}

The report should include:
1. An executive summary highlighting key insights.
2. Revenue analysis for the selected period.
3. Customer buying patterns based on top products.
4. Business recommendations to improve profitability.
5. A formal conclusion.

Format it as a structured document suitable for presentation to the CEO, Finance Manager, and Chartered Accountant. Use professional tone, bullet points, and section headings.
''';

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      setState(() {
        generatedInsight = response.text ?? 'No insight generated.';
      });
    } catch (e) {
      debugPrint("❌ Gemini Error: $e");
      setState(() {
        generatedInsight =
            "Failed to generate AI summary. Please check API key and network.";
      });
    }
  }

  Widget _buildInsightBox() {
    return generatedInsight.isNotEmpty
        ? Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(generatedInsight, style: const TextStyle(fontSize: 15)),
        )
        : const SizedBox.shrink();
  }

  Widget _buildReportList() {
    return ListView.builder(
      itemCount: _reportData.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final item = _reportData[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("🗓️ Date: ${item['date']} | 💰 ₹${item['amount']}"),
            const Text(
              "🛒 Products:",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            ...((item['products'] as Map<String, dynamic>).values).map<Widget>((
              prod,
            ) {
              return Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Text("• ${prod['name']} (Qty: ${prod['quantity']})"),
              );
            }),
            const Divider(),
          ],
        );
      },
    );
  }

  Widget _buildMartHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          martDetails['name'] ?? '',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text("${martDetails['address']}, ${martDetails['state']}, India"),
        Text("Phone: ${martDetails['phone']}"),
        Text("GSTIN: ${martDetails['gstin']} | CIN: ${martDetails['cin']}"),
        const Divider(thickness: 1),
      ],
    );
  }

  Future<void> _downloadPDF() async {
    final pdf = pw.Document();

    final totalRevenue = _reportData.fold<double>(
      0,
      (sum, item) => sum + (item['amount'] as num).toDouble(),
    );

    final topProducts =
        productFrequency.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    pdf.addPage(
      pw.MultiPage(
        build:
            (context) => [
              pw.Text(
                martDetails['name'] ?? 'NexaBill Mart',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                "${martDetails['address']}, ${martDetails['state']}, India",
              ),
              pw.Text("Phone: ${martDetails['phone']}"),
              pw.Text(
                "GSTIN: ${martDetails['gstin']} | CIN: ${martDetails['cin']}",
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                "Report Period: ${DateFormat.yMMMd().format(_startDate!)} - ${DateFormat.yMMMd().format(_endDate!)}",
              ),
              pw.Text("Total Bills: ${_reportData.length}"),
              pw.Text("Total Revenue: ₹${totalRevenue.toStringAsFixed(2)}"),
              pw.SizedBox(height: 10),
              if (generatedInsight.isNotEmpty) ...[
                pw.Text(
                  "Gemini Insight:",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(generatedInsight),
                pw.Divider(),
              ],
              pw.Text(
                "Top Products:",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              ...topProducts
                  .take(10)
                  .map((e) => pw.Text("• ${e.key}: ${e.value} times")),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.Text(
                "Detailed Transactions:",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              ..._reportData.map(
                (item) => pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "Date: ${item['date']} | Amount: ₹${item['amount']}",
                    ),
                    ...((item['products'] as Map<String, dynamic>).values)
                        .map<pw.Widget>((prod) {
                          return pw.Padding(
                            padding: const pw.EdgeInsets.only(left: 12),
                            child: pw.Text(
                              "• ${prod['name']} (Qty: ${prod['quantity']})",
                            ),
                          );
                        }),
                    pw.Divider(),
                  ],
                ),
              ),
            ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}/Customer_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());

    Share.shareXFiles([
      XFile(file.path),
    ], text: '🧾 Customer Report - NexaBill');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Customer Report"), centerTitle: true),
      // floatingActionButton:
      //     _reportData.isNotEmpty
      //         ? FloatingActionButton.extended(
      //           icon: const Icon(Icons.download),
      //           label: const Text("Download PDF"),
      //           onPressed: _downloadPDF,
      //         )
      //         : null,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      _startDate == null || _endDate == null
                          ? "Select Date Range"
                          : "${DateFormat.yMMMd().format(_startDate!)} - ${DateFormat.yMMMd().format(_endDate!)}",
                    ),
                    onPressed: () => _selectDateRange(context),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _generateReport,
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text("Generate"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_reportData.isNotEmpty)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMartHeader(),
                      const SizedBox(height: 10),
                      _buildInsightBox(),
                      // _buildReportList(),
                    ],
                  ),
                ),
              ),
            if (_reportData.isEmpty && !_isLoading)
              const Expanded(child: Center(child: Text("No data found."))),
          ],
        ),
      ),
    );
  }
}

// // No change to imports
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:google_generative_ai/google_generative_ai.dart';
// import 'package:intl/intl.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:path_provider/path_provider.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:pdf/pdf.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class CustomerReportScreen extends StatefulWidget {
//   const CustomerReportScreen({super.key});

//   @override
//   State<CustomerReportScreen> createState() => _CustomerReportScreenState();
// }

// class _CustomerReportScreenState extends State<CustomerReportScreen> {
//   DateTime? _startDate;
//   DateTime? _endDate;
//   bool _isLoading = false;
//   List<Map<String, dynamic>> _reportData = [];
//   Map<String, int> productFrequency = {};
//   Map<String, dynamic>? martDetails;

//   @override
//   void initState() {
//     super.initState();
//     _fetchMartDetails();
//   }

//   final model = GenerativeModel(
//     model: 'gemini-pro',
//     apiKey: 'AIzaSyD4Zs7RkPSNgbJnOSqzhtV9uI2q_LPkaSE',
//   );

//   Future<String> generateDescriptiveReport({
//     required int totalBills,
//     required double totalRevenue,
//     required List<String> topProducts,
//   }) async {
//     final prompt = '''
//   Generate a detailed summary for a customer report with the following data:
//   - Total Bills: $totalBills
//   - Total Revenue: ₹${totalRevenue.toStringAsFixed(2)}
//   - Top Products: ${topProducts.join(', ')}

//   Provide insights and recommendations based on this data.
//   ''';

//     final response = await model.generateContent([Content.text(prompt)]);
//     return response.text ?? 'No summary generated.';
//   }

//   Future<void> _fetchMartDetails() async {
//     final uid = FirebaseAuth.instance.currentUser?.uid;
//     if (uid == null) return;

//     try {
//       final doc =
//           await FirebaseFirestore.instance.collection('users').doc(uid).get();
//       final data = doc.data();
//       if (data == null) return;

//       debugPrint("📦 Mart Data: $data");

//       setState(() {
//         martDetails = {
//           'name': data['martName'] ?? 'NexaBill Mart',
//           'address': data['martAddress'] ?? 'Not available',
//           'state': data['martCity'] ?? 'N/A', // mapped from martCity
//           'phone': data['martContact'] ?? 'N/A',
//           'gstin': data['martGstin'] ?? 'N/A',
//           'cin': data['martCin'] ?? 'N/A',
//         };
//       });
//     } catch (e) {
//       debugPrint("❌ Error fetching mart details: $e");
//     }
//   }

//   Future<void> _selectDateRange(BuildContext context) async {
//     final picked = await showDateRangePicker(
//       context: context,
//       firstDate: DateTime(2024),
//       lastDate: DateTime.now(),
//     );
//     if (picked != null) {
//       setState(() {
//         _startDate = picked.start;
//         _endDate = picked.end;
//       });
//     }
//   }

//   Future<void> _generateReport() async {
//     if (_startDate == null || _endDate == null) return;
//     setState(() {
//       _isLoading = true;
//       _reportData.clear();
//       productFrequency.clear();
//     });

//     try {
//       final users = await FirebaseFirestore.instance.collection('users').get();
//       final List<Map<String, dynamic>> allBills = [];
//       final Map<String, int> tempProductFreq = {};

//       for (var user in users.docs) {
//         final userData = user.data();
//         if ((userData['role'] ?? '').toLowerCase() == 'customer') {
//           final bills =
//               await FirebaseFirestore.instance
//                   .collection('users')
//                   .doc(user.id)
//                   .collection('my_bills')
//                   .get();

//           for (var bill in bills.docs) {
//             final data = bill.data();
//             final billDate = DateFormat("dd-MM-yyyy").parse(data['billDate']);
//             if (billDate.isAfter(
//                   _startDate!.subtract(const Duration(days: 1)),
//                 ) &&
//                 billDate.isBefore(_endDate!.add(const Duration(days: 1)))) {
//               allBills.add({
//                 'amount': data['amountPaid'] ?? 0,
//                 'date': data['billDate'],
//                 'products': data['products'] ?? {},
//               });

//               final products = data['products'] as Map<String, dynamic>;
//               for (var product in products.values) {
//                 final name = product['name'] ?? 'Unnamed';
//                 tempProductFreq[name] = (tempProductFreq[name] ?? 0) + 1;
//               }
//             }
//           }
//         }
//       }

//       setState(() {
//         _reportData = allBills;
//         productFrequency = tempProductFreq;
//       });
//     } catch (e) {
//       debugPrint("❌ Error generating report: $e");
//     }

//     setState(() => _isLoading = false);
//   }

//   Future<void> _downloadPDF() async {
//     final pdf = pw.Document();
//     final totalRevenue = _reportData.fold<double>(
//       0,
//       (sum, item) => sum + (item['amount'] as num).toDouble(),
//     );

//     final topProducts =
//         productFrequency.entries.toList()
//           ..sort((a, b) => b.value.compareTo(a.value));

//     pdf.addPage(
//       pw.MultiPage(
//         pageFormat: PdfPageFormat.a4,
//         build:
//             (context) => [
//               pw.Center(
//                 child: pw.Text(
//                   martDetails?['name'] ?? "Mart Name",
//                   style: pw.TextStyle(
//                     fontSize: 20,
//                     fontWeight: pw.FontWeight.bold,
//                   ),
//                 ),
//               ),
//               pw.Center(
//                 child: pw.Text(
//                   "${martDetails?['address']}, ${martDetails?['state']}, India",
//                 ),
//               ),
//               pw.Center(child: pw.Text("Phone: ${martDetails?['phone']}")),
//               pw.Center(
//                 child: pw.Text(
//                   "GSTIN: ${martDetails?['gstin']} | CIN: ${martDetails?['cin']}",
//                 ),
//               ),
//               pw.SizedBox(height: 10),
//               pw.Text(
//                 "📅 Report Period: ${DateFormat.yMMMd().format(_startDate!)} - ${DateFormat.yMMMd().format(_endDate!)}",
//               ),
//               pw.Text("🧾 Total Bills: ${_reportData.length}"),
//               pw.Text("💰 Total Revenue: ₹${totalRevenue.toStringAsFixed(2)}"),
//               pw.SizedBox(height: 10),
//               pw.Text(
//                 "📦 Top Purchased Products:",
//                 style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//               ),
//               ...topProducts
//                   .take(10)
//                   .map((e) => pw.Text("• ${e.key}: ${e.value} times")),
//               pw.Divider(),
//               pw.Text(
//                 "🗂 Product-wise Transaction Summary:",
//                 style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//               ),
//               ..._reportData.map(
//                 (item) => pw.Column(
//                   crossAxisAlignment: pw.CrossAxisAlignment.start,
//                   children: [
//                     pw.Text(
//                       "Date: ${item['date']}    Amount: ₹${item['amount']}",
//                     ),
//                     ...((item['products'] as Map<String, dynamic>).values).map(
//                       (prod) => pw.Padding(
//                         padding: const pw.EdgeInsets.only(left: 12),
//                         child: pw.Text(
//                           "• ${prod['name']} (Qty: ${prod['quantity']})",
//                         ),
//                       ),
//                     ),
//                     pw.Divider(),
//                   ],
//                 ),
//               ),
//             ],
//       ),
//     );

//     final dir = await getApplicationDocumentsDirectory();
//     final file = File(
//       "${dir.path}/Mart_Report_${DateTime.now().millisecondsSinceEpoch}.pdf",
//     );
//     await file.writeAsBytes(await pdf.save());

//     Share.shareXFiles([XFile(file.path)], text: '📄 Mart Report - NexaBill');
//   }

//   Widget _buildMartHeader() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//         Text(
//           martDetails?['name'] ?? 'NexaBill Mart',
//           style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//         ),
//         Text("${martDetails?['address']}, ${martDetails?['state']}, India"),
//         Text("Phone: ${martDetails?['phone']}"),
//         Text("GSTIN: ${martDetails?['gstin']}    CIN: ${martDetails?['cin']}"),
//         const Divider(thickness: 1),
//       ],
//     );
//   }

//   Widget _buildSummary() {
//     final totalRevenue = _reportData.fold<double>(
//       0,
//       (sum, item) => sum + (item['amount'] as num).toDouble(),
//     );
//     final topProducts =
//         productFrequency.entries.toList()
//           ..sort((a, b) => b.value.compareTo(a.value));

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           "Report Period: ${DateFormat.yMMMd().format(_startDate!)} - ${DateFormat.yMMMd().format(_endDate!)}",
//         ),
//         Text("🧾 Total Bills: ${_reportData.length}"),
//         Text("💰 Total Revenue: ₹${totalRevenue.toStringAsFixed(2)}"),
//         const SizedBox(height: 8),
//         const Text(
//           "📦 Most Purchased Products:",
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         ...topProducts
//             .take(10)
//             .map((e) => Text("• ${e.key}: ${e.value} times")),
//         const Divider(),
//       ],
//     );
//   }

//   Widget _buildReportList() {
//     return ListView.builder(
//       itemCount: _reportData.length,
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       itemBuilder: (context, index) {
//         final item = _reportData[index];
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text("Date: ${item['date']} | Amount: ₹${item['amount']}"),
//             const Text(
//               "Products:",
//               style: TextStyle(fontWeight: FontWeight.w500),
//             ),
//             ...((item['products'] as Map<String, dynamic>).values).map<Widget>((
//               prod,
//             ) {
//               return Padding(
//                 padding: const EdgeInsets.only(left: 12),
//                 child: Text("• ${prod['name']} (Qty: ${prod['quantity']})"),
//               );
//             }).toList(),
//             const Divider(),
//           ],
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Customer Report"),
//         centerTitle: true,
//         actions:
//             _reportData.isNotEmpty
//                 ? [
//                   IconButton(
//                     icon: const Icon(Icons.download),
//                     onPressed: _downloadPDF,
//                   ),
//                 ]
//                 : null,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             Row(
//               children: [
//                 Expanded(
//                   child: ElevatedButton.icon(
//                     icon: const Icon(Icons.date_range),
//                     label: Text(
//                       _startDate == null || _endDate == null
//                           ? "Select Date Range"
//                           : "${DateFormat.yMMMd().format(_startDate!)} - ${DateFormat.yMMMd().format(_endDate!)}",
//                     ),
//                     onPressed: () => _selectDateRange(context),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 ElevatedButton(
//                   onPressed: _generateReport,
//                   child:
//                       _isLoading
//                           ? const SizedBox(
//                             width: 16,
//                             height: 16,
//                             child: CircularProgressIndicator(strokeWidth: 2),
//                           )
//                           : const Text("Generate"),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//             if (_reportData.isNotEmpty)
//               Expanded(
//                 child: SingleChildScrollView(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       _buildMartHeader(),
//                       const SizedBox(height: 10),
//                       _buildSummary(),
//                       _buildReportList(),
//                     ],
//                   ),
//                 ),
//               ),
//             if (_reportData.isEmpty && !_isLoading)
//               const Expanded(child: Center(child: Text("No data found."))),
//           ],
//         ),
//       ),
//     );
//   }
// }
