import 'package:flutter/material.dart';
import 'package:medicare/screens/login.dart';
import 'package:medicare/screens/shared/splash_page.dart';
import 'package:medicare/services/firebase_service.dart';
import 'package:medicare/themes/app_theme.dart'; // Import your new theme file

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await firebaseInitialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medicare',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const SplashPage(),
    );
  }
}
