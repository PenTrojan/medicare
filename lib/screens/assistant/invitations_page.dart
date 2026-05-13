import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InvitationsPage extends StatelessWidget {
  const InvitationsPage({super.key});

  /// Logic to handle accepting the job
  Future<void> _acceptJob(
    BuildContext context,
    String invitationId,
    String jobId,
  ) async {
    final assistantId = FirebaseAuth.instance.currentUser!.uid;
    final batch = FirebaseFirestore.instance.batch();

    // 1. Update Invitation Status
    batch.update(
      FirebaseFirestore.instance.collection('invitations').doc(invitationId),
      {'status': 'accepted'},
    );

    // 2. Assign Assistant to Job and change Job Status
    batch.update(FirebaseFirestore.instance.collection('jobs').doc(jobId), {
      'assignedAssistantId': assistantId,
      'status': 'in_progress', // Job is now active
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
        ).showSnackBar(SnackBar(content: Text("Error accepting job: $e")));
      }
    }
  }

  /// Logic to decline the job
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
        // Listen to invitations collection filtered for this assistant
        stream: FirebaseFirestore.instance
            .collection('invitations')
            .where('assistantId', isEqualTo: currentUid)
            .where('status', isEqualTo: 'pending') // Only show active requests
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Center(child: Text("Error: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final invitations = snapshot.data!.docs;

          if (invitations.isEmpty) {
            return const Center(child: Text("No new invitations."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: invitations.length,
            itemBuilder: (context, index) {
              final invite = invitations[index];
              final inviteId = invite.id;
              final data = invite.data() as Map<String, dynamic>;
              final jobId = data['jobId'];

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
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => _declineJob(inviteId),
                            child: const Text(
                              "Decline",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () =>
                                _acceptJob(context, inviteId, jobId),
                            child: const Text("Accept Job"),
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
