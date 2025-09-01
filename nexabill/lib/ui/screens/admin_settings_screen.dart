import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexabill/providers/cam_verification_provider.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() =>
      _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  bool isAdmin = false;
  bool isLoading = true;
  String? uid;

  @override
  void initState() {
    super.initState();
    _loadAdminStatus();
  }

  Future<void> _loadAdminStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    uid = user.uid;

    final snapshot =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = snapshot.data();
    if (data != null) {
      final role = data['role'] ?? 'customer';
      final camEnabled = data['camVerification'] ?? false;

      setState(() {
        isAdmin = role.toLowerCase() == 'admin';
        isLoading = false;
      });

      // Update Riverpod state
      ref.read(camVerificationProvider.notifier).state = camEnabled;
    }
  }

  Future<void> _updateCamVerification(bool value) async {
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'camVerification': value,
    });

    ref.read(camVerificationProvider.notifier).state = value;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? 'Camera Verification Enabled ✅'
              : 'Camera Verification Disabled ❌',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final camEnabled = ref.watch(camVerificationProvider);

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Admin Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isAdmin)
              SwitchListTile(
                title: const Text("Camera Verification"),
                value: camEnabled,
                onChanged: _updateCamVerification,
              )
            else
              const Center(
                child: Text("You do not have permission to access this page"),
              ),
          ],
        ),
      ),
    );
  }
}
