import 'package:cloud_firestore/cloud_firestore.dart';

// ============================================================================
// ============== User class ==================================================
// ============================================================================

// abstract class for users
abstract class AppUser {
  // attributes common to all users
  // final -> cannot be changed
  // _ -> private

  // ENCAPSULATION =================================================
  final String _uid;
  final String? _displayName; //Nullable for guests
  final String? _email; //Nullable for guests

  AppUser({required String uid, String? displayName, String? email})
    : _uid = uid,
      _displayName = displayName,
      _email = email;

  // getters allow for read only
  String get uid => _uid;
  String? get displayName => _displayName;
  String? get email => _email;

  Future<void>
  saveToFirestore(); // abstract method for saving data to the database

  //=================================================================================
  //=============== Converting the output from the firestore to an object ===========
  //=================================================================================

  static AppUser? fromFirestore(DocumentSnapshot doc) {
    // static factory method to create an object using the data in the databse
    // if no entry found in the database return null
    if (!doc.exists) return null;

    // convert to a map object
    final data = doc.data() as Map<String, dynamic>;

    // default is seeker is something went wrong
    final role = data['role'] ?? 'seeker';

    if (role == 'assistant') {
      final assistant = Assistant(
        uid: doc.id,
        displayName: data['name'],
        email: data['email'],
      );

      // factory method can access private fields

      assistant._nic = data['nic'];
      assistant._nicImageUrl = data['nicImageUrl'];
      assistant._bio = data['bio'];
      assistant._address = data['address'];
      assistant._rating = (data['rating'] as num?)?.toDouble();
      assistant._experienceDescription = data['experience'];
      assistant._skills = List<String>.from(data['skills'] ?? []);
      assistant._proofImageUrls = List<String>.from(
        data['proofImageUrls'] ?? [],
      );
      assistant._isVerified = data['isVerified'] ?? false;

      // safely casting as a map of lists
      if (data['workingTimes'] != null) {
        assistant._workingTimes = (data['workingTimes'] as Map).map(
          (key, value) => MapEntry(key.toString(), List<String>.from(value)),
        );
      }
      assistant._proofText = List<String>.from(data['proofText'] ?? []);

      return assistant;
    } else {
      final seeker = Seeker(
        uid: doc.id,
        displayName: data['name'],
        email: data['email'],
      );

      seeker._activeJobIds = List<String>.from(data['activeJobIds'] ?? []);

      return seeker;
    }
  }
}

// Inheritance =======================================================

// ============================================================================
// ============== Assistant class =============================================
// ============================================================================

class Assistant extends AppUser {
  String? _nic;
  String? _nicImageUrl;
  List<String> _skills;
  bool _isVerified;
  String? _experienceDescription;
  String? _address;
  double? _rating;
  String? _bio;
  Map<String, List<String>>
  _workingTimes; // Ex - {'Monday': ['08:00', '17:00']}
  List<String> _proofText;
  List<String> _proofImageUrls;

  // constructor
  Assistant({
    required super.uid,
    required super.displayName,
    required super.email,
  }) : _skills = [],
       _workingTimes = {},
       _proofText = [],
       _proofImageUrls = [],
       _isVerified = false;

  // Polymorphism
  @override
  Future<void> saveToFirestore() async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'uid': uid,
      'name': displayName,
      'email': email,
      'role': 'assistant',
      'nic': _nic,
      'nicImageUrl': _nicImageUrl,
      'skills': _skills,
      'isVerified': _isVerified,
      'experience': _experienceDescription,
      'address': _address,
      'rating': _rating,
      'bio': _bio,
      'workingTimes': _workingTimes,
      'proofText': _proofText,
      'proofImageUrls': _proofImageUrls,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

// ===========================================================================
// ============== Seeker class ===============================================
// ===========================================================================

class Seeker extends AppUser {
  List<String> _activeJobIds;

  Seeker({required super.uid, super.displayName, super.email})
    : _activeJobIds = [];

  @override
  Future<void> saveToFirestore() async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'uid': uid,
      'name': displayName,
      'email': email,
      'role': 'seeker',
      'activeJobIds': _activeJobIds,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
