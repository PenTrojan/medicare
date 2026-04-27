import 'package:flutter/material.dart';

class AssistantProfileView extends StatelessWidget {
  final Map<String, dynamic> profile;

  const AssistantProfileView({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    // Helper to safely format working times
    final workingTimes = profile['workingTimes'] as Map<String, dynamic>? ?? {};

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle for the BottomSheet
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header Section
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

            _buildSectionTitle("Bio"),
            Text(
              profile['bio'] ?? "No bio available.",
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),

            const SizedBox(height: 20),

            _buildSectionTitle("Experience Details"),
            Text(
              profile['experienceDescription'] ?? "No details provided.",
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),

            const SizedBox(height: 20),

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

            _buildSectionTitle("Weekly Availability"),
            const SizedBox(height: 10),
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

            const SizedBox(height: 30),

            // Call to Action
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // Handle Hiring/Booking Step
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Request Booking",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
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
