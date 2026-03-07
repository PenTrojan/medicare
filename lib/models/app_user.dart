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
  bool _registrationComplete = false;

  AppUser({required String uid, String? displayName, String? email})
    : _uid = uid,
      _displayName = displayName,
      _email = email;

  // getters allow for read only
  String get uid => _uid;
  String? get displayName => _displayName;
  String? get email => _email;
  bool get registrationComplete => _registrationComplete;

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
      assistant._registrationComplete = data['registrationComplete'] ?? false;

      return assistant;
    } else {
      final seeker = Seeker(
        uid: doc.id,
        displayName: data['name'],
        email: data['email'],
      );

      seeker._activeJobIds = List<String>.from(data['activeJobIds'] ?? []);
      seeker._registrationComplete = data['registrationComplete'] ?? false;
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


  // getters for UI to read the existing data
  String? get nic => _nic;
  String? get nicImageUrl => _nicImageUrl;
  String? get address => _address;
  String? get bio => _bio;
  String? get experienceDescription => _experienceDescription;
  List<String> get skills => _skills;
  Map<String, List<String>> get workingTimes => _workingTimes;
  List<String> get proofText => _proofText;
  List<String> get proofImageUrls => _proofImageUrls;
  bool get isVerified => _isVerified;


  // update details inside the object locally (before uploading to the firestore)
  void updateRegistrationDetails({
    required String nic,
    required String? nicImageUrl,
    required String address,
    required String bio,
    required String experienceDescription,
    required List<String> skills,
    required Map<String, List<String>> workingTimes,
    required List<String> proofText,
    required List<String> proofImageUrls,
    required bool registrationComplete,
  }) {
    _nic = nic;
    _nicImageUrl = nicImageUrl;
    _address = address;
    _bio = bio;
    _experienceDescription = experienceDescription;
    _skills = skills;
    _workingTimes = workingTimes;
    _proofText = proofText;
    _proofImageUrls = proofImageUrls;
    _registrationComplete = registrationComplete;
  }


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
      'registrationComplete': _registrationComplete,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

// ===========================================================================
// ============== Seeker class ===============================================
// ===========================================================================

class Seeker extends AppUser {

  bool _isGuest;         // for anonymous users
  List<String> _activeJobIds;

  Seeker({required super.uid, super.displayName, super.email, bool isGuest = false,})
    : _isGuest = isGuest,
      _activeJobIds = [];


  // getter for isGuest
  bool get isGuest => _isGuest;
  
  //isGuest is not sent
  @override
  Future<void> saveToFirestore() async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'uid': uid,
      'name': displayName,
      'email': email,
      'role': 'seeker',
      'activeJobIds': _activeJobIds,
      'registrationComplete': _registrationComplete,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
