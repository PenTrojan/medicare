import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/job.dart';
import '../shared/job_details_view.dart';

class InvitationsPage extends StatelessWidget {
  const InvitationsPage({super.key});

  ///Logic to fetch Job data and Navigate
  Future<void> _viewJobDetails(BuildContext context, String jobId) async {
    try {
      // 1. Fetch the actual job document
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('jobs')
          .doc(jobId)
          .get();

      if (!doc.exists) {
        throw "Job no longer exists";
      }

      // 2. Convert to your Job model
      final job = Job.fromFirestore(doc);

      // 3. Navigate to the Assistant-specific view
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AssistantJobPage(
              job: job,
              isPendingInvitation: true, // Shows the Accept/Decline buttons
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error loading job: $e")));
      }
    }
  }

  Future<void> _acceptJob(
    BuildContext context,
    String invitationId,
    String jobId,
  ) async {
    final assistantId = FirebaseAuth.instance.currentUser!.uid;
    final batch = FirebaseFirestore.instance.batch();

    batch.update(
      FirebaseFirestore.instance.collection('invitations').doc(invitationId),
      {'status': 'accepted'},
    );

    batch.update(FirebaseFirestore.instance.collection('jobs').doc(jobId), {
      'assignedAssistantId': assistantId,
      'status': 'in_progress',
    });

    try {
      await batch.commit();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Job accepted!")));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Future<void> _declineJob(String invitationId) async {
    await FirebaseFirestore.instance
        .collection('invitations')
        .doc(invitationId)
        .update({'status': 'declined'});
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Job Invitations")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('invitations')
            .where('assistantId', isEqualTo: currentUid)
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Center(child: Text("Error: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final invitations = snapshot.data!.docs;
          if (invitations.isEmpty)
            return const Center(child: Text("No new invitations."));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: invitations.length,
            itemBuilder: (context, index) {
              final invite = invitations[index];
              final data = invite.data() as Map<String, dynamic>;
              final String jobId = data['jobId'];
              final String inviteId = invite.id;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 15),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['patientName'] ?? "Medical Request",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text("You have been requested for this case."),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // VIEW DETAILS BUTTON
                          TextButton.icon(
                            onPressed: () => _viewJobDetails(context, jobId),
                            icon: const Icon(Icons.visibility_outlined),
                            label: const Text("View Details"),
                          ),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () => _declineJob(inviteId),
                                child: const Text(
                                  "Decline",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () =>
                                    _acceptJob(context, inviteId, jobId),
                                child: const Text("Accept"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

