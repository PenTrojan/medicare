import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_job_page.dart';
import 'job_details_page.dart';
import '../../models/job.dart';

class SeekerJobsPage extends StatelessWidget {
  const SeekerJobsPage({super.key});

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
                  color: Color(0xFF1E3A8A),
                ),
              ),
            ),
            Expanded(
              child: SeekerJobDetailsPage(
                filterStatuses: [JobStatus.completed],
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
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          title: const Text(
            "Job Management",
            style: TextStyle(
              color: Color(0xFF1E3A8A),
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.history, color: Color(0xFF1E3A8A)),
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
        body: const TabBarView(
          children: [
            AddJobPage(),
            SeekerJobDetailsPage(
              filterStatuses: [JobStatus.pending, JobStatus.matching],
            ),
            SeekerJobDetailsPage(filterStatuses: [JobStatus.assigned]),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestOverlay(BuildContext context) {
    return Container(
      color: const Color(0xFFF1F5F9),
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, size: 100, color: Color(0xFF1E3A8A)),
          const SizedBox(height: 24),
          const Text(
            "Sign In Required",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            "Please sign in with a Seeker account to post and manage jobs.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.blueGrey),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => _handleGuestRedirect(context),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text("Sign In / Register"),
          ),
        ],
      ),
    );
  }
}

