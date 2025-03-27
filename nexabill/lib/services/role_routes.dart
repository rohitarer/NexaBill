import 'package:flutter/material.dart';
import 'package:nexabill/ui/screens/adminHome_screen.dart';
import 'package:nexabill/ui/screens/cashierHome_screen.dart';
import 'package:nexabill/ui/screens/customerHome_screen.dart';
import 'package:nexabill/ui/screens/profile_screen.dart';

class RoleRoutes {
  static Widget getHomeScreen(String role, bool isProfileComplete) {
    if (!isProfileComplete) {
      return ProfileScreen();
    }

    switch (role.toLowerCase()) {
      case 'admin':
        return AdminHomeScreen();
      case 'cashier':
        return CashierHomeScreen();
      case 'customer':
        return CustomerHomeScreen();
      default:
        return CustomerHomeScreen(); // Default fallback
    }
  }
}
