//==================================================
//"Dumb" Presenter
// This file will handle only the visual layout.
// It receives data and displays it.
// It does not know about Firebase or jobId
//==================================================

import 'package:flutter/material.dart';

class AssistantProfileUI extends StatelessWidget {
  final Map<String, dynamic> profile;
  final VoidCallback? onMessageTap;

  const AssistantProfileUI({
    super.key,
    required this.profile,
    this.onMessageTap,
  });

  @override
  Widget build(BuildContext context) {
    final workingTimes = profile['workingTimes'] as Map<String, dynamic>? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header with Avatar and Primary Info
        Row(
          children: [
            CircleAvatar(
              radius: 45,
              backgroundColor: Colors.blue[100],
              backgroundImage: profile['profilePicUrl'] != null
                  ? NetworkImage(profile['profilePicUrl'])
                  : null,
              child: profile['profilePicUrl'] == null
                  ? const Icon(Icons.person, size: 45, color: Colors.blue)
                  : null,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile['name'] ?? 'Assistant',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildMiniBadge(
                        profile['gender']?.toString().toUpperCase() ?? "N/A",
                      ),
                      const SizedBox(width: 8),
                      _buildMiniBadge("${profile['age'] ?? '??'} Yrs"),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Rs. ${profile['dailyRate']}/day",
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Divider(height: 40, thickness: 1),

        // 2. Quick Info Grid (Experience Level & Address)
        Row(
          children: [
            Expanded(
              child: _infoTile(
                Icons.verified_user,
                "Level",
                profile['experienceLevel']?.toString().toUpperCase() ?? "N/A",
              ),
            ),
            Expanded(
              child: _infoTile(
                Icons.location_on,
                "Location",
                profile['address'] ?? "No address",
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // 3. Bio & Experience Description
        _buildSectionTitle("About & Bio"),
        Text(
          profile['bio'] ?? "No bio available.",
          style: const TextStyle(
            fontSize: 15,
            height: 1.5,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionTitle("Work Experience"),
        Text(
          profile['experienceDescription'] ?? "No experience details provided.",
          style: TextStyle(fontSize: 14, height: 1.4, color: Colors.grey[800]),
        ),
        const SizedBox(height: 24),

        // 4. Skills Chips
        _buildSectionTitle("Medical & Care Skills"),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: (profile['skills'] as List<dynamic>? ?? [])
              .map(
                (skill) => Chip(
                  label: Text(
                    skill.toString(),
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: const Color(0xFFEFF6FF),
                  side: const BorderSide(color: Color(0xFFDBEAFE)),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 24),

        // 5. Availability
        _buildSectionTitle("Weekly Availability"),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: workingTimes.entries.map((entry) {
              final times = entry.value as List<dynamic>;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      "${times[0]} - ${times[1]}",
                      style: const TextStyle(
                        color: Color(0xFF3B82F6),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),

        // 6. Messaging Action Call-To-Action Button
        if (onMessageTap != null) ...[
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onMessageTap,
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text("Message Assistant"),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // Helper for small badges (Gender/Age)
  Widget _buildMiniBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.black54,
        ),
      ),
    );
  }

  // Helper for info tiles
  Widget _infoTile(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blueGrey),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E3A8A),
        ),
      ),
    );
  }
}
