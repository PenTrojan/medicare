import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:medicare/screens/assistant/assistant_dashboard.dart'
    as assistant_dashboard;
import 'package:medicare/screens/seeker/seeker_dashboard.dart'
    as seeker_dashboard;
import 'package:medicare/services/auth_service.dart';
import 'package:medicare/models/app_user.dart';
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

            // Polymorphic Routing ================================================
            //======================================================================
            // * if registration complete -> show the relevent dashboard
            // * if not registered -> show the relevent registration screen
            //======================================================================
            if (appUser is Assistant) {
              if (!appUser.registrationComplete) {
                return const assistant_reg.AssistantReg();
              }
              return const assistant_dashboard.AssistantDash();
            } else if (appUser is Seeker) {
                if (!appUser.registrationComplete && !appUser.isGuest) {
                  return const seeker_reg.SeekerReg();
                }
              return const seeker_dashboard.SeekerDash();
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
