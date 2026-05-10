import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/job.dart';
import 'job_expanded.dart';

class SeekerJobDetailsPage extends StatefulWidget {
  const SeekerJobDetailsPage({super.key});

  @override
  State<SeekerJobDetailsPage> createState() => _SeekerJobDetailsPageState();
}

class _SeekerJobDetailsPageState extends State<SeekerJobDetailsPage> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  final int _documentLimit = 20;
  final List<DocumentSnapshot> _documents = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;

  @override
  void initState() {
    super.initState();
    _fetchJobs();
  }

  Future<void> _fetchJobs() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    try {
      // FIXED QUERY: Fetch jobs where seekerId matches current user
      Query query = FirebaseFirestore.instance
          .collection('jobs')
          .where('seekerId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(_documentLimit);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.length < _documentLimit) {
        _hasMore = false;
      }

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        setState(() {
          _documents.addAll(snapshot.docs);
        });
      }
    } catch (e) {
      debugPrint("Job Fetch Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Active Jobs")),
      body: _documents.isEmpty && !_isLoading
          ? const Center(child: Text("No active medical requests"))
          : ListView.builder(
              itemCount: _documents.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _documents.length) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: _fetchJobs,
                              child: const Text("See More"),
                            ),
                    ),
                  );
                }

                final job = Job.fromFirestore(_documents[index]);
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(job.patientName),
                    subtitle: Text("Status: ${job.status.name.toUpperCase()}"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => JobExpanded(job: job),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}