import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 🧠 Stores the selected mart name from dropdown or card tap
final selectedMartProvider = StateProvider<String?>((ref) => null);

// 🧠 Maps mart name to admin UID (used for fetching correct mart data)
final adminMartMapProvider = FutureProvider<Map<String, String>>((ref) async {
  final snapshot =
      await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

  final map = <String, String>{};
  for (var doc in snapshot.docs) {
    final data = doc.data();
    final martName = data['martName']?.toString().trim();
    if (martName != null && martName.isNotEmpty) {
      map[martName] = doc.id; // 🔁 martName → UID
    }
  }

  return map;
});

// 🧠 Fetches product list of selected mart
final productListProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final selectedMart = ref.watch(selectedMartProvider);
      if (selectedMart == null || selectedMart.isEmpty) return [];

      final martMap = await ref.watch(adminMartMapProvider.future);
      final adminUID = martMap[selectedMart];
      if (adminUID == null) return [];

      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(adminUID)
              .get(); // ✅ await here

      final data = snapshot.data();
      if (data == null || data['products'] == null) return [];

      final List<dynamic> rawProducts = data['products'];
      return rawProducts.whereType<List>().map((item) {
        return {
          "name": item[0] ?? '',
          "price": item[1] ?? '',
          "pid": item[2] ?? '',
        };
      }).toList();
    });
