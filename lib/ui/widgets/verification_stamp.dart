import 'package:flutter/material.dart';

enum StampType { verified, rejected }

class VerificationStamp extends StatelessWidget {
  final StampType type;
  final String martName;

  const VerificationStamp({
    super.key,
    required this.type,
    required this.martName,
  });

  @override
  Widget build(BuildContext context) {
    final bool isVerified = type == StampType.verified;
    final Color stampColor =
        isVerified ? Colors.blue.shade900 : Colors.red.shade900;
    final IconData icon = isVerified ? Icons.check : Icons.close;
    final String label = isVerified ? "VERIFIED" : "REJECTED";

    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Adjusted color for better visibility in dark mode
    final Color adjustedTextColor = isDark ? Colors.white : stampColor;
    final Color adjustedBackground =
        isDark ? stampColor.withOpacity(0.3) : stampColor.withOpacity(0.09);

    return Opacity(
      opacity: 0.8,
      child: Transform.rotate(
        angle: -0.4,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          decoration: BoxDecoration(
            color: adjustedBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: stampColor, width: 8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? stampColor.withOpacity(0.6)
                          : stampColor.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: stampColor, width: 6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      martName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: adjustedTextColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    CircleAvatar(
                      backgroundColor: stampColor,
                      radius: 16,
                      child: Icon(icon, color: Colors.white, size: 18),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: adjustedTextColor,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';

// enum StampType { verified, rejected }

// class VerificationStamp extends StatelessWidget {
//   final StampType type;
//   final String martName;

//   const VerificationStamp({
//     super.key,
//     required this.type,
//     required this.martName,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final bool isVerified = type == StampType.verified;
//     final Color stampColor =
//         isVerified ? Colors.blue.shade900 : Colors.red.shade900;
//     final IconData icon = isVerified ? Icons.thumb_up : Icons.thumb_down;
//     final String label = isVerified ? "VERIFIED" : "REJECTED";

//     debugPrint(
//       "Building VerificationStamp: type = $type, martName = $martName",
//     );

//     return Opacity(
//       opacity: 0.7, // 🔹 Adds slight transparency
//       child: Transform.rotate(
//         angle: -0.4,
//         child: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
//           decoration: BoxDecoration(
//             color: stampColor.withOpacity(0.09),
//             borderRadius: BorderRadius.circular(24),
//             border: Border.all(
//               color: stampColor,
//               width: 8,
//             ), // Thicker outer border
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 50,
//                   vertical: 6,
//                 ),
//                 decoration: BoxDecoration(
//                   color: stampColor.withOpacity(0.4),
//                   borderRadius: BorderRadius.circular(16),
//                   border: Border.all(
//                     color: stampColor,
//                     width: 6,
//                   ), // Thicker inner border
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text(
//                       martName,
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 20,
//                         color: stampColor,
//                       ),
//                     ),
//                     const SizedBox(width: 10),
//                     CircleAvatar(
//                       backgroundColor: stampColor,
//                       radius: 16,
//                       child: Icon(icon, color: Colors.white, size: 18),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 label,
//                 style: TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   color: stampColor,
//                   letterSpacing: 1.2,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
