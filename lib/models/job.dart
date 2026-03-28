import 'package:cloud_firestore/cloud_firestore.dart';

// pending - still not matched with list
// matching - matched list created
// assigned - an assistant is assigned
// completed - job finished
enum JobStatus { pending, matching, assigned, completed }

class Job {
  final String id;
  final String seekerId;
  final String patientName;
  final int patientAge;
  final String patientCondition;
  final String address;
  final GeoPoint location;
  final List<String> requiredSkills;
  //final double offeredRate;
  final DateTime createdAt;
  JobStatus status;

  // Populated by the cloud function
  final List<Map<String, dynamic>> topMatches;

  Job({
    required this.id,
    required this.seekerId,
    required this.patientName,
    required this.patientAge,
    required this.patientCondition,
    required this.address,
    required this.location,
    required this.requiredSkills,
    //required this.offeredRate,
    required this.createdAt,
    this.status = JobStatus.pending,
    this.topMatches = const [],
  });

  // Create a Job from a Firestore Document
  factory Job.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Job(
      id: doc.id,
      seekerId: data['seekerId'] ?? '',
      patientName: data['patientName'] ?? '',
      patientAge: data['patientAge'] ?? 0,
      patientCondition: data['patientCondition'] ?? '',
      address: data['address'] ?? '',
      location: data['location'] as GeoPoint,
      requiredSkills: List<String>.from(data['requiredSkills'] ?? []),
      //offeredRate: (data['offeredRate'] ?? 0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      status: JobStatus.values.firstWhere((e) => e.name == data['status']),
      topMatches: List<Map<String, dynamic>>.from(data['topMatches'] ?? []),
    );
  }

  // Convert Job to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'seekerId': seekerId,
      'patientName': patientName,
      'patientAge': patientAge,
      'patientCondition': patientCondition,
      'address': address,
      'location': location,
      'requiredSkills': requiredSkills,
      //'offeredRate': offeredRate,
      'createdAt': FieldValue.serverTimestamp(), // Set the saved time
      'status': status.name,
      'topMatches': topMatches,
    };
  }

  Future<void> saveToFirestore() async {
    final collection = FirebaseFirestore.instance.collection('jobs');

    if (id.isEmpty) {
      // Create new job
      await collection.add(toMap());
    } else {
      // Update existing job
      await collection.doc(id).update(toMap());
    }
  }
}
