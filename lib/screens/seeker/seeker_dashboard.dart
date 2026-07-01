import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medicare/themes/app_colors.dart';

// Reusable Shared Widgets
import 'package:medicare/widgets/profile_header_card.dart';
import 'package:medicare/widgets/section_header.dart';
import 'package:medicare/widgets/dashboard_stat_card.dart';
import 'seeker_find_list_view.dart';

class SeekerDash extends StatelessWidget {
  final Function(int mainTab, int? innerTab)? onTabRequested;

  const SeekerDash({super.key, this.onTabRequested});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final bool isAnonymous = user == null || user.isAnonymous;
    final String uid = user?.uid ?? "";

    // ==========================================
    // ANONYMOUS / GUEST VIEW
    // ==========================================
    if (isAnonymous) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: _buildAppBar(),
        body: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 80.0),
          children: [
            // 1. Guest Greeting Banner
            ProfileHeaderCard(
              title: "Hello, Guest Seeker",
              subtitle: "Sign in to request custom care assignments",
              profilePicUrl: null,
              statusColor: Colors.blueGrey,
              onTap: () {
                onTabRequested?.call(4, null); // Bounce to profile/auth tab
              },
            ),
            const SizedBox(height: 16),

            // 2. Embedded Directory Search Module (Uses your new HTTPS Function)
            _buildSearchSection(),
          ],
        ),
      );
    }

    // ==========================================
    // AUTHENTICATED USER VIEW
    // ==========================================
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading dashboard profile"));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          final seekerData = snapshot.data!.data() as Map<String, dynamic>;
          final String name = seekerData['name'] ?? "Care Seeker";

          return RefreshIndicator(
            onRefresh: () async {}, // Stream auto-updates reactively
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 80.0),
              children: [
                // 1. Hero Workspace Greetings Card
                ProfileHeaderCard(
                  title: "Hello, $name",
                  subtitle: "Manage and hire professional care assistants",
                  profilePicUrl: seekerData['profilePicUrl'],
                  statusColor: AppColors.primary,
                  onTap: () {
                    onTabRequested?.call(4, null);
                  },
                ),
                const SizedBox(height: 24),

                // 2. Metrics Block Section (Only visible to registered seekers)
                Text(
                  "Overview",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildActivePostingsCard(context, uid)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildOngoingCareCard(context, uid)),
                  ],
                ),
                const SizedBox(height: 24),

                // 3. Embedded Directory Search Module
                _buildSearchSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text("Medicare Workspace"),
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    );
  }

  Widget _buildSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: "Find Medical Assistants",
          actionText: "Reset View",
          onActionTap: () {},
        ),
        const SizedBox(height: 10),
        const SeekerFindListView(), // Dynamically hits Cloud Function endpoints safely
      ],
    );
  }

  // Live Aggregate Streams tracking posted Care Assignments
  Widget _buildActivePostingsCard(BuildContext context, String seekerId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('jobs')
          .where('seekerId', isEqualTo: seekerId)
          .snapshots(),
      builder: (context, snapshot) {
        final bool isLoading = !snapshot.hasData && !snapshot.hasError;
        int activeJobs = 0;

        if (snapshot.hasData) {
          activeJobs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final String status = data['status'] ?? '';
            return status == 'pending' ||
                status == 'matching' ||
                status == 'no_matches';
          }).length;
        }

        return DashboardStatCard(
          title: "Active Requests",
          valueText: "$activeJobs Postings",
          icon: Icons.assignment_outlined,
          iconColor: AppColors.primary,
          valueColor: AppColors.textMain,
          isLoading: isLoading,
          onTap: () {
            onTabRequested?.call(1, 1);
          },
        );
      },
    );
  }

  Widget _buildOngoingCareCard(BuildContext context, String seekerId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('jobs')
          .where('seekerId', isEqualTo: seekerId)
          .snapshots(),
      builder: (context, snapshot) {
        final bool isLoading = !snapshot.hasData && !snapshot.hasError;
        int ongoingJobs = 0;

        if (snapshot.hasData) {
          ongoingJobs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final String status = data['status'] ?? '';
            return status == 'assigned' || status == 'in_progress';
          }).length;
        }

        return DashboardStatCard(
          title: "Ongoing Care",
          valueText: "$ongoingJobs Running",
          icon: Icons.play_circle_fill,
          iconColor: AppColors.secondary,
          valueColor: AppColors.textMain,
          isLoading: isLoading,
          onTap: () {
            onTabRequested?.call(1, 2);
          },
        );
      },
    );
  }
}

