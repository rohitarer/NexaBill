import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ✅ Provider to Get Current User's Data
final userProvider = Provider<User?>((ref) {
  return FirebaseAuth.instance.currentUser;
});
