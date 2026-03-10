import 'package:cloud_firestore/cloud_firestore.dart';

// enum definition for gender
enum Gender { male, female, unspecified }

enum ExperienceLevel {
  lessThanOne, // < 1 Year
  oneToThree, // 1-3 Years
  threeToFive, // 3-5 Years
  fivePlus, // 5+ Years
  unspecified,
}

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

      assistant._gender = Gender.values.firstWhere(
        (e) => e.name == (data['gender'] ?? 'unspecified'),
        orElse: () => Gender.unspecified,
      );

      if (data['experienceLevel'] != null) {
        assistant._experienceLevel = ExperienceLevel.values.firstWhere(
          (e) => e.name == data['experienceLevel'],
          orElse: () => ExperienceLevel.unspecified,
        );
      }

      assistant._profilePicUrl = data['profilePicUrl'];
      assistant._age = data['age'];
      assistant._nic = data['nic'];
      assistant._nicImageUrl = data['nicImageUrl'];
      assistant._bio = data['bio'];
      assistant._address = data['address'];
      assistant._rating = (data['rating'] as num?)?.toDouble();
      assistant._experienceDescription = data['experience'];
      assistant._dailyRate = data['dailyRate'] as int?;
      assistant._skills = List<String>.from(data['skills'] ?? []);
      assistant._proofImageUrls = List<String>.from(
        data['proofImageUrls'] ?? [],
      );
      assistant._isVerified = data['isVerified'] ?? false;
      assistant._isBooked = data['isBooked'] ?? false;

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
  Gender _gender = Gender.unspecified;
  String? _profilePicUrl;
  int? _age;
  String? _nic;
  String? _nicImageUrl;
  String? _address;
  GeoPoint? _location;
  List<String> _skills;
  Map<String, List<String>>
  _workingTimes; // Ex - {'Monday': ['08:00', '17:00']}
  int? _dailyRate;
  ExperienceLevel _experienceLevel = ExperienceLevel.unspecified;
  String? _bio;
  String? _experienceDescription;
  double? _rating;
  List<String> _proofText;
  List<String> _proofImageUrls;

  bool _isVerified = false;
  bool _isBooked = false;

  // constructor
  Assistant({
    required super.uid,
    required super.displayName,
    required super.email,
  }) : _skills = [],
       _workingTimes = {},
       _proofText = [],
       _proofImageUrls = [];

  // getters for UI to read the existing data
  Gender get gender => _gender;
  String? get profilePicUrl => _profilePicUrl;
  int? get age => _age;
  String? get nic => _nic;
  String? get nicImageUrl => _nicImageUrl;
  String? get address => _address;
  GeoPoint? get location => _location;
  ExperienceLevel? get experienceLevel => _experienceLevel;
  String? get bio => _bio;
  String? get experienceDescription => _experienceDescription;
  double? get rating => _rating;
  List<String> get skills => _skills;
  Map<String, List<String>> get workingTimes => _workingTimes;
  int? get dailyRate => _dailyRate;
  List<String> get proofText => _proofText;
  List<String> get proofImageUrls => _proofImageUrls;
  bool get isVerified => _isVerified;
  bool get isBooked => _isBooked;

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
    required Gender gender,
    required int age,
    required int dailyRate,
    required ExperienceLevel experienceLevel,
    required String? profilePicUrl,
    GeoPoint? location,
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
    _gender = gender;
    _age = age;
    _dailyRate = dailyRate;
    _experienceLevel = experienceLevel;
    _profilePicUrl = profilePicUrl;
    _location = location;
  }

  // Polymorphism
  @override
  Future<void> saveToFirestore() async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'uid': uid,
      'name': displayName,
      'email': email,
      'role': 'assistant',
      'gender': _gender.name,
      'age': _age,
      'profilePicUrl': _profilePicUrl,
      'nic': _nic,
      'nicImageUrl': _nicImageUrl,
      'location': _location,
      'skills': _skills,
      'dailyRate': _dailyRate,
      'experienceLevel': _experienceLevel.name,
      'isVerified': _isVerified,
      'isBooked': _isBooked,
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
  bool _isGuest; // for anonymous users
  List<String> _activeJobIds;

  Seeker({
    required super.uid,
    super.displayName,
    super.email,
    bool isGuest = false,
  }) : _isGuest = isGuest,
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
