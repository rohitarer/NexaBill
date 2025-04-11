import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexabill/core/theme.dart';
import 'package:nexabill/ui/screens/payments_screen.dart';
import 'package:nexabill/ui/screens/bill_verification_screen.dart';
import 'package:nexabill/ui/widgets/custom_bottom_navbar.dart';
import 'package:nexabill/ui/widgets/custom_drawer.dart';
import 'package:nexabill/providers/customer_home_provider.dart';
import 'package:nexabill/ui/screens/profile_screen.dart';

class CashierHomeScreen extends ConsumerStatefulWidget {
  const CashierHomeScreen({super.key});

  @override
  ConsumerState<CashierHomeScreen> createState() => _CashierHomeScreenState();
}

class _CashierHomeScreenState extends ConsumerState<CashierHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [BillVerificationScreen(), PaymentsScreen()];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final profileImage = ref.watch(profileImageProvider);
    double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    bool isKeyboardOpen = keyboardHeight > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0 ? "NexaBill - Cashier" : "Payment History",
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: AppTheme.whiteColor,
        elevation: 2,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(fromHome: true),
                  ),
                );
              },
              child: CircleAvatar(
                radius: 22,
                backgroundColor:
                    isDarkMode ? Colors.white24 : Colors.grey.shade300,
                child: profileImage.when(
                  data:
                      (imageData) =>
                          imageData != null
                              ? ClipOval(
                                child: Image.memory(
                                  imageData,
                                  fit: BoxFit.cover,
                                  width: 44,
                                  height: 44,
                                ),
                              )
                              : Icon(
                                Icons.person,
                                color: isDarkMode ? Colors.white : Colors.black,
                                size: 28,
                              ),
                  loading:
                      () => const CircularProgressIndicator(strokeWidth: 2),
                  error:
                      (_, __) =>
                          const Icon(Icons.error, color: Colors.red, size: 28),
                ),
              ),
            ),
          ),
        ],
      ),

      drawer: const CustomDrawer(),

      body: _screens[_selectedIndex],

      bottomNavigationBar:
          isKeyboardOpen
              ? null
              : CustomBottomNavBar(
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
                items: [
                  CustomBottomNavBarItem(
                    icon: Icons.receipt_long,
                    label: "Bill Verification",
                  ),
                  CustomBottomNavBarItem(
                    icon: Icons.payment,
                    label: "Payments",
                  ),
                ],
              ),
    );
  }
}
