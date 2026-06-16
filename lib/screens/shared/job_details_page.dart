import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../models/job.dart';
import '../../widgets/assistant_booking_sheet.dart';
import 'billing_details_page.dart';
import 'dart:convert';
import 'package:intl/intl.dart'; // Add intl to pubspec.yaml for date formatting
import 'package:firebase_auth/firebase_auth.dart';

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

  Future<void> _viewAssistantProfile(String assistantId) async {
    setState(() => _isFetchingProfile = true);
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('getAssistantPublicProfile')
          .call({'assistantId': assistantId});

      if (!mounted) return;

      final String rawJson = jsonEncode(result.data);
      final Map<String, dynamic> profileData = jsonDecode(rawJson);
      profileData['assistantId'] = assistantId;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) =>
            AssistantBookingSheet(profile: profileData, jobId: widget.job.id),
      );
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

  @override
  Widget build(BuildContext context) {
    // A seeker opening this page directly from their list dashboard should see billing
    // ONLY if an assistant has actually been assigned to it.
    final bool canShowBilling =
        widget.job.status == JobStatus.assigned ||
        widget.job.status == JobStatus.completed;
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                JobSpecsView(job: widget.job, showBilling: canShowBilling),
                const SizedBox(height: 32),
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
              onPressed: () => _viewAssistantProfile(assistant['assistantId']),
              child: const Text("View"),
            ),
          ),
        );
      },
    );
  }
}

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

// =============================================================================
// 3. SHARED ENGINE (Formatted for your Job Model)
// =============================================================================
class JobSpecsView extends StatelessWidget {
  final Job job;
  final bool showBilling; // visibility flag.
  const JobSpecsView({
    super.key,
    required this.job,
    this.showBilling = false,
  }); // default showbilling to false

  @override
  Widget build(BuildContext context) {
    // Formatting Helpers
    final df = DateFormat('MMM dd, yyyy');
    final dateRange = "${df.format(job.startDate)} - ${df.format(job.endDate)}";
    final skills = job.requiredSkills.isEmpty
        ? "None"
        : job.requiredSkills.join(", ");

    // Formatting workingTimes (e.g., "Mon: 08:00-17:00")
    String hoursSummary = job.workingTimes.entries
        .map((e) => "${e.key}: ${e.value.join(', ')}")
        .join("\n");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader("Patient Information"),
        _infoCard([
          _infoRow(Icons.person, "Name", job.patientName),
          _infoRow(Icons.cake, "Age", "${job.patientAge} years"),
          _infoRow(
            Icons.wc,
            "Preferred Gender",
            job.preferredGender.name.toUpperCase(),
          ),
          _infoRow(Icons.healing, "Condition", job.patientCondition),
          _infoRow(Icons.location_on, "Address", job.address),
        ]),
        const SizedBox(height: 24),
        _sectionHeader("Care Requirements & Schedule"),
        _infoCard([
          _infoRow(Icons.psychology, "Required Skills", skills),
          _infoRow(Icons.calendar_today, "Duration", dateRange),
          _infoRow(Icons.access_time, "Working Hours", hoursSummary),
          _infoRow(
            Icons.payments,
            "Max Daily Rate",
            "Rs. ${job.maxDailyRate}/day",
          ),
        ]),

        // =================== BILLING ===================================
        if (showBilling) ...[
          const SizedBox(height: 24),
          _sectionHeader("Financial Account Ledger"),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFEFF6FF),
                child: Icon(
                  Icons.receipt_long_outlined,
                  color: Color(0xFF3B82F6),
                ),
              ),
              title: const Text(
                "View Invoice & Escrow",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              subtitle: const Text(
                "Track contract pricing, fees, and clearance status.",
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.grey,
              ),
              onTap: () {
                // Look up the widget tree context to see which parent page is housing this view
                final isSeekerProfile =
                    context.findAncestorWidgetOfExactType<SeekerJobPage>() !=
                    null;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BillingDetailsPage(
                      jobId: job.id,
                      isSeeker: isSeekerProfile,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey,
        ),
      ),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: children),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF3B82F6)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
