import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexabill/core/theme.dart';
import 'package:nexabill/ui/widgets/custom_drawer.dart';
import 'package:nexabill/ui/widgets/bottom_input_bar.dart';
import 'package:nexabill/ui/widgets/bill_container.dart';
import 'package:nexabill/data/bill_data.dart';
import 'package:nexabill/providers/home_provider.dart'; // ✅ Import Home Provider
import 'package:nexabill/ui/screens/profile_screen.dart'; // ✅ Import Profile Screen

class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final profileImage = ref.watch(
      profileImageProvider,
    ); // ✅ Fetch Profile Image
    final selectedMart = ref.watch(
      selectedMartProvider,
    ); // ✅ Watch Selected Mart

    final ScrollController scrollController = ScrollController();

    // ✅ List of available marts
    final List<String> marts = [
      "DMart",
      "Reliance Fresh",
      "Big Bazaar",
      "More Supermarket",
      "Spencer’s",
    ];

    void _onMartSelected(String mart) {
      ref.read(selectedMartProvider.notifier).state = mart;
    }

    // ✅ Detect keyboard state
    double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    bool isKeyboardOpen = keyboardHeight > 0;

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
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
        ),
        actions: [
          // GestureDetector(
          //   onTap: () {
          //     // ✅ Navigate to Profile Screen when tapped
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(builder: (context) => ProfileScreen()),
          //     );
          //   },
          //   child: Padding(
          //     padding: const EdgeInsets.only(right: 16),
          //     child: CircleAvatar(
          //       backgroundColor:
          //           isDarkMode ? Colors.white24 : Colors.grey.shade300,
          //       child: profileImage.when(
          //         data:
          //             (imageData) =>
          //                 imageData != null
          //                     ? ClipOval(
          //                       child: Image.memory(
          //                         imageData,
          //                         fit: BoxFit.cover,
          //                         width: 6, // ✅ Set avatar size
          //                         height: 6,
          //                       ),
          //                     )
          //                     : Icon(
          //                       Icons.person,
          //                       color: isDarkMode ? Colors.white : Colors.black,
          //                     ),
          //         loading:
          //             () => const CircularProgressIndicator(), // ✅ Show loader
          //         error:
          //             (_, __) => Icon(
          //               Icons.error,
          //               color: Colors.red,
          //             ), // ✅ Show error icon if fetching fails
          //       ),
          //     ),
          //   ),
          // ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(fromHome: true),
                  ),
                );
              },
              child: CircleAvatar(
                radius: 22, // ✅ Restore proper avatar size
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
                                  width: 44, // ✅ Ensure image fills the avatar
                                  height:
                                      44, // ✅ Keep it square to fit properly
                                ),
                              )
                              : Icon(
                                Icons.person,
                                color: isDarkMode ? Colors.white : Colors.black,
                                size:
                                    28, // ✅ Adjust icon size for better visibility
                              ),
                  loading:
                      () => const CircularProgressIndicator(strokeWidth: 2),
                  error:
                      (_, __) => Icon(Icons.error, color: Colors.red, size: 28),
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
              // ✅ Mart Selection Dropdown (Your UI Design)
              Padding(
                padding: const EdgeInsets.all(12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedMart,
                    icon: const Icon(
                      Icons.storefront,
                      color: Colors.blueAccent,
                    ),
                    isExpanded: true,
                    dropdownColor: isDarkMode ? Colors.grey[850] : Colors.white,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    hint: const Text("Select a mart..."), // ✅ Added hint text
                    onChanged: (String? newMart) {
                      if (newMart != null) {
                        _onMartSelected(newMart);
                      }
                    },
                    items:
                        marts.map<DropdownMenuItem<String>>((String mart) {
                          return DropdownMenuItem<String>(
                            value: mart,
                            child: Text(mart),
                          );
                        }).toList(),
                  ),
                ),
              ),

              // ✅ Centered Text (Before & After Selection)
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    double availableHeight =
                        constraints.maxHeight; // Get screen height dynamically
                    double spacing =
                        availableHeight * 0.15; // Adjust spacing proportionally

                    return Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center, // ✅ Perfectly centers text
                      children: [
                        Text(
                          selectedMart == null
                              ? "Please select a mart to generate a bill"
                              : "🛒 Welcome to $selectedMart 🛒", // ✅ Dynamic text change
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18, // ✅ Font size remains elegant
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        SizedBox(
                          height: spacing,
                        ), // ✅ Dynamically adjusts spacing
                      ],
                    );
                  },
                ),
              ),
            ],
          ),

          // ✅ Show BillContainer **ONLY** when a mart is selected
          if (selectedMart != null)
            BillContainer(
              scrollController: scrollController,
              billItems: BillData.products,
              isKeyboardOpen: isKeyboardOpen,
            ),

          // ✅ Bottom Input Bar (Always stays at the bottom)
          const Align(
            alignment: Alignment.bottomCenter,
            child: BottomInputBar(),
          ),
        ],
      ),
    );
  }
}
