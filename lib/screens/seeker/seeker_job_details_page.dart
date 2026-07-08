import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../models/job.dart';
import '../../widgets/assistant_booking_sheet.dart';
import '../../widgets/assistant_profile_ui.dart';
import '../../widgets/job_specs_view.dart';
import 'dart:convert';

// =============================================================================
// 1. SEEKER VIEW (Specs + Match List)
// =============================================================================
class SeekerJobPage extends StatefulWidget {
  final Job job;
  const SeekerJobPage({super.key, required this.job});

  @override
  State<SeekerJobPage> createState() => _SeekerJobPageState();
}

class _SeekerJobPageState extends State<SeekerJobPage> {
  bool _isFetchingProfile = false;

  Future<void> _viewAssistantProfile(
    String assistantId,
    bool showRequestButton,
  ) async {
    setState(() => _isFetchingProfile = true);
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('getAssistantPublicProfile')
          .call({'assistantId': assistantId});

      if (!mounted) return;

      final String rawJson = jsonEncode(result.data);
      final Map<String, dynamic> profileData = jsonDecode(rawJson);
      profileData['assistantId'] = assistantId;

      if (showRequestButton) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) =>
              AssistantBookingSheet(profile: profileData, jobId: widget.job.id),
        );
      } else {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          builder: (_) => Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: AssistantProfileUI(profile: profileData),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isFetchingProfile = false);
    }
  }

  Future<void> _showCancelConfirmationDialog() async {
    // Determine the warning text based on the exact job status
    final bool isStarted = widget.job.status == JobStatus.in_progress;
    final String title = isStarted
        ? "Cancel Active Job?"
        : "Cancel Scheduled Job?";
    final String content = isStarted
        ? "This job has already started. Your refund will be pro-rated based on the hours the assistant has already worked. Are you sure you want to terminate this contract?"
        : "This job hasn't started yet. You will receive a full refund of your escrow balance. Are you sure you want to cancel?";

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title, style: const TextStyle(color: Colors.red)),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Go Back"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Confirm Cancellation"),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _executeCancellation();
    }
  }

  Future<void> _executeCancellation() async {
    // Show a loading overlay so the user can't double-tap
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('cancelJobEarly')
          .call({'jobId': widget.job.id});

      if (!mounted) return;
      Navigator.pop(context); // Remove loading indicator

      if (result.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Contract cancelled and escrow partitioned."),
          ),
        );
        // Pop the screen to return to the dashboard, forcing a fresh database read
        Navigator.pop(context);
      }
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Remove loading indicator
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to cancel: ${e.message}")));
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Remove loading indicator
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("An error occurred: $e")));
    }
  }

  Future<void> _retryJob() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Call the new backend retryJob Cloud Function
      final result = await FirebaseFunctions.instance
          .httpsCallable('retryJob')
          .call({'jobId': widget.job.id});

      if (!mounted) return;
      Navigator.pop(context); // Remove loading indicator

      if (result.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Job republished! Searching for new assistants..."),
          ),
        );
        Navigator.pop(context); // Go back to refresh the list
      }
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Failed to retry job")),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An unexpected error occurred: $e")),
      );
    }
  }

  Future<void> _showDeleteConfirmationDialog() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Job?", style: TextStyle(color: Colors.red)),
          content: const Text(
            "Are you sure you want to permanently delete this job request? This action cannot be undone.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _executeDelete();
    }
  }

  Future<void> _executeDelete() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Call the new backend deleteJob Cloud Function
      final result = await FirebaseFunctions.instance
          .httpsCallable('deleteJob')
          .call({'jobId': widget.job.id});

      if (!mounted) return;
      Navigator.pop(context); // Remove loading indicator

      if (result.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Job successfully deleted.")),
        );
        Navigator.pop(context); // Go back to the dashboard
      }
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      // This will display the exact error message from your Cloud Function
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Failed to delete job")),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An unexpected error occurred: $e")),
      );
    }
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon: const Icon(Icons.refresh),
          label: const Text("Search Again"),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: _retryJob,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.delete_outline),
          label: const Text("Delete Job"),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: _showDeleteConfirmationDialog,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // A seeker opening this page directly from their list dashboard should see billing
    // ONLY if an assistant has actually been assigned to it.
    final bool canShowBilling =
        widget.job.status == JobStatus.assigned ||
        widget.job.status == JobStatus.in_progress ||
        widget.job.status == JobStatus.completed;

    // Flag to check if cancellation is allowed
    final bool canCancel =
        widget.job.status == JobStatus.assigned ||
        widget.job.status == JobStatus.in_progress;

    // Flag to determine if we should show the contracted assistant details
    final bool showAssignedAssistant =
        widget.job.status == JobStatus.assigned ||
        widget.job.status == JobStatus.in_progress ||
        widget.job.status == JobStatus.completed ||
        widget.job.status == JobStatus.cancelled;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text("${widget.job.patientName}'s Case"),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment
                  .stretch, // Changed to stretch for full-width buttons
              children: [
                JobSpecsView(job: widget.job, showBilling: canShowBilling),
                const SizedBox(height: 32),

                // NEW: Show the Assigned Assistant Card
                // We also check that the ID is not null so we don't show a blank card
                // if a seeker cancels a job *before* an assistant is assigned.
                if (showAssignedAssistant &&
                    widget.job.assignedAssistantId != null) ...[
                  const Text(
                    "Assigned Assistant",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildAssignedAssistantCard(),
                  const SizedBox(height: 24),
                ],

                // Conditionally show Matches OR the Cancel Button
                if (widget.job.status == JobStatus.pending ||
                    widget.job.status == JobStatus.matching) ...[
                  const Text(
                    "Top Matched Assistants",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildMatchesSection(),

                  if (widget.job.status == JobStatus.matching)
                    _buildActionButtons(),
                ] else if (widget.job.status == JobStatus.no_matches) ...[
                  // NEW: Handle the no_matches state specifically
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: Center(
                      child: Text(
                        "No matches found.\nTry changing your job requirements.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.blueGrey,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                  _buildActionButtons(),
                ] else if (canCancel) ...[
                  // THE CANCEL BUTTON
                  OutlinedButton.icon(
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text("Terminate Contract Early"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: _showCancelConfirmationDialog,
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
          if (_isFetchingProfile)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildMatchesSection() {
    if (widget.job.topMatches.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Center(child: Text("No matches found yet.")),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.job.topMatches.length,
      itemBuilder: (context, index) {
        final assistant = widget.job.topMatches[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: assistant['profilePicUrl'] != null
                  ? NetworkImage(assistant['profilePicUrl'])
                  : null,
              child: assistant['profilePicUrl'] == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            title: Text(assistant['name'] ?? "Assistant"),
            subtitle: Text("Rs. ${assistant['dailyRate']}/day"),
            trailing: ElevatedButton(
              onPressed: () =>
                  _viewAssistantProfile(assistant['assistantId'], true),
              child: const Text("View"),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAssignedAssistantCard() {
    final assistantId = widget.job.assignedAssistantId;
    final assistantName =
        widget.job.assignedAssistantName ?? "Assigned Assistant";
    final assistantPic = widget.job.assignedAssistantPicUrl;

    if (assistantId == null) {
      return const SizedBox.shrink(); // Failsafe if ID is missing
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.green.shade300,
          width: 2,
        ), // Green border to highlight assignment
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.green.shade50,
          backgroundImage: assistantPic != null
              ? NetworkImage(assistantPic)
              : null,
          child: assistantPic == null
              ? const Icon(Icons.person, color: Colors.green)
              : null,
        ),
        title: Text(
          assistantName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 14),
            const SizedBox(width: 4),
            Text(
              "Contracted Assistant",
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => _viewAssistantProfile(assistantId, false),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text("View Profile"),
        ),
      ),
    );
  }
}
