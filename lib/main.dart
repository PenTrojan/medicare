import 'package:flutter/material.dart';
import 'package:medicare/screens/shared/splash_page.dart';
import 'package:medicare/services/firebase_service.dart';
import 'package:medicare/themes/app_theme.dart';

// 1. Create a global messenger key
final GlobalKey<ScaffoldMessengerState> messengerKey =
    GlobalKey<ScaffoldMessengerState>();

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
      // 2. Assign the key here
      scaffoldMessengerKey: messengerKey,
      title: 'Medicare',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const SplashPage(),
      // 3. Intercept navigation or build sequences to instantly clear snacks if they try to show
      builder: (context, child) {
        // This listens globally and forces any triggered snackbar to instantly clear before rendering a frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          messengerKey.currentState?.clearSnackBars();
        });
        return child ?? const SizedBox.shrink();
      },
    );
  }
}

