import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_job_page.dart';
import 'seeker_job_list_stream_view.dart';
import '../../models/job.dart';
import '../../themes/app_colors.dart';

class SeekerJobsPage extends StatelessWidget {
  final int initialTabIndex;

  const SeekerJobsPage({super.key, this.initialTabIndex = 0});

  Future<void> _handleGuestRedirect(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _showHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                "Care History",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
            ),
            Expanded(
              child: SeekerJobDetailsPage(
                filterStatuses: [JobStatus.completed, JobStatus.cancelled],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.isAnonymous) {
      return _buildGuestOverlay(context);
    }

    return DefaultTabController(
      length: 3,
      initialIndex: initialTabIndex,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          title: const Text(
            "Job Management",
            style: TextStyle(
              color: AppColors.textMain,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.history, color: AppColors.textSecondary),
              onPressed: () => _showHistory(context),
              tooltip: "View History",
            ),
          ],
          bottom: const TabBar(
            labelColor: Color(0xFF3B82F6),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF3B82F6),
            tabs: [
              Tab(text: "New", icon: Icon(Icons.add_task)),
              Tab(text: "Pending", icon: Icon(Icons.hourglass_empty)),
              Tab(text: "Ongoing", icon: Icon(Icons.play_circle_fill)),
            ],
          ),
        ),
        body: SafeArea(
          bottom:
              true, // Ensures it leaves room above the bottom navigation bar
          child: const TabBarView(
            children: [
              AddJobPage(),
              SeekerJobDetailsPage(
                filterStatuses: [
                  JobStatus.pending,
                  JobStatus.matching,
                  JobStatus.no_matches,
                ],
              ),
              SeekerJobDetailsPage(
                filterStatuses: [JobStatus.assigned, JobStatus.in_progress],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuestOverlay(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          "Job Workspace",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Styled Background Circle Context for Icon Presentation
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_person_outlined,
                  size: 80,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                "Sign In Required",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Please register or authenticate with an authorized Seeker profile "
                "to post standard or recurring care assignments.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () => _handleGuestRedirect(context),
                icon: const Icon(Icons.login_rounded),
                label: const Text(
                  "Sign In / Register",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
