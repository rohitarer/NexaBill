import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ Get Current User
  User? get currentUser => _auth.currentUser;

  // ✅ Sign Up (Returns error message if any, otherwise null)
  Future<String?> signUp({
    required String fullName,
    required String role,
    required String phoneNumber,
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // ✅ Store user details in Firestore
      await _firestore.collection("users").doc(userCredential.user!.uid).set({
        "fullName": fullName,
        "role": role,
        "phoneNumber": phoneNumber,
        "email": email,
        "isProfileComplete": false, // ✅ Use existing field
      });

      // ✅ Store Profile Completion status locally
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool("isProfileComplete", false);

      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message; // Return error message
    }
  }

  // ✅ Log In (Returns error message if any, otherwise null)
  Future<String?> logIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      // ✅ Check Profile Completion
      bool isComplete = await isProfileComplete();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool("isProfileComplete", isComplete);

      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<bool> isProfileComplete() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // 🔹 **First, Check Locally**
    if (prefs.containsKey("isProfileComplete")) {
      return prefs.getBool("isProfileComplete") ?? false;
    }

    // 🔹 **Then Check Firebase**
    User? user = _auth.currentUser;
    if (user == null || user.email == null) {
      return false; // No user logged in
    }

    try {
      DocumentSnapshot userDoc =
          await _firestore.collection("users").doc(user.uid).get();

      if (!userDoc.exists || userDoc.data() == null) {
        return false;
      }

      // ✅ Extract User Data
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      bool isComplete =
          userData.containsKey("fullName") &&
          userData.containsKey("phoneNumber") &&
          userData.containsKey("gender") &&
          userData.containsKey("dob") &&
          userData.containsKey("address") &&
          userData.containsKey("city") &&
          userData.containsKey("state") &&
          userData.containsKey("pin") &&
          userData["state"]
              .toString()
              .trim()
              .isNotEmpty && // ✅ Ensure state is NOT empty
          userData["isProfileComplete"] ==
              true; // ✅ Use only `isProfileComplete`

      // ✅ Store in Local Storage
      await prefs.setBool("isProfileComplete", isComplete);

      return isComplete;
    } catch (e) {
      return false;
    }
  }

  // ✅ Update Profile Completion Status
  Future<void> updateProfileCompletionStatus() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection("users").doc(user.uid).update({
        "isProfileComplete": true, // ✅ Set the existing field to true
      });

      // ✅ Update local storage
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool("isProfileComplete", true);
    } catch (e) {
      print("Error updating profile completion: $e");
    }
  }

  // ✅ Log Out
  Future<void> logOut() async {
    await _auth.signOut();

    // ✅ Clear Local Storage
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove("isProfileComplete");
  }
}
