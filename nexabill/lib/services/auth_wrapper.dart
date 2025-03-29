// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:nexabill/services/role_routes.dart';
// import 'package:nexabill/ui/screens/customerHome_screen.dart';
// import 'package:nexabill/ui/screens/signin_screen.dart';

// class AuthWrapper extends StatelessWidget {
//   const AuthWrapper({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<User?>(
//       stream:
//           FirebaseAuth.instance.authStateChanges(), // Listen for auth changes
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(
//             child: CircularProgressIndicator(),
//           ); // Loading state
//         } else if (snapshot.hasData) {
//           return RoleRoutes.getHomeScreen(
//             role,
//             isComplete,
//           ); // If user is logged in, go to HomeScreen
//         } else {
//           return const SignInScreen(); // If not logged in, go to SignInScreen
//         }
//       },
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nexabill/services/role_routes.dart';
import 'package:nexabill/ui/screens/signin_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<Map<String, dynamic>> fetchUserProfile(String uid) async {
    final snapshot =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (snapshot.exists) {
      return snapshot.data()!;
    } else {
      throw Exception("User profile not found");
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 🔄 While checking auth status
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 🔐 If user is not logged in
        if (!snapshot.hasData || snapshot.data == null) {
          return const SignInScreen();
        }

        // ✅ User is logged in → now fetch profile
        final user = snapshot.data!;
        return FutureBuilder<Map<String, dynamic>>(
          future: fetchUserProfile(user.uid),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (profileSnapshot.hasError || !profileSnapshot.hasData) {
              return const SignInScreen(); // fallback in case of error
            }

            final profileData = profileSnapshot.data!;
            final role = profileData['role'] ?? 'Customer';
            final isComplete = profileData['isProfileComplete'] ?? false;

            return AppRoutes.getHomeScreen(role, isComplete);
          },
        );
      },
    );
  }
}
