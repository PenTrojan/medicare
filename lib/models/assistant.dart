import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_user.dart';

// ============================================================================
// ============== Assistant class =============================================
// ============================================================================

class Assistant extends AppUser {
  Gender _gender = Gender.unspecified;
  String? _profilePicUrl;
  String? _profileImageUrl;
  int? _age;
  String? _nic;
  String? _nicImageUrl;
  String? _nicProofImageUrl;
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
  List<String> _proofDocumentsUrls;

  bool _isVerified = false;
  bool _isBooked = false;

  // constructor
  Assistant({
    required super.uid,
    required super.displayName,
    required super.email,
    super.isSuspended = false,
  }) : _skills = [],
       _workingTimes = {},
       _proofText = [],
       _proofImageUrls = [],
       _proofDocumentsUrls = [];

  factory Assistant.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final assistant = Assistant.fromMap(doc.id, data);

    assistant._profileImageUrl =
        (data['profileImageUrl'] as String?) ?? assistant._profilePicUrl;
    assistant._nicProofImageUrl =
        (data['nicProofImageUrl'] as String?) ?? assistant._nicImageUrl;

    final proofDocuments =
        (data['proofDocumentsUrls'] as List?) ??
        data['proofImageUrls'] as List?;
    assistant._proofDocumentsUrls = proofDocuments == null
        ? []
        : proofDocuments.whereType<String>().toList();

    return assistant;
  }

  factory Assistant.fromMap(String id, Map<String, dynamic> data) {
    final assistant = Assistant(
      uid: id,
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
    assistant._profileImageUrl =
        (data['profileImageUrl'] as String?) ?? assistant._profilePicUrl;
    assistant._age = data['age'];
    assistant._nic = data['nic'];
    assistant._nicImageUrl = data['nicImageUrl'];
    assistant._nicProofImageUrl =
        (data['nicProofImageUrl'] as String?) ?? assistant._nicImageUrl;
    assistant._bio = data['bio'];
    assistant._address = data['address'];
    assistant._rating = (data['rating'] as num?)?.toDouble();
    assistant._experienceDescription = data['experience'];
    assistant._dailyRate = data['dailyRate'] as int?;
    assistant._skills = List<String>.from(data['skills'] ?? []);
    assistant._proofImageUrls = List<String>.from(data['proofImageUrls'] ?? []);
    assistant._proofDocumentsUrls = List<String>.from(
      data['proofDocumentsUrls'] ?? data['proofImageUrls'] ?? [],
    );
    assistant._isVerified = data['isVerified'] ?? false;
    assistant._isBooked = data['isBooked'] ?? false;
    assistant.isSuspended = data['isSuspended'] ?? false;

    // safely casting as a map of lists
    if (data['workingTimes'] != null) {
      assistant._workingTimes = (data['workingTimes'] as Map).map(
        (key, value) => MapEntry(key.toString(), List<String>.from(value)),
      );
    }
    assistant._proofText = List<String>.from(data['proofText'] ?? []);
    assistant.registrationComplete = data['registrationComplete'] ?? false;

    return assistant;
  }

  // getters for UI to read the existing data
  Gender get gender => _gender;
  String? get profilePicUrl => _profilePicUrl;
  String? get profileImageUrl => _profileImageUrl;
  int? get age => _age;
  String? get nic => _nic;
  String? get nicImageUrl => _nicImageUrl;
  String? get nicProofImageUrl => _nicProofImageUrl;
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
  List<String> get proofDocumentsUrls => _proofDocumentsUrls;
  bool get isVerified => _isVerified;
  bool get isBooked => _isBooked;

  // update details inside the object locally (before uploading to the firestore)
  void updateRegistrationDetails({
    required String displayName,
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
    this.displayName = displayName;
    _nic = nic;
    _nicImageUrl = nicImageUrl;
    _address = address;
    _bio = bio;
    _experienceDescription = experienceDescription;
    _skills = skills;
    _workingTimes = workingTimes;
    _proofText = proofText;
    _proofImageUrls = proofImageUrls;
    this.registrationComplete = registrationComplete;
    _gender = gender;
    _age = age;
    _dailyRate = dailyRate;
    _experienceLevel = experienceLevel;
    _profilePicUrl = profilePicUrl;
    _location = location;
  }

  // Polymorphism
  @override
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': displayName,
      'email': email,
      'role': 'assistant',
      'gender': _gender.name,
      'age': _age,
      'profilePicUrl': _profilePicUrl,
      'profileImageUrl': _profileImageUrl,
      'nic': _nic,
      'nicImageUrl': _nicImageUrl,
      'nicProofImageUrl': _nicProofImageUrl,
      'location': _location,
      'skills': _skills,
      'dailyRate': _dailyRate,
      'experienceLevel': _experienceLevel.name,
      'isVerified': _isVerified,
      'isBooked': _isBooked,
      'isSuspended': isSuspended,
      'experience': _experienceDescription,
      'address': _address,
      'rating': _rating,
      'bio': _bio,
      'workingTimes': _workingTimes,
      'proofText': _proofText,
      'proofImageUrls': _proofImageUrls,
      'proofDocumentsUrls': _proofDocumentsUrls,
      'registrationComplete': registrationComplete,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  @override
  Future<void> saveToFirestore() async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set(toMap());
  }
}
