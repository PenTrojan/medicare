import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/job.dart';
import 'job_expanded.dart'; // Import the details page
import '../../services/dummy_data_service.dart';

class SeekerJobDetailsPage extends StatefulWidget {
  const SeekerJobDetailsPage({super.key});

  @override
  State<SeekerJobDetailsPage> createState() => _SeekerJobDetailsPageState();
}

class _SeekerJobDetailsPageState extends State<SeekerJobDetailsPage> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  
  // Pagination variables
  final int _documentLimit = 20;
  List<DocumentSnapshot> _documents = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;

  @override
  void initState() {
    super.initState();
    _fetchJobs(); // Fetch the first 20 items on load
  }

  Future<void> _fetchJobs() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Build the query
      Query query = FirebaseFirestore.instance
          .collection('jobs') // Change to 'users' if you are querying the users collection instead
          .where('seekerId', isEqualTo: uid)
          // ADDED FILTER: This ensures only assistants are loaded. 
          // Change 'role' to match your actual database field (e.g., 'userType')
          .where('role', isEqualTo: 'assistant') 
          .orderBy('createdAt', descending: true)
          .limit(_documentLimit);

      // If we already have documents, start after the last one we fetched
      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.length < _documentLimit) {
        _hasMore = false; // No more documents to load after this batch
      }

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        _documents.addAll(snapshot.docs);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching data: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Active Jobs"),
        actions: [
          IconButton(
            icon: const Icon(Icons.factory_outlined),
            tooltip: "Seed Dummy Data",
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Seeding dummy jobs..."),
                  duration: Duration(seconds: 1),
                ),
              );

              await DummyDataService.seedJobs(uid);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Dummy Jobs Seeded!")),
                );
                // Refresh the list after seeding
                setState(() {
                  _documents.clear();
                  _lastDocument = null;
                  _hasMore = true;
                });
                _fetchJobs();
              }
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Show loading indicator for the initial fetch
    if (_documents.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show empty state if no data is found
    if (_documents.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              "No active medical requests",
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text("Tap the '+' button to find an assistant."),
          ],
        ),
      );
    }

    // List view with pagination
    return ListView.builder(
      itemCount: _documents.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        // If we reach the end of the list, show the "Load More" button
        if (index == _documents.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _fetchJobs,
                      child: const Text("Load More"),
                    ),
            ),
          );
        }

        // Map the document to your Job model
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
    );
  }
}