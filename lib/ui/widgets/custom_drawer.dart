import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexabill/providers/auth_provider.dart';
import 'package:nexabill/ui/screens/cashier_dashboard_screen.dart';
import 'package:nexabill/ui/screens/payments_screen.dart';
import 'package:nexabill/ui/screens/signin_screen.dart';
import 'package:nexabill/ui/screens/customer_report_screen.dart';
import 'package:nexabill/ui/screens/admin_settings_screen.dart'; // ✅ Add this import

class CustomDrawer extends ConsumerWidget {
  final bool isCustomer;
  final bool isAdmin;

  const CustomDrawer({
    super.key,
    required this.isCustomer,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: theme.primaryColor),
            child: const Text(
              "NexaBill Menu",
              style: TextStyle(color: Colors.white, fontSize: 22),
            ),
          ),

          if (!isAdmin) ...[
            if (isCustomer)
              ListTile(
                leading: const Icon(Icons.payment),
                title: const Text("Payments"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PaymentsScreen()),
                  );
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.dashboard),
                title: const Text("Dashboard"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CashierDashboardScreen(),
                    ),
                  );
                },
              ),
          ],

          if (isAdmin) ...[
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text("Customer Reports"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CustomerReportScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Settings"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminSettingsScreen(),
                  ),
                );
              },
            ),
          ],

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text(
              "Logout",
              style: TextStyle(color: Colors.redAccent),
            ),
            onTap: () async {
              bool confirmLogout = await _showLogoutDialog(context);
              if (confirmLogout) {
                final navigator = Navigator.of(context);
                ref.read(authNotifierProvider.notifier).logOut(ref);
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const SignInScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Future<bool> _showLogoutDialog(BuildContext context) async {
    return await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text("Logout"),
                content: const Text("Are you sure you want to log out?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      "Logout",
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
        ) ??
        false;
  }
}




// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:nexabill/providers/auth_provider.dart';
// import 'package:nexabill/ui/screens/cashier_dashboard_screen.dart';
// import 'package:nexabill/ui/screens/payments_screen.dart';
// import 'package:nexabill/ui/screens/signin_screen.dart';

// class CustomDrawer extends ConsumerWidget {
//   final bool isCustomer;
//   final bool isAdmin;

//   const CustomDrawer({
//     super.key,
//     required this.isCustomer,
//     this.isAdmin = false,
//   });

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final theme = Theme.of(context);

//     return Drawer(
//       child: ListView(
//         padding: EdgeInsets.zero,
//         children: [
//           DrawerHeader(
//             decoration: BoxDecoration(color: theme.primaryColor),
//             child: const Text(
//               "NexaBill Menu",
//               style: TextStyle(color: Colors.white, fontSize: 22),
//             ),
//           ),

//           if (!isAdmin) ...[
//             if (isCustomer)
//               ListTile(
//                 leading: const Icon(Icons.payment),
//                 title: const Text("Payments"),
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (_) => const PaymentsScreen()),
//                   );
//                 },
//               )
//             else
//               ListTile(
//                 leading: const Icon(Icons.dashboard),
//                 title: const Text("Dashboard"),
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (_) => const CashierDashboardScreen(),
//                     ),
//                   );
//                 },
//               ),
//           ],

//           ListTile(
//             leading: const Icon(Icons.settings),
//             title: const Text("Settings"),
//             onTap: () {
//               // TODO: Navigate to settings
//             },
//           ),
//           ListTile(
//             leading: const Icon(Icons.logout, color: Colors.redAccent),
//             title: const Text(
//               "Logout",
//               style: TextStyle(color: Colors.redAccent),
//             ),
//             onTap: () async {
//               bool confirmLogout = await _showLogoutDialog(context);
//               if (confirmLogout) {
//                 final navigator = Navigator.of(context);
//                 ref.read(authNotifierProvider.notifier).logOut(ref);
//                 navigator.pushAndRemoveUntil(
//                   MaterialPageRoute(builder: (_) => const SignInScreen()),
//                   (route) => false,
//                 );
//               }
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   Future<bool> _showLogoutDialog(BuildContext context) async {
//     return await showDialog(
//           context: context,
//           builder:
//               (context) => AlertDialog(
//                 title: const Text("Logout"),
//                 content: const Text("Are you sure you want to log out?"),
//                 actions: [
//                   TextButton(
//                     onPressed: () => Navigator.pop(context, false),
//                     child: const Text("Cancel"),
//                   ),
//                   TextButton(
//                     onPressed: () => Navigator.pop(context, true),
//                     child: const Text(
//                       "Logout",
//                       style: TextStyle(color: Colors.redAccent),
//                     ),
//                   ),
//                 ],
//               ),
//         ) ??
//         false;
//   }
// }

