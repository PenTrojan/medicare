// Reusable widget to get skills list live from the database

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SkillSelector extends StatelessWidget {
  final List<String> selectedSkills;
  final Function(String, bool) onSkillToggled;

  const SkillSelector({
    super.key,
    required this.selectedSkills,
    required this.onSkillToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Select Your Skills",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('metadata')
              .doc('skills')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Text("Error loading skills");
            if (!snapshot.hasData) return const CircularProgressIndicator();

            List<String> availableSkills = List<String>.from(
              snapshot.data!.get('available_skills') ?? [],
            );

            return Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: availableSkills.map((skill) {
                final isSelected = selectedSkills.contains(skill);
                return FilterChip(
                  label: Text(skill),
                  selected: isSelected,
                  selectedColor: Theme.of(
                    context,
                  ).primaryColor.withOpacity(0.3),
                  onSelected: (bool selected) =>
                      onSkillToggled(skill, selected),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
