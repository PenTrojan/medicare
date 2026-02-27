import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:medicare/screens/assistant/assistant_dashboard.dart'
    as assistant_dashboard;
import 'package:medicare/screens/seeker/seeker_dashboard.dart'
    as seeker_dashboard;

// auth UI
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If NOT logged in, show the FirebaseUI SignInScreen
        if (!snapshot.hasData) {
          return SignInScreen(
            providers: FirebaseUIAuth.providersFor(FirebaseAuth.instance.app),
            headerBuilder: (context, constraints, shrinkOffset) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Icon(
                  Icons.medical_services,
                  size: 60,
                  color: Colors.blue,
                ),
              );
            },
          );
        }

        // 2. If the user IS logged in, show your home page
        return const assistant_dashboard.AssistantDash();
      },
    );
  }
}
