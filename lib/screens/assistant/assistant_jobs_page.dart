import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/job.dart';
import '../../widgets/job_list_view.dart';
import '../shared/job_details_page.dart'; // Holds AssistantJobPage
import 'invitations_page.dart';

class AssistantJobsPage extends StatelessWidget {
  final int initialTabIndex;
  const AssistantJobsPage({super.key, this.initialTabIndex = 0});

  void _showHistory(BuildContext context, String uid) {
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
                "Commitment History",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
            ),
            Expanded(
              child: _buildFilteredJobStream(
                uid: uid,
                targetStatuses: [JobStatus.completed, JobStatus.cancelled],
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
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please sign in to view commitments.")),
      );
    }

    return DefaultTabController(
      length: 2,
      initialIndex: initialTabIndex,
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
          centerTitle: false, // Matches seeker layout left-align
          actions: [
            IconButton(
              icon: const Icon(Icons.history, color: Color(0xFF1E3A8A)),
              onPressed: () => _showHistory(context, user.uid),
              tooltip: "View History",
            ),
          ],
          bottom: const TabBar(
            labelColor: Color(0xFF3B82F6),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF3B82F6),
            tabs: [
              Tab(text: "Invites", icon: Icon(Icons.mail_outline)),
              Tab(text: "Active", icon: Icon(Icons.play_circle_fill)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Replaces your old standalone bottom-nav page!
            const InvitationsPage(),

            // Tab 2: Currently running/assigned engagements
            _buildFilteredJobStream(
              uid: user.uid,
              targetStatuses: [JobStatus.assigned, JobStatus.in_progress],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilteredJobStream({
    required String uid,
    required List<JobStatus> targetStatuses,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('jobs')
          .where('assignedAssistantId', isEqualTo: uid)
          .where('status', whereIn: targetStatuses.map((e) => e.name).toList())
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final jobs = snapshot.data!.docs
            .map((doc) {
              try {
                return Job.fromFirestore(doc);
              } catch (e) {
                // Catch the fleeting map parsing error quietly in the background
                debugPrint("Fleeting matching state skipped: $e");
                return null;
              }
            })
            .whereType<
              Job
            >() // Filters out any null instances from parsing glitches
            .toList();
        return JobListView(
          jobs: jobs,
          onJobTap: (job) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    AssistantJobPage(job: job, isPendingInvitation: false),
              ),
            );
          },
        );
      },
    );
  }
}
