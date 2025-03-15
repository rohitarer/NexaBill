import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nexabill/services/auth_service.dart';
import 'package:nexabill/ui/screens/home_screen.dart';
import 'package:nexabill/ui/screens/signin_screen.dart';
import 'package:nexabill/ui/screens/profile_screen.dart';
import 'package:nexabill/core/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const NexaBillApp());
}

class NexaBillApp extends StatefulWidget {
  const NexaBillApp({super.key});

  @override
  _NexaBillAppState createState() => _NexaBillAppState();
}

class _NexaBillAppState extends State<NexaBillApp> {
  bool _isLoading = true;
  User? _user;
  bool _isProfileComplete = false;

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  /// ✅ **Check User Authentication & Profile Status**
  Future<void> _checkUserStatus() async {
    setState(() => _isLoading = true);

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint("🔹 No user found. Redirecting to Sign-In.");
      setState(() {
        _user = null;
        _isProfileComplete = false;
        _isLoading = false;
      });
      return;
    }

    bool isProfileComplete = await AuthService().isProfileComplete(context);
    debugPrint("🔍 Profile Completion Status: $isProfileComplete");

    setState(() {
      _user = user;
      _isProfileComplete = isProfileComplete;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home:
          _isLoading
              ? const Scaffold(body: Center(child: CircularProgressIndicator()))
              : _user == null
              ? const SignInScreen() // ✅ Redirect to Sign-In if No User
              : _isProfileComplete
              ? const HomeScreen() // ✅ Redirect to Home if Profile is Complete
              : const ProfileScreen(), // ✅ Show Profile Completion Screen
    );
  }
}



// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:nexabill/services/auth_service.dart';
// import 'package:nexabill/ui/screens/home_screen.dart';
// import 'package:nexabill/ui/screens/signin_screen.dart';
// import 'package:nexabill/ui/screens/profile_screen.dart';
// import 'package:nexabill/core/theme.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp();

//   runApp(const NexaBillApp());
// }

// class NexaBillApp extends StatefulWidget {
//   const NexaBillApp({super.key});

//   @override
//   _NexaBillAppState createState() => _NexaBillAppState();
// }

// class _NexaBillAppState extends State<NexaBillApp> {
//   late Future<User?> userCheckFuture;

//   @override
//   void initState() {
//     super.initState();
//     userCheckFuture = _checkUserStatus();
//   }

//   // ✅ **Check User Authentication & Profile Status**
//   Future<User?> _checkUserStatus() async {
//     User? user = FirebaseAuth.instance.currentUser;

//     if (user == null) {
//       debugPrint("🔹 No user found. Redirecting to Sign-In.");
//       return null; // 🔹 Redirects to Sign-In
//     }

//     bool isProfileComplete = await AuthService().isProfileComplete(context);
//     debugPrint("🔍 Profile Completion Status: $isProfileComplete");

