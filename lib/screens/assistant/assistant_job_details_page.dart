import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../models/job.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/job_specs_view.dart';

// =============================================================================
// 2. ASSISTANT VIEW (Specs + Conditional Actions)
// =============================================================================
class AssistantJobPage extends StatelessWidget {
  final Job job;
  final bool isPendingInvitation;

  const AssistantJobPage({
    super.key,
    required this.job,
    this.isPendingInvitation = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Assignment Details"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        // If it's a pending invitation, hide billing (isPendingInvitation = true -> showBilling = false)
        child: JobSpecsView(job: job, showBilling: !isPendingInvitation),
      ),
      bottomNavigationBar: isPendingInvitation
          ? _buildInvitationActions(context)
          : null,
    );
  }

  Future<void> _handleInvitationResponse(
    BuildContext context,
    String action,
  ) async {
    // Show loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final assistantId = FirebaseAuth.instance.currentUser!.uid;

      // Call the Cloud Function in invitation_lifecycle.ts
      await FirebaseFunctions.instance
          .httpsCallable(
            action == 'accept' ? 'acceptInvitation' : 'declineInvitation',
          )
          .call({'jobId': job.id, 'assistantId': assistantId});

      if (context.mounted) {
        Navigator.pop(context); // Remove loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Job ${action}ed successfully!")),
        );
        Navigator.pop(context); // Return to previous list page
      }
    } on FirebaseFunctionsException catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Remove loading indicator
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${e.message}")));
      }
    }
  }

  Widget _buildInvitationActions(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _handleInvitationResponse(context, 'decline'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                child: const Text("Decline"),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _handleInvitationResponse(context, 'accept'),
                child: const Text("Accept Job"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
