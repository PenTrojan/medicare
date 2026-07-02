import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medicare/themes/app_colors.dart';

// Your Reusable Component Imports
import 'package:medicare/widgets/profile_header_card.dart';
import 'package:medicare/widgets/section_header.dart';
import 'package:medicare/widgets/dashboard_stat_card.dart';
import 'package:medicare/screens/shared/profile_page.dart';
import 'package:medicare/screens/assistant/assistant_jobs_page.dart';

class AssistantDash extends StatelessWidget {
  final Function(int tabIndex, int? innerTabIndex)? onTabRequested;

  const AssistantDash({super.key, this.onTabRequested});

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      appBar: AppBar(title: const Text("Medicare")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading workspace profile"));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          final assistantData = snapshot.data!.data() as Map<String, dynamic>;
          final bool isVerified = assistantData['isVerified'] ?? false;
          final String name = assistantData['name'] ?? "Medical Professional";

          return RefreshIndicator(
            onRefresh: () async =>
                {}, // Handled automatically by Firestore stream
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              children: [
                // 1. Welcome Card Banner (Reusable profile component)
                ProfileHeaderCard(
                  title: "Hello, $name",
                  subtitle: isVerified
                      ? "Verified Assistant"
                      : "Pending Verification Review",
                  profilePicUrl: assistantData['profilePicUrl'],
                  statusColor: isVerified
                      ? AppColors.primary
                      : Colors.amber.shade800,
                  onTap: () {
                    if (onTabRequested != null) {
                      onTabRequested!(4, null);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // 2. Main Dashboard Metrics Section
                if (!isVerified)
                  _buildVerificationCTA(context)
                else ...[
                  Text(
                    "Overview",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildActiveStatusHub(context, assistantData, uid),
                  const SizedBox(height: 24),

                  // 3. Shift Bookings Queue Section
                  SectionHeader(
                    title: "Upcoming Scheduled Care",
                    onActionTap:
                        () {}, // Navigate to full roster list schedule layer
                  ),
                  const SizedBox(height: 10),
                  _buildActiveShiftsQueue(uid),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildVerificationCTA(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.grey.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Icon(
              Icons.lock_clock_outlined,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            const Text(
              "Account Under Review",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Your medical credentials are being verified by our administrators. You will access shifts once approved.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveStatusHub(
    BuildContext context,
    Map<String, dynamic> data,
    String assistantId,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Live Radar Availability Master Switch
        Card(
          color: AppColors.primary.withOpacity(0.05),
          child: ListTile(
            leading: const Icon(Icons.radar, color: AppColors.primary),
            title: const Text(
              "Matching Radar Active",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: const Text(
              "Seekers can find you for immediate shifts.",
              style: TextStyle(fontSize: 12),
            ),
            trailing: Switch.adaptive(
              value: data['isAvailable'] ?? true,
              activeColor: AppColors.primary,
              onChanged: (val) {
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(assistantId)
                    .update({'isAvailable': val});
              },
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Stream Metrics rendering into Generic Dashboard Stat Blocks
        Row(
          children: [
            Expanded(child: _buildNewOffersCard(context, assistantId)),
            const SizedBox(width: 12),
            Expanded(child: _buildTodaysWorkCard(context, assistantId)),
          ],
        ),
      ],
    );
  }

  Widget _buildNewOffersCard(BuildContext context, String assistantId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(assistantId)
          .collection('invitations')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        final bool isLoading = !snapshot.hasData && !snapshot.hasError;
        final int offerCount = snapshot.hasData
            ? snapshot.data!.docs.length
            : 0;

        return DashboardStatCard(
          title: "New Offers",
          valueText: "$offerCount pending",
          icon: Icons.mail_outline,
          iconColor: offerCount > 0
              ? Colors.amber.shade700
              : AppColors.textSecondary,
          valueColor: offerCount > 0
              ? Colors.amber.shade900
              : AppColors.textMain,
          isLoading: isLoading,
          onTap: () {
            if (onTabRequested != null) {
              // Switch to index 1 (AssistantJobsPage) and target inner tab 0 (Invites)
              onTabRequested!(1, 0);
            }
          },
        );
      },
    );
  }

  Widget _buildTodaysWorkCard(BuildContext context, String assistantId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(assistantId)
          .collection('bookings')
          .where(
            'startDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .snapshots(),
      builder: (context, snapshot) {
        final bool isLoading = !snapshot.hasData && !snapshot.hasError;
        int activeShiftsToday = 0;

        if (snapshot.hasData) {
          activeShiftsToday = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return (data['status'] ?? '') != 'cancelled';
          }).length;
        }

        return DashboardStatCard(
          title: "Today's Work",
          valueText:
              "$activeShiftsToday Shift${activeShiftsToday == 1 ? '' : 's'}",
          icon: Icons.today,
          iconColor: AppColors.secondary,
          valueColor: AppColors.textMain,
          isLoading: isLoading,
          onTap: () {
            if (onTabRequested != null) {
              // Switch to index 1 (AssistantJobsPage) and target inner tab 1 (Active)
              onTabRequested!(1, 1);
            }
          },
        );
      },
    );
  }

  Widget _buildActiveShiftsQueue(String assistantId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(assistantId)
          .collection('bookings')
          .orderBy('startDate', descending: false)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        // 1. Add this error check first!
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Error loading schedules: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }
        // 2. This will now only handle the actual loading state
        if (!snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        final bookings = snapshot.data!.docs;
        if (bookings.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 36,
                    color: AppColors.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "No active schedules booked.",
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: bookings.map((doc) {
            final booking = doc.data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.medical_services_outlined,
                    color: AppColors.primary,
                  ),
                ),
                title: Text(
                  booking['seekerName'] ?? "Patient Care Assignment",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  "Rate: LKR ${booking['dailyRate']}/day",
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                ),
                onTap: () {},
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