//     return user;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       theme: AppTheme.lightTheme,
//       darkTheme: AppTheme.darkTheme,
//       themeMode: ThemeMode.system,
//       debugShowCheckedModeBanner: false,
//       home: FutureBuilder<User?>(
//         future: userCheckFuture,
//         builder: (context, snapshot) {
//           // 🔹 **Show Loading Until Firebase & Profile Check is Done**
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Scaffold(
//               body: Center(child: CircularProgressIndicator()),
//             );
//           }

//           // 🔹 **Handle Errors Gracefully**
//           if (snapshot.hasError) {
//             debugPrint("❌ Error in authentication check: ${snapshot.error}");
//             return const SignInScreen();
//           }

//           // 🔹 **Get Auth & Profile Status**
//           User? user = snapshot.data;

//           // 🔹 **Redirect Based on Auth & Profile Completion**
//           if (user == null) {
//             return const SignInScreen(); // ✅ Show Sign-In Page
//           } else {
//             return FutureBuilder<bool>(
//               future: AuthService().isProfileComplete(context),
//               builder: (context, profileSnapshot) {
//                 if (profileSnapshot.connectionState ==
//                     ConnectionState.waiting) {
//                   return const Scaffold(
//                     body: Center(child: CircularProgressIndicator()),
//                   );
//                 }

//                 if (profileSnapshot.hasError || profileSnapshot.data == false) {
//                   debugPrint("🔹 Redirecting to Profile Completion");
//                   return const ProfileScreen(); // ✅ Ask User to Complete Profile
//                 }

//                 debugPrint("🏠 Redirecting to Home");
//                 return const HomeScreen(); // ✅ Go to Home if Profile is Complete
//               },
//             );
//           }
//         },
//       ),
//     );
//   }
// }


// import 'package:flutter/material.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Demo',
//       theme: ThemeData(
//         // This is the theme of your application.
//         //
//         // TRY THIS: Try running your application with "flutter run". You'll see
//         // the application has a purple toolbar. Then, without quitting the app,
//         // try changing the seedColor in the colorScheme below to Colors.green
//         // and then invoke "hot reload" (save your changes or press the "hot
//         // reload" button in a Flutter-supported IDE, or press "r" if you used
//         // the command line to start the app).
//         //
//         // Notice that the counter didn't reset back to zero; the application
//         // state is not lost during the reload. To reset the state, use hot
//         // restart instead.
//         //
//         // This works for code too, not just values: Most code changes can be
//         // tested with just a hot reload.
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//       ),
//       home: const MyHomePage(title: 'Flutter Demo Home Page'),
//     );
//   }
// }

// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key, required this.title});

//   // This widget is the home page of your application. It is stateful, meaning
//   // that it has a State object (defined below) that contains fields that affect
//   // how it looks.

//   // This class is the configuration for the state. It holds the values (in this
//   // case the title) provided by the parent (in this case the App widget) and
//   // used by the build method of the State. Fields in a Widget subclass are
//   // always marked "final".

//   final String title;

//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   int _counter = 0;

//   void _incrementCounter() {
//     setState(() {
//       // This call to setState tells the Flutter framework that something has
//       // changed in this State, which causes it to rerun the build method below
//       // so that the display can reflect the updated values. If we changed
//       // _counter without calling setState(), then the build method would not be
//       // called again, and so nothing would appear to happen.
//       _counter++;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     // This method is rerun every time setState is called, for instance as done
//     // by the _incrementCounter method above.
//     //
//     // The Flutter framework has been optimized to make rerunning build methods
//     // fast, so that you can just rebuild anything that needs updating rather
//     // than having to individually change instances of widgets.
//     return Scaffold(
//       appBar: AppBar(
//         // TRY THIS: Try changing the color here to a specific color (to
//         // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
//         // change color while the other colors stay the same.
//         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
//         // Here we take the value from the MyHomePage object that was created by
//         // the App.build method, and use it to set our appbar title.
//         title: Text(widget.title),
//       ),
//       body: Center(
//         // Center is a layout widget. It takes a single child and positions it
//         // in the middle of the parent.
//         child: Column(
//           // Column is also a layout widget. It takes a list of children and
//           // arranges them vertically. By default, it sizes itself to fit its
//           // children horizontally, and tries to be as tall as its parent.
//           //
//           // Column has various properties to control how it sizes itself and
//           // how it positions its children. Here we use mainAxisAlignment to
//           // center the children vertically; the main axis here is the vertical
//           // axis because Columns are vertical (the cross axis would be
//           // horizontal).
//           //
//           // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
//           // action in the IDE, or press "p" in the console), to see the
//           // wireframe for each widget.
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             const Text('You have pushed the button this many times:'),
//             Text(
//               '$_counter',
//               style: Theme.of(context).textTheme.headlineMedium,
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _incrementCounter,
//         tooltip: 'Increment',
//         child: const Icon(Icons.add),
//       ), // This trailing comma makes auto-formatting nicer for build methods.
//     );
//   }
// }
