import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexabill/core/theme.dart';
import 'package:nexabill/providers/profile_provider.dart';
import 'package:nexabill/services/role_routes.dart';
import 'package:nexabill/ui/screens/bank_details_screen.dart';
import 'package:nexabill/ui/screens/mart_details_screen.dart';
import 'package:nexabill/ui/screens/profile_screen.dart';
import 'package:nexabill/ui/widgets/custom_bottom_navbar.dart';

class AdminProfileTabsScreen extends ConsumerStatefulWidget {
  const AdminProfileTabsScreen({super.key});

  @override
  ConsumerState<AdminProfileTabsScreen> createState() =>
      _AdminProfileTabsScreenState();
}

class _AdminProfileTabsScreenState
    extends ConsumerState<AdminProfileTabsScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    ProfileScreen(fromHome: true, isInsideTabs: true),
    MartDetailsScreen(isInsideTabs: true),
    BankDetailsScreen(isInsideTabs: true),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileNotifier = ref.read(profileNotifierProvider.notifier);
    final profileState = ref.watch(profileNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0
              ? "Profile"
              : _selectedIndex == 1
              ? "Mart Details"
              : "Bank Details",
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: AppTheme.whiteColor,
        elevation: 2,
        actions: [
          TextButton(
            onPressed:
                profileState.isLoading
                    ? null
                    : () async {
                      await profileNotifier.saveProfile(context, ref);

                      if (context.mounted && profileState.role.isNotEmpty) {
                        AppRoutes.navigateToHomeByRole(
                          context,
                          profileState.role,
                        );
                      }
                    },
            child:
                profileState.isLoading
                    ? const Padding(
                      padding: EdgeInsets.only(right: 16),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      ),
                    )
                    : const Padding(
                      padding: EdgeInsets.only(right: 16),
                      child: Text(
                        "Save",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          CustomBottomNavBarItem(icon: Icons.person, label: "Profile"),
          CustomBottomNavBarItem(icon: Icons.store, label: "Mart"),
          CustomBottomNavBarItem(icon: Icons.account_balance, label: "Bank"),
        ],
      ),
    );
  }
}
