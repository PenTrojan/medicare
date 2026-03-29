import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/assistant.dart';
import '../../models/seeker.dart';
import '../../models/admin.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- TOP METRICS ---
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, userSnapshot) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('jobs').snapshots(),
                  builder: (context, jobSnapshot) {
                    int assistantCount = 0;
                    int seekerCount = 0;
                    int pendingCount = 0;
                    int activeJobsCount = 0;

                    // Use model classes for users
                    if (userSnapshot.hasData) {
                      for (var doc in userSnapshot.data!.docs) {
                        final role = (doc.data() as Map<String, dynamic>)['role'] ?? '';
                        if (role == 'assistant') {
                          final assistant = Assistant.fromMap(doc.id, doc.data() as Map<String, dynamic>);
                          assistantCount++;
                          if (!assistant.isVerified) pendingCount++;
                        } else if (role == 'seeker') {
                          final seeker = Seeker.fromMap(doc.id, doc.data() as Map<String, dynamic>);
                          seekerCount++;
                        } else if (role == 'admin') {
                          // Optionally instantiate Admin if needed
                          final admin = Admin.fromMap(doc.id, doc.data() as Map<String, dynamic>);
                        }
                      }
                    }

                    // Safely count jobs
                    if (jobSnapshot.hasData) {
                      for (var doc in jobSnapshot.data!.docs) {
                        final data = doc.data() as Map<String, dynamic>? ?? {};
                        if (data['status'] == 'active') {
                          activeJobsCount++;
                        }
                      }
                    }

                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildStatCard('Total Assistants', assistantCount.toString(), Icons.medical_services, Colors.blue)),
                            const SizedBox(width: 10),
                            Expanded(child: _buildStatCard('Total Seekers', seekerCount.toString(), Icons.people, Colors.green)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: _buildStatCard('Active Jobs', activeJobsCount.toString(), Icons.work, Colors.orange)),
                            const SizedBox(width: 10),
                            Expanded(child: _buildStatCard('Pending Verifications', pendingCount.toString(), Icons.pending_actions, Colors.purple)),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 30),
            
            // --- RECENT JOBS SECTION ---
            const Text(
              "Live Activity: Recent Jobs",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            
            StreamBuilder<QuerySnapshot>(
              // Fetch only the 5 most recent jobs
              stream: FirebaseFirestore.instance
                  .collection('jobs')
                  .orderBy('createdAt', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Text("Waiting for new jobs...");
                }
                
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text("No jobs posted recently."),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(), // Prevents scrolling conflicts
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>? ?? {};
                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[50],
                          child: const Icon(Icons.work_outline, color: Colors.blue),
                        ),
                        title: Text(data['patientName'] ?? 'Unknown Patient', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(data['medicalCondition'] ?? 'No condition listed', maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Widget to build the cards safely ---
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Prevents bottom overflow!
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            FittedBox( // Shrinks text if it's too long
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}