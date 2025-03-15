import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nexabill/ui/screens/home_screen.dart';
import 'package:nexabill/ui/screens/signin_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream:
          FirebaseAuth.instance.authStateChanges(), // Listen for auth changes
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          ); // Loading state
        } else if (snapshot.hasData) {
          return const HomeScreen(); // If user is logged in, go to HomeScreen
        } else {
          return const SignInScreen(); // If not logged in, go to SignInScreen
        }
      },
    );
  }
}
