// abstract class for users
abstract class AppUser {
  // attributes common to all users
  final String uid;
  final String displayName;
  final String email;

  AppUser({required this.uid, required this.displayName, required this.email});

  // Convert Firestore document to a specific User object
  Map<String, dynamic> toMap();
}

class Caregiver extends AppUser {
  final List<String> skills;
  final bool isVerified;

  Caregiver({
    required super.uid,
    required super.displayName,
    required super.email,
    required this.skills,
    this.isVerified = false,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': displayName,
      'email': email,
      'role': 'caregiver',
      'skills': skills,
      'isVerified': isVerified,
    };
  }
}

class Seeker extends AppUser {
  final List<String> activeJobIds;

  Seeker({
    required super.uid,
    required super.displayName,
    required super.email,
    this.activeJobIds = const [],
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': displayName,
      'email': email,
      'role': 'seeker',
      'activeJobIds': activeJobIds,
    };
  }
}
