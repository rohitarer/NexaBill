import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexabill/core/theme.dart';
import 'package:nexabill/providers/auth_provider.dart';
import 'package:nexabill/ui/screens/signin_screen.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  // final _formKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _signUpFormKey = GlobalKey<FormState>();

  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

  void _handleSignUp() {
    // if (!_formKey.currentState!.validate()) return;
    if (!_signUpFormKey.currentState!.validate()) return;

    final fullName = nameController.text.trim();
    final phoneNumber = phoneController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Passwords do not match"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final authNotifier = ref.read(authNotifierProvider.notifier);

    // ✅ Call `signUp` with error and success handlers
    authNotifier.signUp(
      fullName: fullName,
      phoneNumber: phoneNumber,
      email: email,
      password: password,
      onSuccess: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account created successfully!")),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SignInScreen()),
        );
      },
      onError: (errorMessage) {
        if (errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppTheme.darkGrey : AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("Sign Up"),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: AppTheme.whiteColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Form(
          // key: _formKey,
          key: _signUpFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Create an Account",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? AppTheme.whiteColor : AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 20),

              // ✅ Name Field
              CustomTextField(
                label: "Full Name",
                hintText: "Enter your full name",
                controller: nameController,
                prefixIcon: Icons.person,
                labelColor:
                    isDarkMode
                        ? AppTheme.whiteColor
                        : AppTheme.textColor, // ✅ Label color based on theme
              ),

              // ✅ Phone Number Field
              CustomTextField(
                label: "Phone Number",
                hintText: "Enter your phone number",
                controller: phoneController,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone,
                labelColor:
                    isDarkMode
                        ? AppTheme.whiteColor
                        : AppTheme.textColor, // ✅ Label color based on theme
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Phone number is required";
                  }
                  if (!RegExp(r"^\d{10}$").hasMatch(value)) {
                    return "Enter a valid 10-digit phone number";
                  }
                  return null;
                },
              ),

              // ✅ Email Field
              CustomTextField(
                label: "Email",
                hintText: "Enter your email",
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email,
                labelColor:
                    isDarkMode
                        ? AppTheme.whiteColor
                        : AppTheme.textColor, // ✅ Label color based on theme
              ),

              // ✅ Password Field
              CustomTextField(
                label: "Password",
                hintText: "Enter your password",
                controller: passwordController,
                isPassword: !isPasswordVisible,
                prefixIcon: Icons.lock,
                suffixIcon:
                    isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                labelColor:
                    isDarkMode
                        ? AppTheme.whiteColor
                        : AppTheme.textColor, // ✅ Label color based on theme
                onSuffixIconTap: () {
                  setState(() => isPasswordVisible = !isPasswordVisible);
                },
              ),

              // ✅ Confirm Password Field
              CustomTextField(
                label: "Confirm Password",
                hintText: "Re-enter your password",
                controller: confirmPasswordController,
                isPassword: !isConfirmPasswordVisible,
                prefixIcon: Icons.lock,
                suffixIcon:
                    isConfirmPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                labelColor:
                    isDarkMode
                        ? AppTheme.whiteColor
                        : AppTheme.textColor, // ✅ Label color based on theme
                onSuffixIconTap: () {
                  setState(
                    () => isConfirmPasswordVisible = !isConfirmPasswordVisible,
                  );
                },
              ),

              const SizedBox(height: 20),

              // ✅ Sign Up Button
              CustomButton(
                text: authState.isLoading ? "Signing Up..." : "Sign Up",
                isLoading: authState.isLoading,
                onPressed: authState.isLoading ? () {} : _handleSignUp,
              ),

              const SizedBox(height: 15),

              // ✅ Already have an account? Log In
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account?"),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignInScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "Log In",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:nexabill/core/theme.dart';
// import 'package:nexabill/services/auth_service.dart';
// import 'package:nexabill/ui/screens/signin_screen.dart';
// import '../widgets/custom_button.dart';
// import '../widgets/custom_textfield.dart';

// class SignUpScreen extends StatefulWidget {
//   const SignUpScreen({super.key});

//   @override
//   _SignUpScreenState createState() => _SignUpScreenState();
// }

// class _SignUpScreenState extends State<SignUpScreen> {
//   final TextEditingController nameController = TextEditingController();
//   final TextEditingController phoneController =
//       TextEditingController(); // ✅ Added Phone Number
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();
//   final TextEditingController confirmPasswordController =
//       TextEditingController();

//   final _formKey = GlobalKey<FormState>();
//   bool isLoading = false;
//   bool isPasswordVisible = false;
//   bool isConfirmPasswordVisible = false;

//   Future<void> _handleSignUp() async {
//     if (!_formKey.currentState!.validate()) return;

//     final fullName = nameController.text.trim();
//     final phoneNumber = phoneController.text.trim(); // ✅ Capture Phone Number
//     final email = emailController.text.trim();
//     final password = passwordController.text.trim();
//     final confirmPassword = confirmPasswordController.text.trim();

//     if (password != confirmPassword) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: const Text("Passwords do not match"),
//           backgroundColor: Theme.of(context).colorScheme.error,
//         ),
//       );
//       return;
//     }

//     setState(() => isLoading = true);

//     final errorMessage = await AuthService().signUp(
//       fullName: fullName,
//       phoneNumber: phoneNumber,
//       email: email,
//       password: password,
//     );

//     setState(() => isLoading = false);

//     // if (errorMessage == null) {
//     //   debugPrint("✅ User Signed Up:");
//     //   debugPrint("Name: $name");
//     //   debugPrint("Phone: $phone"); // ✅ Log Phone Number
//     //   debugPrint("Email: $email");

//     //   ScaffoldMessenger.of(context).showSnackBar(
//     //     const SnackBar(content: Text("Account created successfully!")),
//     //   );

//     //   Navigator.pushReplacement(
//     //     context,
//     //     MaterialPageRoute(builder: (context) => const SignInScreen()),
//     //   );
//     // }
//     if (errorMessage == null) {
//       debugPrint("✅ User Signed Up:");
//       debugPrint("Name: $fullName");
//       debugPrint("Email: $email");
//       debugPrint("Phone: $phoneNumber");
//       debugPrint("Password: $password");
//       debugPrint("Confirm Password: $confirmPassword");

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Account created successfully!")),
//       );

//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (context) => const SignInScreen(),
//         ), // ✅ Redirect to Profile
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(errorMessage),
//           backgroundColor: Theme.of(context).colorScheme.error,
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final isDarkMode = theme.brightness == Brightness.dark;

//     // Dynamic Colors for Light & Dark Modes
//     final textColor = isDarkMode ? AppTheme.whiteColor : AppTheme.textColor;
//     final labelColor = isDarkMode ? Colors.white70 : Colors.black87;
//     final hintColor = isDarkMode ? Colors.white54 : Colors.grey;
//     final iconColor = isDarkMode ? Colors.white : Colors.black87;
//     final inputFieldColor =
//         isDarkMode ? AppTheme.textColor : AppTheme.lightGrey;
//     final backgroundColor =
//         isDarkMode ? AppTheme.darkGrey : AppTheme.backgroundColor;

//     return Scaffold(
//       backgroundColor: backgroundColor,
//       appBar: AppBar(
//         title: const Text("Sign Up"),
//         centerTitle: true,
//         backgroundColor: theme.appBarTheme.backgroundColor,
//         foregroundColor: AppTheme.whiteColor,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 "Create an Account",
//                 style: theme.textTheme.headlineSmall?.copyWith(
//                   fontWeight: FontWeight.bold,
//                   color: textColor, // Dark in light mode, White in dark mode
//                 ),
//               ),
//               const SizedBox(height: 20),

//               // ✅ Name Field
//               CustomTextField(
//                 label: "Full Name",
//                 hintText: "Enter your full name",
//                 controller: nameController,
//                 keyboardType: TextInputType.name,
//                 prefixIcon: Icons.person,
//                 prefixIconColor: iconColor,
//                 textColor: textColor,
//                 labelColor: labelColor,
//                 hintColor: hintColor,
//                 fillColor: inputFieldColor,
//                 validator: (value) {
//                   if (value == null || value.trim().isEmpty) {
//                     return "Full name is required";
//                   }
//                   return null;
//                 },
//               ),

//               // ✅ Phone Number Field
//               CustomTextField(
//                 label: "Phone Number",
//                 hintText: "Enter your phone number",
//                 controller: phoneController,
//                 keyboardType: TextInputType.phone,
//                 prefixIcon: Icons.phone,
//                 prefixIconColor: iconColor,
//                 textColor: textColor,
//                 labelColor: labelColor,
//                 hintColor: hintColor,
//                 fillColor: inputFieldColor,
//                 validator: (value) {
//                   if (value == null || value.trim().isEmpty) {
//                     return "Phone number is required";
//                   }
//                   if (!RegExp(r"^\d{10}$").hasMatch(value)) {
//                     return "Enter a valid 10-digit phone number";
//                   }
//                   return null;
//                 },
//               ),

//               // ✅ Email Field
//               CustomTextField(
//                 label: "Email",
//                 hintText: "Enter your email",
//                 controller: emailController,
//                 keyboardType: TextInputType.emailAddress,
//                 prefixIcon: Icons.email,
//                 prefixIconColor: iconColor,
//                 textColor: textColor,
//                 labelColor: labelColor,
//                 hintColor: hintColor,
//                 fillColor: inputFieldColor,
//                 validator: (value) {
//                   if (value == null || value.trim().isEmpty) {
//                     return "Email is required";
//                   }
//                   if (!RegExp(
//                     r"^[a-zA-Z0-9+_.-]+@[a-zA-Z0-9.-]+$",
//                   ).hasMatch(value)) {
//                     return "Enter a valid email";
//                   }
//                   return null;
//                 },
//               ),

//               // ✅ Password Field
//               CustomTextField(
//                 label: "Password",
//                 hintText: "Enter your password",
//                 controller: passwordController,
//                 isPassword: !isPasswordVisible,
//                 prefixIcon: Icons.lock,
//                 suffixIcon:
//                     isPasswordVisible ? Icons.visibility : Icons.visibility_off,
//                 prefixIconColor: iconColor,
//                 textColor: textColor,
//                 labelColor: labelColor,
//                 hintColor: hintColor,
//                 fillColor: inputFieldColor,
//                 onSuffixIconTap: () {
//                   setState(() => isPasswordVisible = !isPasswordVisible);
//                 },
//                 validator: (value) {
//                   if (value == null || value.trim().isEmpty) {
//                     return "Password is required";
//                   }
//                   if (value.length < 6) {
//                     return "Password must be at least 6 characters";
//                   }
//                   return null;
//                 },
//               ),

//               // ✅ Confirm Password Field
//               CustomTextField(
//                 label: "Confirm Password",
//                 hintText: "Re-enter your password",
//                 controller: confirmPasswordController,
//                 isPassword: !isConfirmPasswordVisible,
//                 prefixIcon: Icons.lock,
//                 suffixIcon:
//                     isConfirmPasswordVisible
//                         ? Icons.visibility
//                         : Icons.visibility_off,
//                 prefixIconColor: iconColor,
//                 textColor: textColor,
//                 labelColor: labelColor,
//                 hintColor: hintColor,
//                 fillColor: inputFieldColor,
//                 onSuffixIconTap: () {
//                   setState(
//                     () => isConfirmPasswordVisible = !isConfirmPasswordVisible,
//                   );
//                 },
//                 validator: (value) {
//                   if (value == null || value.trim().isEmpty) {
//                     return "Please confirm your password";
//                   }
//                   return null;
//                 },
//               ),

//               const SizedBox(height: 20),

//               // ✅ Sign Up Button
//               CustomButton(
//                 text: isLoading ? "Signing Up..." : "Sign Up",
//                 isLoading: isLoading,
//                 onPressed: isLoading ? () {} : _handleSignUp,
//               ),

//               const SizedBox(height: 15),

//               // ✅ Already have an account? Log In
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text(
//                     "Already have an account?",
//                     style: TextStyle(color: textColor),
//                   ),
//                   TextButton(
//                     onPressed: () {
//                       Navigator.pushReplacement(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => const SignInScreen(),
//                         ),
//                       );
//                     },
//                     child: Text(
//                       "Log In",
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: isDarkMode ? Colors.blueAccent : Colors.blue,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
