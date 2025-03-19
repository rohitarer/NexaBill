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

  // ✅ Check Profile Completion (Returns `true` or `false`)
  // Future<bool> isProfileComplete() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();

  //   // 🔹 **First, Check Locally**
  //   if (prefs.containsKey("isProfileComplete")) {
  //     return prefs.getBool("isProfileComplete") ?? false;
  //   }

  //   // 🔹 **Then Check Firebase**
  //   User? user = _auth.currentUser;
  //   if (user == null || user.email == null) {
  //     return false; // No user logged in
  //   }

  //   try {
  //     DocumentSnapshot userDoc =
  //         await _firestore.collection("users").doc(user.uid).get();

  //     if (!userDoc.exists || userDoc.data() == null) {
  //       return false;
  //     }

  //     // ✅ Extract User Data
  //     Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

  //     bool isComplete =
  //         userData["isProfileComplete"] ?? false; // ✅ Read from Firestore

  //     // ✅ Store in Local Storage
  //     await prefs.setBool("isProfileComplete", isComplete);

  //     return isComplete;
  //   } catch (e) {
  //     return false;
  //   }
  // }

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




// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class AuthService {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   // ✅ Get Current User
//   User? get currentUser => _auth.currentUser;

//   // ✅ Sign Up (Returns error message if any, otherwise null)
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
//         "isProfileComplete": false, // Marks profile as incomplete
//       });

//       // ✅ Store Profile Completion status locally
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       await prefs.setBool("isProfileCompleted", false);

//       return null; // Success
//     } on FirebaseAuthException catch (e) {
//       return e.message; // Return error message
//     }
//   }

//   // ✅ Log In (Returns error message if any, otherwise null)
//   Future<String?> logIn({
//     required String email,
//     required String password,
//   }) async {
//     try {
//       await _auth.signInWithEmailAndPassword(email: email, password: password);

//       // ✅ Check Profile Completion
//       bool isComplete = await isProfileComplete();
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       await prefs.setBool("isProfileCompleted", isComplete);

//       return null; // Success
//     } on FirebaseAuthException catch (e) {
//       return e.message;
//     }
//   }

//   // ✅ Check Profile Completion (Returns `true` or `false`)
//   Future<bool> isProfileComplete() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();

//     // 🔹 **First, Check Locally**
//     if (prefs.containsKey("isProfileCompleted")) {
//       return prefs.getBool("isProfileCompleted") ?? false;
//     }

//     // 🔹 **Then Check Firebase**
//     User? user = _auth.currentUser;
//     if (user == null || user.email == null) {
//       return false; // No user logged in
//     }

//     try {
//       DocumentSnapshot userDoc =
//           await _firestore.collection("users").doc(user.uid).get();

//       if (!userDoc.exists || userDoc.data() == null) {
//         return false;
//       }

//       // ✅ Extract User Data
//       Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

//       bool isComplete =
//           userData.containsKey("address") &&
//           userData.containsKey("city") &&
//           userData.containsKey("state") &&
//           userData.containsKey("pin");

//       // ✅ Store in Local Storage
//       await prefs.setBool("isProfileCompleted", isComplete);

//       return isComplete;
//     } catch (e) {
//       return false;
//     }
//   }

//   // ✅ Log Out
//   Future<void> logOut() async {
//     await _auth.signOut();

//     // ✅ Clear Local Storage
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     await prefs.remove("isProfileCompleted");
//   }
// }



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
//       await prefs.setBool("isProfileCompleted", true);

//       debugPrint("✅ Profile successfully saved for user: $uid");
//     } catch (e) {
//       debugPrint("❌ Error saving profile: $e");
//     }
//   }

//   // ✅ **Check Profile Completion & Auto Logout if User Data is Missing**
//   // Future<bool> isProfileComplete(BuildContext context) async {
//   //   SharedPreferences prefs = await SharedPreferences.getInstance();

//   //   // 🔹 **Check Local Storage First**
//   //   if (prefs.containsKey("isProfileCompleted")) {
//   //     return prefs.getBool("isProfileCompleted") ?? false;
//   //   }

//   //   // 🔹 **Check Firebase Authentication**
//   //   User? user = _auth.currentUser;
//   //   if (user == null) {
//   //     debugPrint("⚠️ User not found in Firebase Auth! Forcing logout...");
//   //     await forceLogout(context);
//   //     return false;
//   //   }

//   //   try {
//   //     DocumentSnapshot userDoc =
//   //         await _firestore.collection("users").doc(user.uid).get();

//   //     // 🚨 **If Firestore Document is Missing → Auto Logout**
//   //     if (!userDoc.exists || userDoc.data() == null) {
//   //       debugPrint("⚠️ No user document found in Firestore! Logging out...");
//   //       await forceLogout(context);
//   //       return false;
//   //     }

//   //     // ✅ **Check Profile Fields**
//   //     Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

