import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/job.dart';
import '../../widgets/job_list_view.dart';
import '../shared/job_details_page.dart';

class SeekerJobDetailsPage extends StatelessWidget {
  final List<JobStatus> filterStatuses;

  const SeekerJobDetailsPage({super.key, required this.filterStatuses});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Safety check
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('jobs')
          .where('seekerId', isEqualTo: user.uid)
          .where('status', whereIn: filterStatuses.map((e) => e.name).toList())
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

        // Convert the Firestore documents into Job model list
        final jobs = snapshot.data!.docs
            .map((doc) => Job.fromFirestore(doc))
            .toList();

        // USING THE REUSABLE WIDGET ====================================================
        return JobListView(
          jobs: jobs,
          onJobTap: (job) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SeekerJobPage(job: job)),
            );
          },
        );
      },
    );
  }
}
