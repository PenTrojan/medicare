import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medicare/models/app_user.dart';

// For converting data from the firestore database into objects in the client side

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Listener to watch for logins/logouts
  Stream<User?> get userStream => _auth.authStateChanges();

  // method to get the user data from the firestore
  Stream<AppUser?> appUserStream(User firebaseUser) {
    // if anonymous user
    if (firebaseUser.isAnonymous) {
      // creates a seeker with a tempID
      return Stream.value(Seeker(uid: firebaseUser.uid));
    }

    // getting data as a stream from the firestore (.snapshots())
    // convert the document snap to an appuser onject from map()
    return _db.collection('users').doc(firebaseUser.uid).snapshots().map((doc) {
      // use polymorphism to create object
      return AppUser.fromFirestore(doc);
    });
  }

  // Creating a user object when role picking
  Future<void> createUserProfile(User firebaseUser, String role) async {
    AppUser newUser;

    if (role == 'assistant') {
      newUser = Assistant(
        uid: firebaseUser.uid,
        displayName: firebaseUser.displayName ?? "New Assistant",
        email: firebaseUser.email ?? "",
      );
    } else {
      newUser = Seeker(
        uid: firebaseUser.uid,
        displayName: firebaseUser.displayName ?? "New Seeker",
        email: firebaseUser.email ?? "",
      );
    }

    // Call the polymorphic save method
    await newUser.saveToFirestore();
  }
}
