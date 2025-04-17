import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int totalPurchases = 0;
  int totalSealed = 0;
  int totalRejected = 0;
  String graphFilter = 'Week';
  Map<String, int> purchasesPerDay = {};
  Map<String, int> productsPerDay = {};
  int currentGraphIndex = 0;
  Map<String, Map<String, int>> productBreakdown = {};
  Map<String, bool> productExpandState = {};
  Map<String, Map<String, dynamic>> cashierProfiles = {};
  Map<String, bool> cashierExpandState = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchBillStats();
      _fetchCashierAccounts();
    });
  }

  Future<void> _fetchBillStats() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('my_bills')
          .get(const GetOptions(source: Source.serverAndCache));

      int purchases = 0;
      int sealed = 0;
      int rejected = 0;
      Map<String, int> tempPurchasesMap = {};
      Map<String, int> tempProductsMap = {};
      Map<String, Map<String, int>> tempProductBreakdown = {};

      for (final doc in querySnapshot.docs) {
        purchases++;
        final data = doc.data();
        final status = data['sealStatus']?.toString().toLowerCase() ?? "";
        if (status == 'sealed') {
          sealed++;
        } else if (status == 'rejected') {
          rejected++;
        }

        final date = data['billDate'] ?? "";
        if (date.isNotEmpty) {
          final parsedDate = DateFormat("dd-MM-yyyy").parse(date);
          final fullDate = DateFormat("dd MMM yyyy").format(parsedDate);
          String key;
          if (graphFilter == 'Week') {
            key = DateFormat('EEE').format(parsedDate);
          } else if (graphFilter == 'Month') {
            key = 'W${((parsedDate.day - 1) / 7).floor() + 1}';
          } else {
            key = DateFormat('MMM').format(parsedDate);
          }

          tempPurchasesMap[key] = (tempPurchasesMap[key] ?? 0) + 1;

          final productsMap = data['products'] as Map<String, dynamic>?;
          if (productsMap != null) {
            int totalQty = 0;
            for (final entry in productsMap.entries) {
              final item = entry.value;
              if (item is Map<String, dynamic>) {
                final qty = item['quantity'];
                final quantity =
                    qty is int ? qty : int.tryParse(qty.toString()) ?? 0;
                totalQty += quantity;

                final name = item['name']?.toString() ?? entry.key;
                tempProductBreakdown[name] ??= {};
                tempProductBreakdown[name]![fullDate] =
                    (tempProductBreakdown[name]![fullDate] ?? 0) + quantity;
              }
            }
            tempProductsMap[key] = (tempProductsMap[key] ?? 0) + totalQty;
          }
        }
      }

      if (mounted) {
        setState(() {
          totalPurchases = purchases;
          totalSealed = sealed;
          totalRejected = rejected;
          purchasesPerDay = tempPurchasesMap;
          productsPerDay = tempProductsMap;
          productBreakdown = tempProductBreakdown;
          productExpandState = {
            for (final product in tempProductBreakdown.keys) product: false,
          };
        });
      }
    } catch (e) {
      debugPrint("❌ Error fetching stats: $e");
    }
  }

  Future<void> _fetchCashierAccounts() async {
    debugPrint("📡 Fetching all user profiles for cashier filtering...");

    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('users').get();

      final Map<String, Map<String, dynamic>> profiles = {};
      for (final doc in snapshot.docs) {
        final data = doc.data();

        final role = data['role']?.toString().toLowerCase();
        if (role == 'cashier') {
          debugPrint("🧾 Raw cashier doc: ${doc.data()}");

          final fullName = data['fullName'] ?? "No Name";
          final email = data['email'] ?? "N/A";
          final phone = data['phoneNumber'] ?? "N/A";
          final counter = data['counterNumber'] ?? "N/A";
          final mart =
              data['martName'] ?? data['MartName'] ?? data['mart'] ?? "N/A";
          final profileImage = data['profileImageUrl'];

          profiles[doc.id] = {
            'fullName': fullName,
            'email': email,
            'phoneNumber': phone,
            'counterNumber': counter,
            'martName': mart,
            'profileImageUrl': profileImage,
          };

          debugPrint("👤 Cashier found: $fullName ($email) | Mart: $mart");
        }
      }

      debugPrint("🔍 Total cashier accounts found: ${profiles.length}");

      if (mounted) {
        setState(() {
          cashierProfiles = profiles;
          cashierExpandState = {for (final id in profiles.keys) id: false};
        });
      }
    } catch (e) {
      debugPrint("❌ Error fetching cashier profiles: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGraphSwitcher(),
            const SizedBox(height: 20),
            _buildCashierListCard(),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildDashboardCard(
                  title: "Total Purchases",
                  value: totalPurchases.toString(),
                  color: Colors.blue,
                ),
                const SizedBox(width: 16),
                _buildDashboardCard(
                  title: "Verified / Rejected",
                  value: "$totalSealed / $totalRejected",
                  color: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              "Product Sales Summary",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              itemCount: productBreakdown.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final productName = productBreakdown.keys.elementAt(index);
                final salesMap = productBreakdown[productName]!;
                final expanded = productExpandState[productName] ?? false;

                int daily = 0, weekly = 0, monthly = 0;
                salesMap.forEach((k, v) {
                  daily += v;
                  weekly += v;
                  monthly += v;
                });

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              productName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                expanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                              ),
                              onPressed: () {
                                setState(() {
                                  productExpandState[productName] = !expanded;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text("Day: $daily"),
                            Text("Week: $weekly"),
                            Text("Month: $monthly"),
                          ],
                        ),
                        if (expanded)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children:
                                  salesMap.entries
                                      .map(
                                        (e) => Text("• ${e.key}: ${e.value}"),
                                      )
                                      .toList(),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraphSwitcher() {
    final graphs = [
      _buildGraphCard(purchasesPerDay, "User Purchases Overview"),
      _buildGraphCard(productsPerDay, "Products Purchased Overview"),
    ];

    return Column(
      children: [
        SizedBox(
          height: 300,
          child: PageView.builder(
            itemCount: graphs.length,
            onPageChanged: (index) => setState(() => currentGraphIndex = index),
            itemBuilder: (context, index) => graphs[index],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            graphs.length,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    currentGraphIndex == index
                        ? Colors.purple
                        : Colors.grey[400],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGraphCard(Map<String, int> dataMap, String title) {
    final sortedKeys = dataMap.keys.toList()..sort((a, b) => a.compareTo(b));

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 300),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  DropdownButton<String>(
                    value: graphFilter,
                    items:
                        ['Week', 'Month', 'Year']
                            .map(
                              (val) => DropdownMenuItem(
                                value: val,
                                child: Text(val),
                              ),
                            )
                            .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => graphFilter = val);
                        _fetchBillStats();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: BarChart(
                  BarChartData(
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget:
                              (value, meta) => Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  sortedKeys.length > value.toInt()
                                      ? sortedKeys[value.toInt()]
                                      : '',
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: true),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    barGroups: List.generate(sortedKeys.length, (i) {
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: (dataMap[sortedKeys[i]] ?? 0).toDouble(),
                            gradient: const LinearGradient(
                              colors: [Colors.purple, Colors.blue],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            width: 14,
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCashierListCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Cashier Accounts",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        if (cashierProfiles.isEmpty) const Text("No cashier accounts found."),
        ...cashierProfiles.entries.map((entry) {
          final uid = entry.key;
          final profile = entry.value;
          final expanded = cashierExpandState[uid] ?? false;

          final String? base64Image = profile['profileImageUrl'];
          final imageWidget =
              base64Image != null && base64Image.isNotEmpty
                  ? ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: Image.memory(
                      Uri.parse(
                        "data:image/png;base64,$base64Image",
                      ).data!.contentAsBytes(),
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  )
                  : const CircleAvatar(
                    radius: 30,
                    child: Icon(Icons.person, size: 30),
                  );

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      imageWidget,
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          profile['fullName'] ?? 'No Name',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          expanded ? Icons.expand_less : Icons.expand_more,
                        ),
                        onPressed: () {
                          setState(() {
                            cashierExpandState[uid] = !expanded;
                          });
                        },
                      ),
                    ],
                  ),
                  if (expanded)
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(width: 72), // align with text
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "📧 Email   : ${profile['email'] ?? 'N/A'}",
                                ),
                                Text(
                                  "📞 Phone   : ${profile['phoneNumber'] ?? 'N/A'}",
                                ),
                                Text(
                                  "🔢 Counter : ${profile['counterNumber'] ?? 'N/A'}",
                                ),
                                Text(
                                  "🏪 Mart    : ${profile['martName'] ?? 'N/A'}",
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        elevation: 4,
        color: color.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
