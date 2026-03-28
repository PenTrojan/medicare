import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/job.dart';

class JobExpanded extends StatelessWidget {
  final Job job;
  const JobExpanded({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${job.patientName}'s Case")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- TOP SECTION: Job Details ---
            _buildSectionHeader("Patient Information"),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildDetailRow(Icons.person, "Name", job.patientName),
                    _buildDetailRow(
                      Icons.cake,
                      "Age",
                      "${job.patientAge} years",
                    ),
                    _buildDetailRow(
                      Icons.medical_information,
                      "Condition",
                      job.patientCondition,
                    ),
                    _buildDetailRow(Icons.location_on, "Address", job.address),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            // --- BOTTOM SECTION: Matched Assistants ---
            _buildSectionHeader("Top Matched Assistants"),
            const SizedBox(height: 10),

            if (job.topMatches.isEmpty)
              _buildMatchingLoader()
            else
              ListView.builder(
                shrinkWrap: true, // Needed inside SingleChildScrollView
                physics: const NeverScrollableScrollPhysics(),
                itemCount: job.topMatches.length,
                itemBuilder: (context, index) {
                  final assistant = job.topMatches[index];
                  return Card(
                    color: Colors.blue[50],
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.health_and_safety),
                      ),
                      title: Text(assistant['name'] ?? "Assistant"),
                      subtitle: Text(
                        "${assistant['distance'].toStringAsFixed(1)} km away",
                      ),
                      trailing: ElevatedButton(
                        onPressed: () {
                          /* Handle Booking Logic */
                        },
                        child: const Text("View Profile"),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // Helper widgets for a clean UI
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.blueGrey,
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 10),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildMatchingLoader() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 20),
          const CircularProgressIndicator(),
          const SizedBox(height: 15),
          Text(
            "Analyzing skills and proximity...",
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
