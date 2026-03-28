import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_user.dart';

// ===========================================================================
// ============== Seeker class ===============================================
// ===========================================================================

class Seeker extends AppUser {
  bool _isGuest; // for anonymous users
  List<String> _activeJobIds;
  String? _profilePicUrl;

  Seeker({
    required super.uid,
    super.displayName,
    super.email,
    bool isGuest = false,
  }) : _isGuest = isGuest,
       _activeJobIds = [];

  factory Seeker.fromMap(String id, Map<String, dynamic> data) {
    final seeker = Seeker(
      uid: id,
      displayName: data['name'],
      email: data['email'],
    );
    seeker._profilePicUrl = data['profilePicUrl'];

    seeker._activeJobIds = List<String>.from(data['activeJobIds'] ?? []);
    seeker.registrationComplete = data['registrationComplete'] ?? false;
    return seeker;
  }

  // getter for isGuest
  bool get isGuest => _isGuest;
  String? get profilePicUrl => _profilePicUrl;

  void updateRegistrationDetails({
    required String displayName,
    required bool registrationComplete,
    required String? profilePicUrl,
  }) {
    this.displayName = displayName;
    this.registrationComplete = registrationComplete;
  }

  //isGuest is not sent
  @override
  Future<void> saveToFirestore() async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'uid': uid,
      'name': displayName,
      'email': email,
      'role': 'seeker',
      'profilePicUrl': _profilePicUrl,
      'activeJobIds': _activeJobIds,
      'registrationComplete': registrationComplete,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
