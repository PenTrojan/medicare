//==================================================
//"Dumb" Presenter
// This file will handle only the visual layout.
// It receives data and displays it.
// It does not know about Firebase or jobId
//==================================================
//
import 'package:flutter/material.dart';

class AssistantProfileUI extends StatelessWidget {
  final Map<String, dynamic> profile;

  const AssistantProfileUI({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final workingTimes = profile['workingTimes'] as Map<String, dynamic>? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header with Avatar and Name
        Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: profile['profilePicUrl'] != null
                  ? NetworkImage(profile['profilePicUrl'])
                  : null,
              child: profile['profilePicUrl'] == null
                  ? const Icon(Icons.person, size: 40)
                  : null,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile['name'] ?? 'Assistant',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "${profile['experienceLevel']?.toString().toUpperCase()} Helper",
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "Rs. ${profile['dailyRate']}/day",
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Divider(height: 40),
        // 2. Bio Section
        _buildSectionTitle("Bio"),
        Text(
          profile['bio'] ?? "No bio available.",
          style: const TextStyle(fontSize: 15, height: 1.5),
        ),
        const SizedBox(height: 20),
        // 3. Skills Chips
        _buildSectionTitle("Skills"),
        Wrap(
          spacing: 8,
          children: (profile['skills'] as List<dynamic>? ?? [])
              .map(
                (skill) => Chip(
                  label: Text(skill.toString()),
                  backgroundColor: Colors.blue[50],
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 20),
        // 4. Availability
        _buildSectionTitle("Weekly Availability"),
        ...workingTimes.entries.map((entry) {
          final times = entry.value as List<dynamic>;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  entry.key,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  "${times[0]} - ${times[1]}",
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey,
        ),
      ),
    );
  }
}
