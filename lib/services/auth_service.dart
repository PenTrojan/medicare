import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medicare/models/app_user.dart';

// For converting data from the firestore database into objects in the client side

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Listener to watch for logins/logouts
  Stream<User?> get userStream => _auth.authStateChanges();

  // Asynchronous call to getting user data from the server and create an object
  Future<AppUser?> getAppUserData(User firebaseUser) async {
    // if anonymous user
    if (firebaseUser.isAnonymous) {
      // creates a seeker with a tempID
      return Seeker(uid: firebaseUser.uid);
    }

    // if not anonymous fetch user data from the database
    DocumentSnapshot doc = await _db
        .collection('users')
        .doc(firebaseUser.uid)
        .get();

    if (!doc.exists) return null;

    // maps the data from the database to a map
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // defaults to seeker if something goes wrong
    String role = data['role'] ?? 'seeker';

    //Note: subtype polymorphism ======================================
    // function return type is AppUser but return seeker or assistant

    if (role == 'assistant') {
      return Assistant(
        uid: doc.id,
        displayName: data['name'],
        email: data['email'],
        skills: List<String>.from(data['skills'] ?? []),
        isVerified: data['isVerified'] ?? false,
      );
    } else {
      return Seeker(
        uid: doc.id,
        displayName: data['name'],
        email: data['email'],
        activeJobIds: List<String>.from(data['activeJobIds'] ?? []),
      );
    }
  }

  // Creating a user object when role picking
  Future<void> createUserProfile(User user, String role) async {
    try {
      await _db.collection('users').doc(user.uid).set({
        // initialize the values inside the database
        'uid': user.uid,
        'email': user.email,
        'role': role,
        'name': user.displayName ?? 'New User',
        'createdAt': FieldValue.serverTimestamp(),

        if (role == 'assistant') 'skills': [],
        if (role == 'assistant') 'isVerified': false,
        if (role == 'seeker') 'activeJobIds': [],
      });
    } catch (e) {
      print("Error creating user profile: $e");
      rethrow;
    }
  }
}
