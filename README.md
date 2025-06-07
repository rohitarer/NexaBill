# nexabill

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


NexaBill/
├── lib/
│   ├── main.dart                # Entry point
│   ├── core/                    # Global utilities & constants
│   │   ├── theme.dart           # App theme colors
│   │   ├── app_routes.dart      # Navigation routes
│   │   ├── constants.dart       # App-wide constants
│   ├── ui/                      # UI components
│   │   ├── screens/             # App Screens
│   │   │   ├── home_screen.dart
│   │   │   ├── billing_screen.dart
│   │   │   ├── fraud_detection_screen.dart
│   │   ├── widgets/             # Reusable UI components
│   ├── services/                # Business Logic
│   │   ├── firebase_auth.dart   # Firebase Authentication
│   │   ├── qr_scanner.dart      # QR Scanner Logic
│   │   ├── speech_to_text.dart  # Voice Recognition Logic
│   ├── models/                  # Data Models
│   ├── providers/               # State Management (if using Provider)
│   ├── pubspec.yaml             # Dependencies
│   ├── README.md                # Documentation
