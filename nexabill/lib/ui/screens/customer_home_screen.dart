import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nexabill/core/theme.dart';
import 'package:nexabill/providers/profile_provider.dart';
import 'package:nexabill/ui/widgets/custom_drawer.dart';
import 'package:nexabill/ui/widgets/bottom_input_bar.dart';
import 'package:nexabill/ui/widgets/bill_container.dart';
import 'package:nexabill/ui/screens/profile_screen.dart';
import 'package:nexabill/providers/customer_home_provider.dart';

// ✅ Provider to hold scanned products added via QR screen
final scannedProductsProvider = StateProvider<List<Map<String, dynamic>>>(
  (ref) => [],
);

// ✅ Admin UID selected after mart selection
final selectedAdminUidProvider = StateProvider<String?>((ref) => null);

// ✅ Load all products of selected mart
final productsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final adminUid = ref.watch(selectedAdminUidProvider);
  if (adminUid == null) return [];

  final snapshot =
      await FirebaseFirestore.instance
          .collection("products")
          .doc(adminUid)
          .collection("items")
          .get();

  return snapshot.docs.map((doc) => doc.data()).toList();
});

class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final profileImage = ref.watch(profileImageProvider);
    final selectedMart = ref.watch(selectedMartProvider);
    final adminMarts = ref.watch(adminMartsProvider);
    final scannedProducts = ref.watch(scannedProductsProvider);
    final ScrollController scrollController = ScrollController();

    void onMartSelected(String martName) {
      final martMap = ref.read(adminMartMapProvider);
      debugPrint("💡 Mart Map: $martMap");

      final adminUid = martMap[martName];
      debugPrint("🔐 onMartSelected -> UID for $martName: $adminUid");

      ref.read(selectedMartProvider.notifier).state = martName;
      ref.read(selectedAdminUidProvider.notifier).state = adminUid;

      ref.invalidate(productsProvider);
      ref.invalidate(profileFutureProvider);

      // Clear previous bill items
      ref.read(scannedProductsProvider.notifier).state = [];
    }

    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final bool isKeyboardOpen = keyboardHeight > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("NexaBill"),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: AppTheme.whiteColor,
        elevation: 2,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(fromHome: true),
                    ),
                  ),
              child: CircleAvatar(
                radius: 22,
                backgroundColor:
                    isDarkMode ? Colors.white24 : Colors.grey.shade300,
                child: profileImage.when(
                  data:
                      (imageData) =>
                          imageData != null
                              ? ClipOval(
                                child: Image.memory(
                                  imageData,
                                  fit: BoxFit.cover,
                                  width: 44,
                                  height: 44,
                                ),
                              )
                              : Icon(
                                Icons.person,
                                color: isDarkMode ? Colors.white : Colors.black,
                                size: 28,
                              ),
                  loading:
                      () => const CircularProgressIndicator(strokeWidth: 2),
                  error:
                      (_, __) =>
                          const Icon(Icons.error, color: Colors.red, size: 28),
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: adminMarts.when(
                  data: (marts) {
                    return DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedMart,
                        icon: const Icon(
                          Icons.storefront,
                          color: Colors.blueAccent,
                        ),
                        isExpanded: true,
                        dropdownColor:
                            isDarkMode ? Colors.grey[850] : Colors.white,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        hint: const Text("Select a mart..."),
                        onChanged: (String? newMart) {
                          if (newMart != null) onMartSelected(newMart);
                        },
                        items:
                            marts.map((String mart) {
                              return DropdownMenuItem<String>(
                                value: mart,
                                child: Text(mart),
                              );
                            }).toList(),
                      ),
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (error, _) => Text("Error loading marts: $error"),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double availableHeight = constraints.maxHeight;
                    final double spacing = availableHeight * 0.15;

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          selectedMart == null
                              ? "Please select a mart to generate a bill"
                              : "🛒 Welcome to $selectedMart 🛒",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        SizedBox(height: spacing),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),

          // ✅ Bill Container with dynamic scanned product list
          if (selectedMart != null)
            BillContainer(
              scrollController: scrollController,
              billItems: scannedProducts,
              isKeyboardOpen: isKeyboardOpen,
            ),

          // ✅ Bottom Input Bar
          if (selectedMart != null)
            const Align(
              alignment: Alignment.bottomCenter,
              child: BottomInputBar(),
            ),
        ],
      ),
    );
  }
}
