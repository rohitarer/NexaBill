import 'package:flutter/material.dart';
import 'package:nexabill/ui/screens/qr_scanner_screen.dart';
import 'package:permission_handler/permission_handler.dart';

class BottomInputBar extends StatefulWidget {
  const BottomInputBar({super.key});

  @override
  _BottomInputBarState createState() => _BottomInputBarState();
}

class _BottomInputBarState extends State<BottomInputBar> {
  final TextEditingController _controller = TextEditingController();
  bool _showExtraIcons = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            spreadRadius: 2,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: TextFormField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: "Enter amount...",
          hintStyle: TextStyle(color: theme.hintColor),
          filled: true,
          fillColor: theme.cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.dividerColor),
          ),
          suffixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 💳 Payment Icon
                IconButton(
                  icon: const Icon(Icons.payment),
                  color: theme.iconTheme.color,
                  onPressed: () {
                    // TODO: Add payment logic
                  },
                ),

                // ➕ Toggle Icons
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder:
                      (child, anim) =>
                          FadeTransition(opacity: anim, child: child),
                  child:
                      _showExtraIcons
                          ? Row(
                            key: const ValueKey("icons"),
                            children: [
                              IconButton(
                                icon: const Icon(Icons.qr_code_scanner),
                                color: theme.iconTheme.color,
                                onPressed: () async {
                                  final status =
                                      await Permission.camera.request();
                                  if (status.isGranted) {
                                    showDialog(
                                      context: context,
                                      builder:
                                          (_) => const Dialog(
                                            backgroundColor: Colors.transparent,
                                            insetPadding: EdgeInsets.all(20),
                                            child: AspectRatio(
                                              aspectRatio: 1,
                                              child: QRScannerScreen(),
                                            ),
                                          ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Camera permission required.",
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.mic),
                                color: theme.iconTheme.color,
                                onPressed: () {
                                  // TODO: Implement mic input
                                },
                              ),
                            ],
                          )
                          : const SizedBox(key: ValueKey("empty")),
                ),

                // Toggle Button (➕ ➖)
                IconButton(
                  icon: Icon(_showExtraIcons ? Icons.remove : Icons.add),
                  color: theme.iconTheme.color,
                  onPressed:
                      () => setState(() => _showExtraIcons = !_showExtraIcons),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:nexabill/ui/screens/qr_scanner_screen.dart'; // Add your scanner screen import
// import 'package:permission_handler/permission_handler.dart';

// class BottomInputBar extends StatefulWidget {
//   const BottomInputBar({super.key});

//   @override
//   _BottomInputBarState createState() => _BottomInputBarState();
// }

// class _BottomInputBarState extends State<BottomInputBar> {
//   final TextEditingController _controller = TextEditingController();
//   bool _showExtraIcons = false;

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       decoration: BoxDecoration(
//         color: theme.scaffoldBackgroundColor,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 5,
//             spreadRadius: 2,
//             offset: const Offset(0, -2),
//           ),
//         ],
//       ),
//       child: TextFormField(
//         controller: _controller,
//         decoration: InputDecoration(
//           hintText: "Enter amount...",
//           hintStyle: TextStyle(color: theme.hintColor),
//           filled: true,
//           fillColor: theme.cardColor,
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: BorderSide(color: theme.dividerColor),
//           ),
//           suffixIcon: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 6),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 AnimatedContainer(
//                   duration: const Duration(milliseconds: 300),
//                   curve: Curves.easeInOut,
//                   width: _showExtraIcons ? 40 : 48,
//                   child: IconButton(
//                     icon: const Icon(Icons.payment),
//                     color: theme.iconTheme.color,
//                     onPressed: () {
//                       // TODO: Implement payment logic
//                     },
//                   ),
//                 ),
//                 AnimatedSwitcher(
//                   duration: const Duration(milliseconds: 300),
//                   child:
//                       _showExtraIcons
//                           ? Row(
//                             children: [
//                               const SizedBox(width: 4),
//                               IconButton(
//                                 icon: const Icon(Icons.qr_code_scanner),
//                                 color: theme.iconTheme.color,
//                                 onPressed: () async {
//                                   final status =
//                                       await Permission.camera.request();
//                                   if (status.isGranted) {
//                                     showDialog(
//                                       context: context,
//                                       builder:
//                                           (context) => const Dialog(
//                                             backgroundColor: Colors.transparent,
//                                             insetPadding: EdgeInsets.all(20),
//                                             child: AspectRatio(
//                                               aspectRatio: 1,
//                                               child: QRScannerScreen(),
//                                             ),
//                                           ),
//                                     );
//                                   } else {
//                                     ScaffoldMessenger.of(context).showSnackBar(
//                                       const SnackBar(
//                                         content: Text(
//                                           "Camera permission is required to scan QR codes.",
//                                         ),
//                                       ),
//                                     );
//                                   }
//                                 },
//                               ),
//                               const SizedBox(width: 4),
//                               IconButton(
//                                 icon: const Icon(Icons.mic),
//                                 color: theme.iconTheme.color,
//                                 onPressed: () {
//                                   // TODO: Implement mic input
//                                 },
//                               ),
//                             ],
//                           )
//                           : const SizedBox(),
//                 ),
//                 IconButton(
//                   icon: Icon(_showExtraIcons ? Icons.remove : Icons.add),
//                   color: theme.iconTheme.color,
//                   onPressed: () {
//                     setState(() => _showExtraIcons = !_showExtraIcons);
//                   },
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
