import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_user.dart'; // for gender enum
import 'firestore_object.dart';

// pending - still not matched with list
// matching - matched list created
// assigned - an assistant is assigned
// completed - job finished
enum JobStatus { pending, matching, assigned, completed, no_matches }

class Job implements FirestoreObject {
  @override
  final String id;

  final String seekerId;
  final String patientName;
  final int patientAge;
  final String patientCondition;
  final String address;
  final GeoPoint location;
  final List<String> requiredSkills;

  final DateTime startDate;
  final DateTime endDate;
  final Map<String, List<String>> workingTimes;
  final int maxDailyRate;
  final Gender preferredGender;

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
    required this.startDate,
    required this.endDate,
    required this.workingTimes,
    required this.maxDailyRate,
    required this.preferredGender,
    required this.createdAt,
    this.status = JobStatus.pending,
    this.topMatches = const [],
  });

  // Create a Job from a Firestore Document
  factory Job.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    Map<String, List<String>> parsedTimes = {};
    if (data['workingTimes'] != null) {
      parsedTimes = (data['workingTimes'] as Map).map(
        (key, value) => MapEntry(key.toString(), List<String>.from(value)),
      );
    }

    return Job(
      id: doc.id,
      seekerId: data['seekerId'] ?? '',
      patientName: data['patientName'] ?? '',
      patientAge: data['patientAge'] ?? 0,
      patientCondition: data['patientCondition'] ?? '',
      address: data['address'] ?? '',
      location: data['location'] as GeoPoint,
      requiredSkills: List<String>.from(data['requiredSkills'] ?? []),

      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),

      workingTimes: parsedTimes,
      maxDailyRate: data['maxDailyRate'] ?? 0,
      preferredGender: Gender.values.firstWhere(
        (e) => e.name == (data['preferredGender'] ?? 'unspecified'),
        orElse: () => Gender.unspecified,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: JobStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => JobStatus.pending,
      ),
      topMatches: List<Map<String, dynamic>>.from(data['topMatches'] ?? []),
    );
  }

  // Convert Job to Map for Firestore
  @override
  Map<String, dynamic> toMap() {
    return {
      'seekerId': seekerId,
      'patientName': patientName,
      'patientAge': patientAge,
      'patientCondition': patientCondition,
      'address': address,
      'location': location,
      'requiredSkills': requiredSkills,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'workingTimes': workingTimes, // Stored as a Map in Firestore
      'maxDailyRate': maxDailyRate,
      'preferredGender': preferredGender.name,
      'createdAt': id.isEmpty
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(
              createdAt,
            ), // Set the saved time - Dont overwrite if already exista
      'status': status.name,
      'topMatches': topMatches,
    };
  }

  @override
  Future<void> saveToFirestore() async {
    final collection = FirebaseFirestore.instance.collection('jobs');

    if (id.isEmpty) {
      // Create new job
      await collection.add(toMap());
    } else {
      // Update existing job
      await collection.doc(id).set(toMap(), SetOptions(merge: true));
    }
  }
}
