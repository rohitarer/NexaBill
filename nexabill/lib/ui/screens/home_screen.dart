import 'package:flutter/material.dart';
import 'package:nexabill/core/theme.dart';
import 'package:nexabill/ui/widgets/custom_drawer.dart';
import 'package:nexabill/ui/widgets/bottom_input_bar.dart';
import 'package:nexabill/ui/widgets/bill_container.dart';
import 'package:nexabill/data/bill_data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController scrollController = ScrollController();

  // ✅ List of available marts
  final List<String> marts = [
    "DMart",
    "Reliance Fresh",
    "Big Bazaar",
    "More Supermarket",
    "Spencer’s",
  ];

  String? selectedMart; // ✅ No default mart selected

  void _onMartSelected(String mart) {
    setState(() {
      selectedMart = mart; // ✅ Set selected mart
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // ✅ Detect keyboard state
    double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    bool isKeyboardOpen = keyboardHeight > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("NexaBill Home"),
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
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor:
                  isDarkMode ? Colors.white24 : Colors.grey.shade300,
              child: Icon(
                Icons.person,
                color: isDarkMode ? Colors.white : Colors.black,
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





// import 'package:flutter/material.dart';
// import 'package:nexabill/core/theme.dart';
// import 'package:nexabill/ui/widgets/custom_drawer.dart';
// import 'package:nexabill/ui/widgets/bottom_input_bar.dart';
// import 'package:nexabill/ui/widgets/bill_container.dart';
// import 'package:nexabill/data/bill_data.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   _HomeScreenState createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   final ScrollController scrollController = ScrollController();

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final isDarkMode = theme.brightness == Brightness.dark;

//     // ✅ Detect if the keyboard is open
//     bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("NexaBill Home"),
//         backgroundColor: theme.appBarTheme.backgroundColor,
//         foregroundColor: AppTheme.whiteColor,
//         elevation: 2,
//         leading: Builder(
//           builder:
//               (context) => IconButton(
//                 icon: const Icon(Icons.menu),
//                 onPressed: () {
//                   Scaffold.of(context).openDrawer();
//                 },
//               ),
//         ),
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 16),
//             child: CircleAvatar(
//               backgroundColor:
//                   isDarkMode ? Colors.white24 : Colors.grey.shade300,
//               child: Icon(
//                 Icons.person,
//                 color: isDarkMode ? Colors.white : Colors.black,
//               ),
//             ),
//           ),
//         ],
//       ),

//       drawer: const CustomDrawer(),

//       body: Stack(
//         children: [
//           const Center(child: Text("Welcome to NexaBill!")),

//           // ✅ Bill Container (Now adjusts when keyboard is open)
//           BillContainer(
//             scrollController: scrollController,
//             billItems: BillData.products,
//             // isKeyboardOpen: isKeyboardOpen, // Pass this to BillContainer
//           ),

//           // ✅ Bottom Input Bar (Always stays at the bottom)
//           const Align(
//             alignment: Alignment.bottomCenter,
//             child: BottomInputBar(),
//           ),
//         ],
//       ),
//     );
//   }
// }

