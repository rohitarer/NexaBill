import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexabill/core/theme.dart';
import 'package:nexabill/providers/auth_provider.dart';
import 'package:nexabill/ui/screens/signin_screen.dart';
import 'package:nexabill/ui/widgets/custom_dropdown.dart';
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
  String? selectedRole; // ✅ Start with null so hintText is shown
  final List<String> roles = ["Customer", "Cashier", "Admin"];

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

    if (selectedRole == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Please select a role")));
      return;
    }

    final authNotifier = ref.read(authNotifierProvider.notifier);

    // ✅ Call `signUp` with error and success handlers
    authNotifier.signUp(
      fullName: fullName,
      role: selectedRole!,
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

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Role",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 5),
                  CustomDropdown(
                    value: roles.contains(selectedRole) ? selectedRole : null,
                    hintText: "Select your role",
                    items: roles,
                    onChanged: (newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedRole = newValue;
                        });
                      }
                    },
                    textColor: isDarkMode ? Colors.black : Colors.white,
                    hintColor: isDarkMode ? Colors.black54 : Colors.white70,
                    fillColor: isDarkMode ? Colors.white : Colors.black,
                    prefixIcon:
                        Icons
                            .supervisor_account_rounded, // 👥 Different icon from name
                    suffixIcon: Icons.arrow_drop_down,
                    iconColor:
                        isDarkMode
                            ? Colors.black54
                            : Colors.black54, // ✅ Matching your reference
                  ),
                ],
              ),
              const SizedBox(height: 15),

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
