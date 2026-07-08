import 'package:flutter/material.dart';
import '../../models/job.dart';
import 'package:intl/intl.dart'; // Add intl to pubspec.yaml for date formatting
import '../screens/shared/billing_details_page.dart';
import '../screens/seeker/seeker_job_details_page.dart';

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
                "View Bill",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              subtitle: const Text(
                "Contract pricing, fees, and clearance status.",
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
