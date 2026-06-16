import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get count of verified assistants where:
  /// - role == 'assistant'
  /// - isVerified == true
  /// - isSuspended == false
  static Future<int> getVerifiedAssistantsCount() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'assistant')
          .where('isVerified', isEqualTo: true)
          .where('isSuspended', isEqualTo: false)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      print(e);
      return 0;
    }
  }

  /// Get count of active seekers where:
  /// - role == 'seeker'
  /// - isSuspended == false
  static Future<int> getActiveSeekersCount() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'seeker')
          .where('isSuspended', isEqualTo: false)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      print(e);
      return 0;
    }
  }

  /// Get count of pending verifications where:
  /// - role == 'assistant'
  /// - isVerified == false
  /// - isSuspended == false
  static Future<int> getPendingVerificationsCount() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'assistant')
          .where('isVerified', isEqualTo: false)
          .where('isSuspended', isEqualTo: false)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      print(e);
      return 0;
    }
  }

  /// Get count of active jobs where status == 'active'
  static Future<int> getActiveJobsCount() async {
    try {
      final snapshot = await _firestore
          .collection('jobs')
          .where('status', isEqualTo: 'active')
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      print(e);
      return 0;
    }
  }
}
