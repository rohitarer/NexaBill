import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nexabill/ui/screens/signin_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ **Save User Profile & Mark as Completed**
  Future<void> saveUserProfile(
    String uid,
    Map<String, dynamic> profileData,
  ) async {
    try {
      await _firestore
          .collection("users")
          .doc(uid)
          .set(profileData, SetOptions(merge: true));

      // ✅ Store Profile Completion in Local Storage
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool("profileCompleted", true);

      debugPrint("✅ Profile successfully saved for user: $uid");
    } catch (e) {
      debugPrint("❌ Error saving profile: $e");
    }
  }

  // ✅ **Check Profile Completion & Auto Logout if User Data is Missing**
  // Future<bool> isProfileComplete(BuildContext context) async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();

  //   // 🔹 **Check Local Storage First**
  //   if (prefs.containsKey("profileCompleted")) {
  //     return prefs.getBool("profileCompleted") ?? false;
  //   }

  //   // 🔹 **Check Firebase Authentication**
  //   User? user = _auth.currentUser;
  //   if (user == null) {
  //     debugPrint("⚠️ User not found in Firebase Auth! Forcing logout...");
  //     await forceLogout(context);
  //     return false;
  //   }

  //   try {
  //     DocumentSnapshot userDoc =
  //         await _firestore.collection("users").doc(user.uid).get();

  //     // 🚨 **If Firestore Document is Missing → Auto Logout**
  //     if (!userDoc.exists || userDoc.data() == null) {
  //       debugPrint("⚠️ No user document found in Firestore! Logging out...");
  //       await forceLogout(context);
  //       return false;
  //     }

  //     // ✅ **Check Profile Fields**
  //     Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

  //     bool hasRequiredFields =
  //         userData.containsKey("fullName") &&
  //         userData.containsKey("phoneNumber") &&
  //         userData.containsKey("email");

  //     // ✅ **Allow Partial Profiles: If some fields are missing, show Profile Screen**
  //     if (hasRequiredFields) {
  //       bool isComplete =
  //           userData.containsKey("address") &&
  //           userData.containsKey("city") &&
  //           userData.containsKey("state") &&
  //           userData.containsKey("pin");

  //       // ✅ Store Profile Completion Status in Local Storage
  //       await prefs.setBool("profileCompleted", isComplete);

  //       debugPrint("🔍 Profile Completion Status: $isComplete");

  //       return isComplete;
  //     } else {
  //       debugPrint(
  //         "⚠️ Required user details (Name, Phone, Email) are missing!",
  //       );
  //       await forceLogout(context); // **Logout if critical fields are missing**
  //       return false;
  //     }
  //   } catch (e) {
  //     debugPrint("❌ Error checking profile completion: $e");
  //     await forceLogout(context); // 🔹 Ensure Logout on Error
  //     return false;
  //   }
  // }

  Future<bool> isProfileComplete(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // 🔹 **Check Firebase Authentication**
    User? user = _auth.currentUser;
    if (user == null || user.email == null) {
      // ✅ Logout only if email is missing
      debugPrint("⚠️ User not found OR email is null! Forcing logout...");
      await forceLogout(context);
      return false;
    }

    try {
      DocumentSnapshot userDoc =
          await _firestore.collection("users").doc(user.uid).get();

      if (!userDoc.exists || userDoc.data() == null) {
        debugPrint("⚠️ No user document found in Firestore! Logging out...");
        await forceLogout(context);
        return false;
      }

      // ✅ **Extract User Data Safely**
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      bool hasRequiredFields =
          userData.containsKey("fullName") &&
          userData.containsKey("phoneNumber") &&
          userData.containsKey("email");

      // ✅ **Allow Partial Profiles: If some fields are missing, show Profile Screen**
      if (hasRequiredFields) {
        bool isComplete =
            userData.containsKey("address") &&
            userData.containsKey("city") &&
            userData.containsKey("state") &&
            userData.containsKey("pin");

        await prefs.setBool("profileCompleted", isComplete);
        debugPrint("🔍 Profile Completion Status: $isComplete");

        return isComplete;
      } else {
        debugPrint(
          "⚠️ Required user details (Name, Phone, Email) are missing!",
        );
        await forceLogout(context); // **Logout if critical fields are missing**
        return false;
      }
    } catch (e) {
      debugPrint("❌ Error checking profile completion: $e");
      await forceLogout(context);
      return false;
    }
  }

  // ✅ **Force Logout & Navigate to Sign-In Page**
  Future<void> forceLogout(BuildContext context) async {
    try {
      await _auth.signOut();

      // ✅ Reset Local Profile Completion Status
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove("profileCompleted");

      debugPrint("✅ User successfully logged out.");

      // ✅ Ensure UI updates before navigation
      if (context.mounted) {
        Future.delayed(const Duration(milliseconds: 300), () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const SignInScreen()),
            (route) => false, // Clears the navigation stack
          );
        });
      }
    } catch (e) {
      debugPrint("❌ Error during logout: $e");
    }
  }

  // ✅ **Sign Up with Email & Password & Store Defaults**
  Future<String?> signUp({
    required String fullName,
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
        "phoneNumber": phoneNumber,
        "email": email,
        "profileComplete": false, // Default - profile needs completion
      });

      // ✅ Ensure Profile Completion is False for New Users
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool("profileCompleted", false);

      debugPrint("✅ New user signed up & profile marked incomplete.");
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint("❌ Error during sign-up: ${e.message}");
      return e.message;
    }
  }

  // ✅ **Log In with Email & Password**
  Future<String?> logIn({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      // ✅ Check Profile Completion on Login
      bool isComplete = await isProfileComplete(context);
      debugPrint("🔹 Profile Completion Status on Login: $isComplete");

      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint("❌ Error during login: ${e.message}");
      return e.message;
    }
  }

  // ✅ **Get Current User**
  User? get currentUser => _auth.currentUser;
}




// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:nexabill/ui/screens/signin_screen.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class AuthService {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   // ✅ **Save User Profile & Mark as Completed**
//   Future<void> saveUserProfile(
//     String uid,
//     Map<String, dynamic> profileData,
//   ) async {
//     try {
//       await _firestore
//           .collection("users")
//           .doc(uid)
//           .set(profileData, SetOptions(merge: true));

//       // ✅ Store Profile Completion in Local Storage
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       await prefs.setBool("profileCompleted", true);

//       debugPrint("✅ Profile successfully saved for user: $uid");
//     } catch (e) {
//       debugPrint("❌ Error saving profile: $e");
//     }
//   }

//   // ✅ **Check Profile Completion (Firestore + Local Storage)**
//   Future<bool> isProfileComplete() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();

//     // 🔹 **First, Check Local Storage** (To Optimize Performance)
//     if (prefs.containsKey("profileCompleted")) {
//       return prefs.getBool("profileCompleted") ?? false;
//     }

//     // 🔹 **If Not Found, Fetch from Firestore**
//     User? user = _auth.currentUser;
//     if (user == null) return false;

//     try {
//       DocumentSnapshot userDoc =
//           await _firestore.collection("users").doc(user.uid).get();

//       bool isComplete =
//           userDoc.exists &&
//           userDoc["fullName"] != null &&
//           userDoc["phoneNumber"] != null &&
//           userDoc["email"] != null &&
//           userDoc["address"] != null &&
//           userDoc["city"] != null &&
//           userDoc["state"] != null &&
//           userDoc["pin"] != null;

//       // ✅ Store in Local Storage for future checks
//       await prefs.setBool("profileCompleted", isComplete);

//       debugPrint(
//         "🔍 Profile completion status fetched from Firestore: $isComplete",
//       );

//       return isComplete;
//     } catch (e) {
//       debugPrint("❌ Error checking profile completion: $e");
//       return false;
//     }
//   }

//   // ✅ **Sign Up with Email & Password & Store Defaults**
//   Future<String?> signUp({
//     required String fullName,
//     required String phoneNumber,
//     required String email,
//     required String password,
//   }) async {
//     try {
//       UserCredential userCredential = await _auth
//           .createUserWithEmailAndPassword(email: email, password: password);

//       // ✅ Store user details in Firestore
//       await _firestore.collection("users").doc(userCredential.user!.uid).set({
//         "fullName": fullName,
//         "phoneNumber": phoneNumber,
//         "email": email,
//         "profileComplete": false, // Default - profile needs completion
//       });

//       // ✅ Ensure Profile Completion is False for New Users
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       await prefs.setBool("profileCompleted", false);

//       debugPrint("✅ New user signed up & profile marked incomplete.");

//       return null;
//     } on FirebaseAuthException catch (e) {
//       debugPrint("❌ Error during sign-up: ${e.message}");
//       return e.message; // Return Firebase error message
//     }
//   }

//   // ✅ **Log In with Email & Password**
//   Future<String?> logIn({
//     required String email,
//     required String password,
//   }) async {
//     try {
//       await _auth.signInWithEmailAndPassword(email: email, password: password);

//       // ✅ Check Profile Completion on Login
//       bool isComplete = await isProfileComplete();
//       debugPrint("🔹 Profile Completion Status on Login: $isComplete");

//       return null;
//     } on FirebaseAuthException catch (e) {
//       debugPrint("❌ Error during login: ${e.message}");
//       return e.message;
//     }
//   }

//   // ✅ **Log Out & Navigate to Sign-In Page**
//   Future<void> logOut(BuildContext context) async {
//     try {
//       await _auth.signOut();

//       // ✅ Reset Local Profile Completion Status
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       await prefs.remove("profileCompleted");

//       // ✅ Navigate to Sign-In Page & Clear Stack
//       Navigator.pushAndRemoveUntil(
//         context,
//         MaterialPageRoute(builder: (context) => const SignInScreen()),
//         (route) => false, // Clears the navigation stack
//       );

//       debugPrint("✅ User successfully logged out.");
//     } catch (e) {
//       debugPrint("❌ Error during logout: $e");
//     }
//   }

//   // ✅ **Get Current User**
//   User? get currentUser => _auth.currentUser;
// }


