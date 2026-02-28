// abstract class for users
abstract class AppUser {
  // attributes common to all users
  final String uid;
  final String? displayName; //Nullable for guests
  final String? email; //Nullable for guests

  AppUser({required this.uid, this.displayName, this.email});

  Map<String, dynamic>
  toMap(); // abstract method for mapping data from the database
}

// Inheritance =======================================================

class Assistant extends AppUser {
  final List<String> skills;
  final bool isVerified;

  Assistant({
    required super.uid,
    required super.displayName, // required because no anonymous users
    required super.email, // required because no anonymous users
    required this.skills,
    this.isVerified = false,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': displayName,
      'email': email,
      'role': 'assistant',
      'skills': skills,
      'isVerified': isVerified,
    };
  }
}

class Seeker extends AppUser {
  final List<String> activeJobIds;

  Seeker({
    required super.uid,
    super.displayName,
    super.email,
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
