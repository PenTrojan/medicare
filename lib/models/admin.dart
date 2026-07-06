import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_user.dart';

// ===========================================================================
// ============== Admin class ===============================================
// ===========================================================================

class Admin extends AppUser {
  String get role => 'admin';

  Admin({
    required super.uid,
    super.displayName,
    super.email,
    super.isSuspended = false,
    super.profilePicUrl,
  });

  /*
  // Factory constructor from Firestore DocumentSnapshot
  factory Admin.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Admin(
      uid: doc.id,
      displayName: data['name'] ?? data['displayName'],
      email: data['email'],
      isSuspended: data['isSuspended'] ?? false,
    );
  }*/

  // Factory fromMap for AppUser.fromFirestore
  factory Admin.fromMap(String id, Map<String, dynamic> data) {
    return Admin(
      uid: id,
      displayName: data['name'] ?? data['displayName'],
      profilePicUrl: data['profilePicUrl'],
      email: data['email'],
      isSuspended: data['isSuspended'] ?? false,
    );
  }

  Future<void> updateRegistrationDetails({String? name, String? email}) async {
    if (name != null) displayName = name;
    // _email is final in AppUser, so this only updates Firestore
    final updateData = <String, dynamic>{};
    if (name != null) updateData['name'] = name;
    if (email != null) updateData['email'] = email;
    if (updateData.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update(updateData);
    }
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': displayName,
      'email': email,
      'role': role,
      'isSuspended': isSuspended,
      'profilePicUrl': profilePicUrl,
      'registrationComplete': registrationComplete,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  @override
  Future<void> saveToFirestore() async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set(toMap());
  }
}
