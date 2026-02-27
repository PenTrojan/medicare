import 'package:firebase_core/firebase_core.dart';
import 'package:medicare/firebase_options.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:firebase_auth/firebase_auth.dart' as f_auth;
//prefix used to avoid conflicts in naming (having EmailAuthProvider() in both f_auth and f_ui_auth)

Future<void> firebaseInitialize() async {
  //Future part tells that this is async and might take some time
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize FirebaseUIAut providers
  FirebaseUIAuth.configureProviders([
    EmailAuthProvider(),
    GoogleProvider(
      // web client ID from the firebase Google sign in method
      clientId:
          '516002987264-fv78t5h707jb6ujbfe17h030opab9m37.apps.googleusercontent.com',
    ),
  ]);
}
