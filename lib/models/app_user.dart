import 'package:cloud_firestore/cloud_firestore.dart';
import 'assistant.dart';
import 'seeker.dart';
import 'admin.dart';
import 'firestore_object.dart';

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
// implements the firestore object interface
abstract class AppUser implements FirestoreObject {
  // attributes common to all users
  // final -> cannot be changed
  // _ -> private

  // ENCAPSULATION =================================================
  final String _uid;
  String? _displayName; //Nullable for guests
  final String? _email; //Nullable for guests
  bool _registrationComplete = false;
  bool _isSuspended = false;

  // to satisfy the interface requirement
  @override
  String get id => _uid;

  AppUser({
    required String uid,
    String? displayName,
    String? email,
    bool isSuspended = false,
  }) : _uid = uid,
       _displayName = displayName,
       _email = email,
       _isSuspended = isSuspended;

  // getters allow for read only
  String get uid => _uid;
  String? get displayName => _displayName;
  String? get email => _email;
  bool get registrationComplete => _registrationComplete;
  bool get isSuspended => _isSuspended;

  // setters to allow child classes to modify the values
  set registrationComplete(bool value) => _registrationComplete = value;
  set displayName(String? value) => _displayName = value;
  set isSuspended(bool value) => _isSuspended = value;

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
      return Assistant.fromMap(doc.id, data);
    } else if (role == 'seeker') {
      return Seeker.fromMap(doc.id, data);
    } else if (role == 'admin') {
      return Admin.fromMap(doc.id, data);
    }

    return null;
  }

  @override
  Map<String, dynamic> toMap(); //every user must know how to turn itself to a map

  @override
  Future<void> saveToFirestore(); // abstract method for saving data to the database
}
