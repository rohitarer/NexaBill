// import 'package:flutter/material.dart';
// import 'package:nexabill/data/marts_data.dart';
// import 'package:nexabill/core/theme.dart';
// import 'package:nexabill/services/role_routes.dart';
// import 'package:nexabill/ui/screens/customerHome_screen.dart';
// import '../widgets/custom_button.dart';
// import '../widgets/custom_dropdown.dart';

// class MartSelectionScreen extends StatefulWidget {
//   const MartSelectionScreen({super.key});

//   @override
//   _MartSelectionScreenState createState() => _MartSelectionScreenState();
// }

// class _MartSelectionScreenState extends State<MartSelectionScreen> {
//   String? selectedMart;

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final isDarkMode = theme.brightness == Brightness.dark;

//     // Dynamic Colors
//     final textColor = isDarkMode ? AppTheme.whiteColor : AppTheme.textColor;
//     final labelColor = isDarkMode ? Colors.white70 : Colors.black87;
//     final hintColor = isDarkMode ? Colors.white54 : Colors.grey;
//     final inputFillColor = isDarkMode ? AppTheme.darkGrey : AppTheme.lightGrey;

//     return Scaffold(
//       backgroundColor: theme.scaffoldBackgroundColor,
//       appBar: AppBar(
//         title: const Text("Mart Selection"),
//         centerTitle: true,
//         // backgroundColor: Colors.brown, // Match design
//         // foregroundColor: Colors.white,
//       ),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const SizedBox(height: 80),
//               Text(
//                 "Marts",
//                 style: TextStyle(
//                   fontSize: 50,
//                   fontWeight: FontWeight.bold,
//                   color: textColor,
//                 ),
//               ),
//               const SizedBox(height: 50),

//               // Dropdown for Mart Selection
//               Align(
//                 alignment: Alignment.centerLeft,
//                 child: Text(
//                   "Select Mart",
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.blue, // Match design
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 8),

//               // Custom Dropdown
//               CustomDropdown(
//                 value: selectedMart,
//                 hintText: "Choose a mart",
//                 items: marts,
//                 textColor: textColor,
//                 hintColor: hintColor,
//                 fillColor: inputFillColor,
//                 onChanged: (value) {
//                   setState(() => selectedMart = value);
//                 },
//               ),

//               const SizedBox(height: 30),

//               // Next Button
//               CustomButton(
//                 text: "Next",
//                 onPressed: () {
//                   if (selectedMart != null) {
//                     debugPrint("Selected Mart: $selectedMart");

//                     // Navigate to Next Page
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder:
//                             (context) => RoleRoutes.getHomeScreen(
//                               role,
//                               isComplete,
//                             ), // Placeholder
//                       ),
//                     );
//                   } else {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(
//                         content: Text("Please select a mart"),
//                         backgroundColor: Colors.red,
//                       ),
//                     );
//                   }
//                 },
//               ),
//               const Spacer(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // import 'package:flutter/material.dart';
// // import '../widgets/custom_button.dart'; // Assuming you use a custom button

// // class MartSelectionScreen extends StatefulWidget {
// //   const MartSelectionScreen({super.key});

// //   @override
// //   _MartSelectionScreenState createState() => _MartSelectionScreenState();
// // }

// // class _MartSelectionScreenState extends State<MartSelectionScreen> {
// //   String? selectedMart;

// //   final List<String> marts = [
// //     "V2-VALUE & VARIETY",
// //     "Reliance Fresh",
// //     "Big Bazaar",
// //     "DMart",
// //   ];

// //   @override
// //   Widget build(BuildContext context) {
// //     final theme = Theme.of(context);
// //     final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;

// //     return Scaffold(
// //       backgroundColor: theme.scaffoldBackgroundColor,
// //       appBar: AppBar(
// //         title: const Text("Mart Selection"),
// //         centerTitle: true,
// //         backgroundColor: Colors.brown, // Adjusted to match design
// //         foregroundColor: Colors.white,
// //       ),
// //       body: Center(
// //         child: Padding(
// //           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
// //           child: Column(
// //             mainAxisAlignment: MainAxisAlignment.center,
// //             children: [
// //               Text(
// //                 "Marts",
// //                 style: TextStyle(
// //                   fontSize: 28,
// //                   fontWeight: FontWeight.bold,
// //                   color: textColor,
// //                 ),
// //               ),
// //               const SizedBox(height: 30),

// //               // Dropdown for Mart Selection
// //               Align(
// //                 alignment: Alignment.centerLeft,
// //                 child: Text(
// //                   "Select Mart",
// //                   style: TextStyle(
// //                     fontSize: 16,
// //                     fontWeight: FontWeight.bold,
// //                     color: Colors.blue, // Adjusted to match design
// //                   ),
// //                 ),
// //               ),
// //               const SizedBox(height: 8),
// //               DropdownButtonFormField<String>(
// //                 value: selectedMart,
// //                 items:
// //                     marts.map((mart) {
// //                       return DropdownMenuItem(value: mart, child: Text(mart));
// //                     }).toList(),
// //                 onChanged: (value) {
// //                   setState(() => selectedMart = value);
// //                 },
// //                 decoration: InputDecoration(
// //                   filled: true,
// //                   fillColor: Colors.white,
// //                   border: OutlineInputBorder(
// //                     borderRadius: BorderRadius.circular(10),
// //                   ),
// //                   contentPadding: const EdgeInsets.symmetric(horizontal: 16),
// //                 ),
// //               ),
// //               const SizedBox(height: 20),

// //               // Next Button
// //               CustomButton(
// //                 text: "Next",
// //                 onPressed: () {
// //                   if (selectedMart != null) {
// //                     // TODO: Navigate to the next page
// //                     debugPrint("Selected Mart: $selectedMart");
// //                   } else {
// //                     ScaffoldMessenger.of(context).showSnackBar(
// //                       const SnackBar(
// //                         content: Text("Please select a mart"),
// //                         backgroundColor: Colors.red,
// //                       ),
// //                     );
// //                   }
// //                 },
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
