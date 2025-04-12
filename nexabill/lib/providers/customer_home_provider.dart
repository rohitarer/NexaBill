import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 👍 Provider to load profile image from Firestore (base64 -> Uint8List)
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

    final base64String = doc.data()?["profileImageUrl"] as String?;
    if (base64String == null || base64String.isEmpty) return null;

    final padded = base64String.padRight((base64String.length + 3) & ~3, '=');
    return base64Decode(padded);
  } catch (e) {
    debugPrint("\u274c Error in profileImageProvider: $e");
    return null;
  }
});

/// 📉 StateProvider to track selected mart
final selectedMartProvider = StateProvider<String?>((ref) => null);

/// 🗺️ Provider to store mapping of martName -> admin UID
final adminMartMapProvider = StateProvider<Map<String, String>>((ref) => {});

/// 👨‍🎓 AsyncProvider to fetch mart names from admin role
final adminMartsProvider = FutureProvider<List<String>>((ref) async {
  try {
    debugPrint("🔍 Fetching admin marts...");

    final querySnapshot =
        await FirebaseFirestore.instance.collection("users").get();
    debugPrint("📄 Total Users Fetched: ${querySnapshot.docs.length}");

    final List<String> marts = [];
    final Map<String, String> martMap = {};

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final role = data["role"];
      final martName = data["martName"];

      debugPrint("-- Role: $role, Mart: $martName");

      if (role != null &&
          role.toString().toLowerCase() == "admin" &&
          martName != null &&
          martName.toString().trim().isNotEmpty) {
        final name = martName.toString().trim();
        marts.add(name);
        martMap[name] = doc.id; // UID mapping
      }
    }

    ref.read(adminMartMapProvider.notifier).state = martMap;
    debugPrint("✅ Final Mart List: $marts");
    return marts;
  } catch (e) {
    debugPrint("❌ Error fetching admin marts: $e");
    return [];
  }
});

// import 'dart:convert';
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// final profileImageProvider = FutureProvider<Uint8List?>((ref) async {
//   try {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return null;

//     final doc =
//         await FirebaseFirestore.instance
//             .collection("users")
//             .doc(user.uid)
//             .get();

//     if (!doc.exists) return null;

//     final base64String = doc["profileImageUrl"] as String?;
//     if (base64String == null || base64String.isEmpty) return null;

//     // ✅ Fix base64 padding safely
//     final padded = base64String.padRight((base64String.length + 3) & ~3, '=');

//     return base64Decode(padded);
//   } catch (e) {
//     debugPrint("❌ Error in profileImageProvider: $e");
//     return null;
//   }
// });

// /// **📌 StateProvider to Manage Selected Mart**
// final selectedMartProvider = StateProvider<String?>((ref) => null);