//   //     bool hasRequiredFields =
//   //         userData.containsKey("fullName") &&
//   //         userData.containsKey("phoneNumber") &&
//   //         userData.containsKey("email");

//   //     // ✅ **Allow Partial Profiles: If some fields are missing, show Profile Screen**
//   //     if (hasRequiredFields) {
//   //       bool isComplete =
//   //           userData.containsKey("address") &&
//   //           userData.containsKey("city") &&
//   //           userData.containsKey("state") &&
//   //           userData.containsKey("pin");

//   //       // ✅ Store Profile Completion Status in Local Storage
//   //       await prefs.setBool("isProfileCompleted", isComplete);

//   //       debugPrint("🔍 Profile Completion Status: $isComplete");

//   //       return isComplete;
//   //     } else {
//   //       debugPrint(
//   //         "⚠️ Required user details (Name, Phone, Email) are missing!",
//   //       );
//   //       await forceLogout(context); // **Logout if critical fields are missing**
//   //       return false;
//   //     }
//   //   } catch (e) {
//   //     debugPrint("❌ Error checking profile completion: $e");
//   //     await forceLogout(context); // 🔹 Ensure Logout on Error
//   //     return false;
//   //   }
//   // }

//   Future<bool> isProfileComplete(BuildContext context) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();

//     // 🔹 **Check Firebase Authentication**
//     User? user = _auth.currentUser;
//     if (user == null || user.email == null) {
//       // ✅ Logout only if email is missing
//       debugPrint("⚠️ User not found OR email is null! Forcing logout...");
//       await forceLogout(context);
//       return false;
//     }

//     try {
//       DocumentSnapshot userDoc =
//           await _firestore.collection("users").doc(user.uid).get();

//       if (!userDoc.exists || userDoc.data() == null) {
//         debugPrint("⚠️ No user document found in Firestore! Logging out...");
//         await forceLogout(context);
//         return false;
//       }

//       // ✅ **Extract User Data Safely**
//       Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

//       bool hasRequiredFields =
//           userData.containsKey("fullName") &&
//           userData.containsKey("phoneNumber") &&
//           userData.containsKey("email");

//       // ✅ **Allow Partial Profiles: If some fields are missing, show Profile Screen**
//       if (hasRequiredFields) {
//         bool isComplete =
//             userData.containsKey("address") &&
//             userData.containsKey("city") &&
//             userData.containsKey("state") &&
//             userData.containsKey("pin");

//         await prefs.setBool("isProfileCompleted", isComplete);
//         debugPrint("🔍 Profile Completion Status: $isComplete");

//         return isComplete;
//       } else {
//         debugPrint(
//           "⚠️ Required user details (Name, Phone, Email) are missing!",
//         );
//         await forceLogout(context); // **Logout if critical fields are missing**
//         return false;
//       }
//     } catch (e) {
//       debugPrint("❌ Error checking profile completion: $e");
//       await forceLogout(context);
//       return false;
//     }
//   }

//   // ✅ **Force Logout & Navigate to Sign-In Page**
//   Future<void> forceLogout(BuildContext context) async {
//     try {
//       await _auth.signOut();

//       // ✅ Reset Local Profile Completion Status
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       await prefs.remove("isProfileCompleted");

//       debugPrint("✅ User successfully logged out.");

//       // ✅ Ensure UI updates before navigation
//       if (context.mounted) {
//         Future.delayed(const Duration(milliseconds: 300), () {
//           Navigator.pushAndRemoveUntil(
//             context,
//             MaterialPageRoute(builder: (context) => const SignInScreen()),
//             (route) => false, // Clears the navigation stack
//           );
//         });
//       }
//     } catch (e) {
//       debugPrint("❌ Error during logout: $e");
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
//         "isProfileComplete": false, // Default - profile needs completion
//       });

//       // ✅ Ensure Profile Completion is False for New Users
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       await prefs.setBool("isProfileCompleted", false);

//       debugPrint("✅ New user signed up & profile marked incomplete.");
//       return null;
//     } on FirebaseAuthException catch (e) {
//       debugPrint("❌ Error during sign-up: ${e.message}");
//       return e.message;
//     }
//   }

//   // ✅ **Log In with Email & Password**
//   Future<String?> logIn({
//     required String email,
//     required String password,
//     required BuildContext context,
//   }) async {
//     try {
//       await _auth.signInWithEmailAndPassword(email: email, password: password);

//       // ✅ Check Profile Completion on Login
//       bool isComplete = await isProfileComplete(context);
//       debugPrint("🔹 Profile Completion Status on Login: $isComplete");

//       return null;
//     } on FirebaseAuthException catch (e) {
//       debugPrint("❌ Error during login: ${e.message}");
//       return e.message;
//     }
//   }

//   // ✅ **Get Current User**
//   User? get currentUser => _auth.currentUser;
// }


