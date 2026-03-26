import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_user.dart';

// ===========================================================================
// ============== Admin class ===============================================
// ===========================================================================

class Admin extends AppUser {
  Admin({required super.uid, super.displayName, super.email});

  factory Admin.fromMap(String id, Map<String, dynamic> data) {
    final admin = Admin(
      uid: id,
      displayName: data['name'],
      email: data['email'],
    );

    admin.registrationComplete = data['registrationComplete'] ?? true;
    return admin;
  }

  void updateRegistrationDetails({
    required String displayName,
    required bool registrationComplete,
  }) {
    this.displayName = displayName;
    this.registrationComplete = registrationComplete;
  }

  @override
  Future<void> saveToFirestore() async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'uid': uid,
      'name': displayName,
      'email': email,
      'role': 'admin',
      'registrationComplete': registrationComplete,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
