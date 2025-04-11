import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexabill/core/theme.dart';
import 'package:nexabill/ui/screens/admin_dashboard_screen.dart';
import 'package:nexabill/ui/screens/admin_products_screen.dart';
import 'package:nexabill/ui/screens/admin_profile_tabs_screen.dart';
import 'package:nexabill/ui/widgets/add_product_sheet.dart';
import 'package:nexabill/ui/widgets/custom_bottom_navbar.dart';
import 'package:nexabill/ui/widgets/custom_drawer.dart';
import 'package:nexabill/providers/customer_home_provider.dart';

class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [AdminDashboardScreen(), AdminProductsScreen()];

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
          _selectedIndex == 0 ? "NexaBill - Admin" : "Products List",
          style: const TextStyle(
            // Prevents text interpolation issues
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            inherit: false,
          ),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: AppTheme.whiteColor,
        elevation: 2,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
        actions: [
          if (_selectedIndex == 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminProfileTabsScreen(),
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
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
                                  size: 28,
                                ),
                    loading:
                        () => const CircularProgressIndicator(strokeWidth: 2),
                    error:
                        (_, __) => const Icon(
                          Icons.error,
                          color: Colors.red,
                          size: 28,
                        ),
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ElevatedButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    builder: (_) => const AddProductSheet(),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 3,
                  textStyle: const TextStyle(
                    // Ensures consistent style
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    inherit: false,
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text(
                  "Add Product",
                  style: TextStyle(
                    inherit: false,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
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
                    icon: Icons.dashboard,
                    label: "Dashboard",
                  ),
                  CustomBottomNavBarItem(
                    icon: Icons.inventory_2,
                    label: "Products",
                  ),
                ],
              ),
    );
  }
}
