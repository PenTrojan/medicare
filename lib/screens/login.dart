import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:medicare/screens/assistant/assistant_main.dart';
import 'package:medicare/screens/seeker/seeker_main.dart';
import 'package:medicare/screens/admin/admin_main.dart';
import 'package:medicare/services/auth_service.dart';
import 'package:medicare/models/app_user.dart';
import 'package:medicare/models/assistant.dart';
import 'package:medicare/models/seeker.dart';
import 'package:medicare/models/admin.dart';
import 'package:medicare/screens/role_picker.dart';
import 'package:medicare/screens/assistant/assistant_reg.dart' as assistant_reg;
import 'package:medicare/screens/seeker/seeker_reg.dart' as seeker_reg;

// auth UI
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // create an auth service object to get user data
    final AuthService authService = AuthService();

    return StreamBuilder<User?>(
      // listener from the auth service
      stream: authService.userStream,
      builder: (context, snapshot) {
        // Not logged in -> show the FirebaseUI SignInScreen
        if (!snapshot.hasData) {
          return SignInScreen(
            providers: FirebaseUIAuth.providersFor(FirebaseAuth.instance.app),

            // browse anonymously option
            footerBuilder: (context, action) {
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: TextButton(
                  onPressed: () => FirebaseAuth.instance.signInAnonymously(),
                  child: const Text('Browse as Guest'),
                ),
              );
            },

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

        // if logged in -> fetch user data

        // real time watching for sign in status
        return StreamBuilder<AppUser?>(
          //  get user data using the appUserStream method from the authService
          stream: authService.appUserStream(snapshot.data!),

          builder: (context, userSnapshot) {
            if (userSnapshot.hasError) {
              dev.log(
                "Error loading user stream in AuthGate",
                name: "medicare.ui.login",
                error: userSnapshot.error,
              );
              return Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 60,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "A database connection issue occurred.",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Error: ${userSnapshot.error}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => FirebaseAuth.instance.signOut(),
                          child: const Text('Go Back'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            //show a loader
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // if user isn't anonymous but also isn't registered create a new user
            if (userSnapshot.data == null) {
              return const RolePicker();
            }

            final AppUser appUser = userSnapshot.data!;

            if (appUser.isSuspended) {
              return Scaffold(
                appBar: AppBar(title: const Text('Account Suspended')),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.block, size: 80, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text(
                        'Your account has been suspended by an administrator.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          FirebaseAuth.instance.signOut();
                        },
                        child: const Text('Log Out'),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Polymorphic Routing ================================================
            //======================================================================
            // * if registration complete -> show the relevent dashboard
            // * if not registered -> show the relevent registration screen
            //======================================================================
            if (appUser is Assistant) {
              if (!appUser.registrationComplete) {
                return const assistant_reg.AssistantReg();
              }
              return const AssistantMain();
            } else if (appUser is Seeker) {
              if (!appUser.registrationComplete && !appUser.isGuest) {
                return const seeker_reg.SeekerReg();
              }
              return const SeekerMain();
            } else if (appUser is Admin) {
              return const AdminMainScreen();
            }

            return const Scaffold(
              body: Center(child: Text("Error: User type unknown")),
            );
          },
        );
      },
    );
  }
}
