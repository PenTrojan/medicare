import 'package:cloud_firestore/cloud_firestore.dart';

class SkillManager {
  final List<String> availableSkills;

  SkillManager({required this.availableSkills});

  factory SkillManager.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final skills = (data['available_skills'] as List?)?.cast<String>() ?? <String>[];
    return SkillManager(availableSkills: skills);
  }

  static DocumentReference get _docRef => FirebaseFirestore.instance.collection('metadata').doc('skills');

  Future<void> addSkill(String newSkill) async {
    await _docRef.update({
      'available_skills': FieldValue.arrayUnion([newSkill])
    });
  }

  Future<void> removeSkill(String skillToRemove) async {
    await _docRef.update({
      'available_skills': FieldValue.arrayRemove([skillToRemove])
    });
  }

  Future<void> editSkill(String oldSkill, String newSkill) async {
    // Remove old, then add new
    await _docRef.update({
      'available_skills': FieldValue.arrayRemove([oldSkill])
    });
    await _docRef.update({
      'available_skills': FieldValue.arrayUnion([newSkill])
    });
  }
}
