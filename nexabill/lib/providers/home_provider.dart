import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// **📌 FutureProvider to Fetch Profile Image from Firestore**
// final profileImageProvider = FutureProvider<Uint8List?>((ref) async {
//   try {
//     User? user = FirebaseAuth.instance.currentUser;
//     if (user == null) return null;

//     DocumentSnapshot userDoc =
//         await FirebaseFirestore.instance
//             .collection("users")
//             .doc(user.uid)
//             .get();

//     if (!userDoc.exists) return null;

//     String? base64String = userDoc["profileImageUrl"];

//     if (base64String != null && base64String.isNotEmpty) {
//       return base64Decode(base64String); // ✅ Decode Base64 String to Image
//     }

//     return null;
//   } catch (e) {
//     print("❌ Error fetching profile image: $e");
//     return null;
//   }
// });
// final profileImageProvider = FutureProvider<Uint8List?>((ref) async {
//   final user = FirebaseAuth.instance.currentUser;
//   if (user == null) return null;

//   final doc =
//       await FirebaseFirestore.instance.collection("users").doc(user.uid).get();
//   if (!doc.exists) return null;

//   final base64String = doc["profileImageUrl"] ?? "";
//   if (base64String.isEmpty) return null;

//   // Pad if needed
//   String padded = base64String;
//   while (padded.length % 4 != 0) {
//     padded += '=';
//   }

//   return base64Decode(padded);
// });

final profileImageProvider = FutureProvider<Uint8List?>((ref) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc =
        await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .get();

    if (!doc.exists) return null;

    final base64String = doc["profileImageUrl"] as String?;
    if (base64String == null || base64String.isEmpty) return null;

    // ✅ Fix base64 padding safely
    final padded = base64String.padRight((base64String.length + 3) & ~3, '=');

    return base64Decode(padded);
  } catch (e) {
    debugPrint("❌ Error in profileImageProvider: $e");
    return null;
  }
});

/// **📌 StateProvider to Manage Selected Mart**
final selectedMartProvider = StateProvider<String?>((ref) => null);
