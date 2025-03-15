import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nexabill/core/theme.dart';
import 'package:nexabill/services/auth_service.dart';
import 'package:nexabill/ui/screens/home_screen.dart';
import 'package:nexabill/ui/screens/martsSelection_screen.dart';
import 'package:nexabill/ui/screens/profile_screen.dart';
import 'package:nexabill/ui/screens/signup_screen.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/custom_button.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isPasswordVisible = false;
  bool isLoading = false;

  // Future<void> _signIn() async {
  //   if (!_formKey.currentState!.validate()) return;

  //   setState(() => isLoading = true);

  //   try {
  //     await FirebaseAuth.instance.signInWithEmailAndPassword(
  //       email: emailController.text.trim(),
  //       password: passwordController.text.trim(),
  //     );
  //     debugPrint("✅ User Signed In: ${emailController.text}");

  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: const Text("Login Successful!"),
  //         backgroundColor: Theme.of(context).colorScheme.primary,
  //       ),
  //     );

  //     // Navigate to Mart Selection Page after successful login
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(builder: (context) => const MartSelectionScreen()),
  //     );
  //   } on FirebaseAuthException catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text("❌ Error: ${e.message}"),
  //         backgroundColor: Theme.of(context).colorScheme.error,
  //       ),
  //     );
  //   }

  //   setState(() => isLoading = false);
  // }
  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      // ✅ Attempt Sign In
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      debugPrint("✅ User Signed In: ${emailController.text}");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Login Successful!"),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );

      bool isProfileComplete = await AuthService().isProfileComplete(context);

      // ✅ Navigate to HomeScreen if profile is complete, otherwise ProfileScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  isProfileComplete
                      ? const HomeScreen()
                      : const ProfileScreen(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      // ❌ Error Handling
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Error: ${e.message}"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Dynamic Colors for Light & Dark Modes
    final textColor = isDarkMode ? AppTheme.whiteColor : AppTheme.textColor;
    final labelColor = isDarkMode ? Colors.white70 : Colors.black87;
    final hintColor = isDarkMode ? Colors.white54 : Colors.grey;
    final iconColor = isDarkMode ? Colors.white : Colors.black54;
    final inputFillColor = isDarkMode ? AppTheme.darkGrey : AppTheme.lightGrey;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Sign In"),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: AppTheme.whiteColor,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Text(
                //   "Sign In",
                //   style: theme.textTheme.headlineSmall?.copyWith(
                //     fontWeight: FontWeight.bold,
                //     color: textColor,
                //   ),
                // ),
                // const SizedBox(height: 30),

                // Email Field
                CustomTextField(
                  label: "Email",
                  hintText: "Enter your email",
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email,
                  prefixIconColor: iconColor,
                  textColor: textColor,
                  labelColor: labelColor,
                  hintColor: hintColor,
                  fillColor: inputFillColor,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Email is required";
                    }
                    if (!RegExp(
                      r'^[a-zA-Z0-9+_.-]+@[a-zA-Z0-9.-]+$',
                    ).hasMatch(value)) {
                      return "Enter a valid email";
                    }
                    return null;
                  },
                ),

                // Password Field
                CustomTextField(
                  label: "Password",
                  hintText: "Enter your password",
                  controller: passwordController,
                  isPassword: !isPasswordVisible,
                  prefixIcon: Icons.lock,
                  suffixIcon:
                      isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                  prefixIconColor: iconColor,
                  suffixIconColor: iconColor,
                  textColor: textColor,
                  labelColor: labelColor,
                  hintColor: hintColor,
                  fillColor: inputFillColor,
                  onSuffixIconTap: () {
                    setState(() => isPasswordVisible = !isPasswordVisible);
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Password is required";
                    }
                    if (value.length < 6) {
                      return "Password must be at least 6 characters";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 10),

                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // TODO: Implement Forgot Password logic
                    },
                    child: Text(
                      "Forgot Password?",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color:
                            isDarkMode
                                ? Colors.blueAccent
                                : Colors.blue, // Adjust color dynamically
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Sign In Button
                CustomButton(
                  text: isLoading ? "Signing In..." : "Sign In",
                  isLoading: isLoading,
                  onPressed: isLoading ? () {} : _signIn,
                ),

                const SizedBox(height: 15),

                // Sign Up Navigation
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account?",
                      style: TextStyle(color: textColor),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignUpScreen(),
                          ),
                        );
                      },
                      child: Text(
                        "Sign up",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.blueAccent : Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
