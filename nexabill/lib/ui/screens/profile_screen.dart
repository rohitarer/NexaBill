import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:nexabill/core/theme.dart';
import 'package:nexabill/data/state_data.dart';
import 'package:nexabill/ui/screens/home_screen.dart';
import 'package:nexabill/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController pinController = TextEditingController();

  String selectedState = "";
  String selectedGender = "Male";
  DateTime? selectedDate;
  File? _profileImage;

  bool _isLoading = true; // ✅ Loading State

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint("❌ No user found, redirecting...");
      return;
    }

    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (!userDoc.exists) {
        debugPrint("⚠️ User document does not exist!");
        return;
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      setState(() {
        nameController.text = userData["fullName"] ?? "";
        phoneController.text = userData["phoneNumber"] ?? "";
        emailController.text = user.email ?? "";
        selectedGender = userData["gender"] ?? "Male";
        addressController.text = userData["address"] ?? "";
        cityController.text = userData["city"] ?? "";
        selectedState = userData["state"] ?? "";
        pinController.text = userData["pin"] ?? "";
        selectedDate =
            userData["dob"] != null ? DateTime.tryParse(userData["dob"]) : null;
        _isLoading = false; // ✅ Done Loading
      });
    } catch (e) {
      debugPrint("❌ Error loading profile: $e");
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        "fullName": nameController.text.trim(),
        "phoneNumber": phoneController.text.trim(),
        "gender": selectedGender,
        "dob": selectedDate?.toIso8601String() ?? "",
        "address": addressController.text.trim(),
        "city": cityController.text.trim(),
        "state": selectedState,
        "pin": pinController.text.trim(),
        "profileCompleted": true, // ✅ Marks the profile as complete
      }, SetOptions(merge: true));

      // ✅ Navigate to Home Screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text("Complete Your Profile")),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(),
              ) // ✅ Show Loader
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Profile Image
                      GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage:
                              _profileImage != null
                                  ? FileImage(_profileImage!)
                                  : const AssetImage(
                                        "assets/profile_placeholder.png",
                                      )
                                      as ImageProvider,
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Name
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: "Full Name",
                        ),
                      ),

                      // Gender Selection
                      Row(
                        children: [
                          const Text("Gender:"),
                          Radio(
                            value: "Male",
                            groupValue: selectedGender,
                            onChanged: (value) {
                              setState(() => selectedGender = value!);
                            },
                          ),
                          const Text("Male"),
                          Radio(
                            value: "Female",
                            groupValue: selectedGender,
                            onChanged: (value) {
                              setState(() => selectedGender = value!);
                            },
                          ),
                          const Text("Female"),
                        ],
                      ),

                      // Date of Birth
                      TextFormField(
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: "Date of Birth",
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () => _selectDate(context),
                          ),
                        ),
                        controller: TextEditingController(
                          text:
                              selectedDate != null
                                  ? "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}"
                                  : "",
                        ),
                      ),

                      // Phone, Email (Disabled)
                      TextFormField(
                        controller: phoneController,
                        decoration: const InputDecoration(labelText: "Phone"),
                      ),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: "Email"),
                        enabled: false,
                      ),

                      // Address, City, State, Pin
                      TextFormField(
                        controller: addressController,
                        decoration: const InputDecoration(labelText: "Address"),
                      ),
                      TextFormField(
                        controller: cityController,
                        decoration: const InputDecoration(labelText: "City"),
                      ),
                      DropdownButtonFormField<String>(
                        value:
                            StateData.states.contains(selectedState)
                                ? selectedState
                                : null,
                        hint: const Text("Select State"),
                        onChanged: (String? newValue) {
                          setState(() => selectedState = newValue!);
                        },
                        items:
                            StateData.states
                                .map(
                                  (state) => DropdownMenuItem<String>(
                                    value: state,
                                    child: Text(state),
                                  ),
                                )
                                .toList(),
                      ),
                      TextFormField(
                        controller: pinController,
                        decoration: const InputDecoration(
                          labelText: "Pin Code",
                        ),
                      ),

                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _saveProfile,
                        child: const Text("Save"),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() => _profileImage = File(pickedFile.path));
    }
  }
}
