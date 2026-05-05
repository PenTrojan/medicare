import 'package:cloud_firestore/cloud_firestore.dart';

abstract interface class FirestoreObject {
  // Every database object needs an ID
  String get id;

  // Method to convert the object to a format Firestore understands
  Map<String, dynamic> toMap();

  // Method to handle the actual upload
  Future<void> saveToFirestore();
}
