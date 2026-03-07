import 'package:flutter/material.dart';
import 'package:medicare/screens/login.dart';
import 'package:medicare/services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await firebaseInitialize();
  // Run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: AuthGate(), // Show the login page
    );
  }
}
