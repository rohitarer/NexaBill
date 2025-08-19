import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nexabill/ui/screens/profile_screen.dart';
import 'package:nexabill/ui/screens/mart_details_screen.dart';
import 'package:nexabill/ui/screens/bank_details_screen.dart';
import 'package:nexabill/ui/screens/admin_home_screen.dart';
import 'package:nexabill/ui/screens/cashier_home_screen.dart';
import 'package:nexabill/ui/screens/customer_home_screen.dart';
import 'package:nexabill/ui/screens/signin_screen.dart';

class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/mart-details':
        return MaterialPageRoute(builder: (_) => const MartDetailsScreen());
      case '/bank-details':
        return MaterialPageRoute(builder: (_) => const BankDetailsScreen());
      case '/profile':
        return MaterialPageRoute(builder: (_) => ProfileScreen());
      case '/admin-home':
        return MaterialPageRoute(builder: (_) => const AdminHomeScreen());
      case '/cashier-home':
        return MaterialPageRoute(builder: (_) => const CashierHomeScreen());
      case '/customer-home':
        return MaterialPageRoute(builder: (_) => const CustomerHomeScreen());
      case '/signin':
      default:
        return MaterialPageRoute(builder: (_) => const SignInScreen());
    }
  }

  static Widget getHomeScreen(String role, bool isProfileComplete) {
    final roleLower = role.toLowerCase();

    if (!isProfileComplete) {
      if (roleLower == "admin") {
        setLastRoute('/mart-details');
        debugPrint("🛠 Profile incomplete → MartDetailsScreen");
        return const MartDetailsScreen();
      } else {
        setLastRoute('/profile');
        debugPrint("🛠 Profile incomplete → ProfileScreen");
        return ProfileScreen();
      }
    }

    switch (roleLower) {
      case 'admin':
        setLastRoute('/admin-home');
        debugPrint("🚀 Home → AdminHomeScreen");
        return const AdminHomeScreen();
      case 'cashier':
        setLastRoute('/cashier-home');
        debugPrint("🚀 Home → CashierHomeScreen");
        return const CashierHomeScreen();
      default:
        setLastRoute('/customer-home');
        debugPrint("🚀 Home → CustomerHomeScreen");
        return const CustomerHomeScreen();
    }
  }

  static Widget? getScreenFromRoute(String? route) {
    debugPrint("🔎 Restoring screen from route: $route");
    switch (route) {
      case '/mart-details':
        return const MartDetailsScreen();
      case '/bank-details':
        return const BankDetailsScreen();
      case '/profile':
        return ProfileScreen();
      case '/admin-home':
        return const AdminHomeScreen();
      case '/cashier-home':
        return const CashierHomeScreen();
      case '/customer-home':
        return const CustomerHomeScreen();
      default:
        debugPrint("⚠️ Unknown or null route.");
        return null;
    }
  }

  static Future<void> setLastRoute(String route) async {
    final prefs = await SharedPreferences.getInstance();
    debugPrint("💾 Saving last_route: $route");
    await prefs.setString('last_route', route);
  }

  static Future<void> clearLastRoute() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_route');
    debugPrint("🧹 Cleared last_route");
  }

  static void navigateToHomeByRole(BuildContext context, String role) {
    Widget home;
    switch (role.toLowerCase()) {
      case 'admin':
        home = const AdminHomeScreen();
        break;
      case 'cashier':
        home = const CashierHomeScreen();
        break;
      default:
        home = const CustomerHomeScreen();
    }

    setLastRoute('/${role.toLowerCase()}-home');

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => home),
      (route) => false,
    );
  }
}
