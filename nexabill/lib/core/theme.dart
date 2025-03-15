import 'package:flutter/material.dart';

class AppTheme {
  // Define Colors
  static const Color primaryColor = Color(0xFF1A237E); // Deep Blue
  static const Color secondaryColor = Color(0xFF00BCD4); // Bright Cyan
  static const Color successColor = Color(0xFF4CAF50); // Soft Green
  static const Color backgroundColor = Color(0xFFF5F5F5); // Lighter Gray
  static const Color textColor = Color(0xFF424242); // Dark Gray
  static const Color aiHighlightColor = Color(0xFF673AB7); // Electric Purple
  static const Color warningColor = Color(0xFFD32F2F); // Warning Red
  static const Color whiteColor = Color(0xFFFFFFFF); // Pure White
  static const Color blackColor = Color(0xFF000000); // Black
  static const Color lightGrey = Color(
    0xFFE0E0E0,
  ); // Soft Light Grey for input fields
  static const Color darkGrey = Color(0xFF212121); // Darker Grey for dark mode

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor, // Lighter Background
    textTheme: const TextTheme(
      bodyLarge: TextStyle(fontSize: 18, color: textColor),
      bodyMedium: TextStyle(fontSize: 16, color: textColor),
      bodySmall: TextStyle(fontSize: 14, color: textColor),
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: lightGrey,
      filled: true,
      border: OutlineInputBorder(
        borderSide: BorderSide(color: textColor),
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: whiteColor,
      ),
      iconTheme: IconThemeData(color: whiteColor),
    ),
    iconTheme: const IconThemeData(color: textColor),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: secondaryColor,
        foregroundColor: whiteColor,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
    ),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData.dark().copyWith(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: darkGrey, // Slightly lighter dark mode background
    textTheme: const TextTheme(
      bodyLarge: TextStyle(fontSize: 18, color: whiteColor),
      bodyMedium: TextStyle(fontSize: 16, color: whiteColor),
      bodySmall: TextStyle(fontSize: 14, color: whiteColor),
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: textColor,
      filled: true,
      border: OutlineInputBorder(
        borderSide: BorderSide(color: whiteColor),
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: whiteColor,
      ),
      iconTheme: IconThemeData(color: whiteColor),
    ),
    iconTheme: const IconThemeData(color: whiteColor),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: secondaryColor,
        foregroundColor: whiteColor,
      ),
    ),
  );
}



// import 'package:flutter/material.dart';

// class AppTheme {
//   // Define Colors
//   static const Color primaryColor = Color(0xFF1A237E); // Deep Blue
//   static const Color secondaryColor = Color(0xFF00BCD4); // Bright Cyan
//   static const Color successColor = Color(0xFF4CAF50); // Soft Green
//   static const Color backgroundColor = Color(0xFFECEFF1); // Light Gray
//   static const Color textColor = Color(0xFF424242); // Dark Gray
//   static const Color aiHighlightColor = Color(0xFF673AB7); // Electric Purple
//   static const Color warningColor = Color(0xFFD32F2F); // Warning Red
//   static const Color whiteColor = Color(0xFFFFFFFF); // Pure White

//   // Light Theme
//   static ThemeData lightTheme = ThemeData(
//     primaryColor: primaryColor,
//     scaffoldBackgroundColor: backgroundColor,
//     textTheme: const TextTheme(
//       bodyLarge: TextStyle(fontSize: 18, color: textColor),
//       bodyMedium: TextStyle(fontSize: 16, color: textColor),
//       bodySmall: TextStyle(fontSize: 14, color: textColor),
//     ),
//     appBarTheme: const AppBarTheme(
//       backgroundColor: primaryColor,
//       titleTextStyle: TextStyle(
//         fontSize: 20,
//         fontWeight: FontWeight.bold,
//         color: whiteColor,
//       ),
//       iconTheme: IconThemeData(color: whiteColor),
//     ),
//     elevatedButtonTheme: ElevatedButtonThemeData(
//       style: ElevatedButton.styleFrom(
//         backgroundColor: secondaryColor,
//         foregroundColor: whiteColor,
//         textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.all(Radius.circular(8)),
//         ),
//       ),
//     ),
//     outlinedButtonTheme: OutlinedButtonThemeData(
//       style: OutlinedButton.styleFrom(
//         foregroundColor: secondaryColor,
//         side: const BorderSide(color: secondaryColor, width: 2),
//         textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.all(Radius.circular(8)),
//         ),
//       ),
//     ),
//     // cardTheme: const CardTheme(
//     //   color: whiteColor,
//     //   shadowColor: textColor,
//     //   elevation: 3,
//     //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
//     // ),
//     floatingActionButtonTheme: const FloatingActionButtonThemeData(
//       backgroundColor: secondaryColor,
//       foregroundColor: whiteColor,
//     ),
//     snackBarTheme: const SnackBarThemeData(
//       backgroundColor: warningColor,
//       contentTextStyle: TextStyle(
//         color: whiteColor,
//         fontWeight: FontWeight.bold,
//       ),
//     ),
//   );

//   // Dark Theme
//   static ThemeData darkTheme = ThemeData.dark().copyWith(
//     primaryColor: primaryColor,
//     scaffoldBackgroundColor: textColor,
//     textTheme: const TextTheme(
//       bodyLarge: TextStyle(fontSize: 18, color: whiteColor),
//       bodyMedium: TextStyle(fontSize: 16, color: whiteColor),
//       bodySmall: TextStyle(fontSize: 14, color: whiteColor),
//     ),
//     appBarTheme: const AppBarTheme(
//       backgroundColor: primaryColor,
//       titleTextStyle: TextStyle(
//         fontSize: 20,
//         fontWeight: FontWeight.bold,
//         color: whiteColor,
//       ),
//       iconTheme: IconThemeData(color: whiteColor),
//     ),
//     elevatedButtonTheme: ElevatedButtonThemeData(
//       style: ElevatedButton.styleFrom(
//         backgroundColor: secondaryColor,
//         foregroundColor: whiteColor,
//       ),
//     ),
//     outlinedButtonTheme: OutlinedButtonThemeData(
//       style: OutlinedButton.styleFrom(
//         foregroundColor: whiteColor,
//         side: const BorderSide(color: secondaryColor, width: 2),
//       ),
//     ),
//     // cardTheme: const CardTheme(
//     //   color: textColor,
//     //   shadowColor: whiteColor,
//     // ),
//     floatingActionButtonTheme: const FloatingActionButtonThemeData(
//       backgroundColor: secondaryColor,
//       foregroundColor: whiteColor,
//     ),
//     snackBarTheme: const SnackBarThemeData(
//       backgroundColor: warningColor,
//       contentTextStyle: TextStyle(
//         color: whiteColor,
//         fontWeight: FontWeight.bold,
//       ),
//     ),
//   );
// }

