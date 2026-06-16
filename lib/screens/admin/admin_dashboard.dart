import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/assistant.dart';
import '../../models/seeker.dart';
import '../../models/admin.dart';
import '../../services/dummy_data_service.dart';
import '../../services/admin_dashboard_service.dart';
import 'assistants_page.dart';
import 'seekers_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _verifiedAssistantsCount = 0;
  int _activeSeekersCount = 0;
  int _pendingVerificationsCount = 0;
  int _activeJobsCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserCounts();
  }

  Future<void> _loadUserCounts() async {
    try {
      final verifiedAssistants =
          await AdminDashboardService.getVerifiedAssistantsCount();
      final activeSeekers =
          await AdminDashboardService.getActiveSeekersCount();
      final pendingVerifications =
          await AdminDashboardService.getPendingVerificationsCount();
      final activeJobs = await AdminDashboardService.getActiveJobsCount();

      if (mounted) {
        setState(() {
          _verifiedAssistantsCount = verifiedAssistants;
          _activeSeekersCount = activeSeekers;
          _pendingVerificationsCount = pendingVerifications;
          _activeJobsCount = activeJobs;
          _isLoading = false;
        });
      }
    } catch (e) {
      print(e);
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
        title: const Text('Admin Dashboard'),
        // =================== Dummy data Button ==============================
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt),
            tooltip: "Seed Assistants",
            onPressed: () async {
              await DummyDataService.seedAssistants();
              await _loadUserCounts();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("50 Assistants Seeded!")),
                );
              }
            },
          ),
        ],

        // ===============================================
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- TOP METRICS ---
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Active Assistants',
                          _verifiedAssistantsCount.toString(),
                          Icons.medical_services,
                          Colors.blue,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AssistantsPage(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildStatCard(
                          'Total Active Seekers',
                          _activeSeekersCount.toString(),
                          Icons.people,
                          Colors.green,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const SeekersPage(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Active Jobs',
                          _activeJobsCount.toString(),
                          Icons.work,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildStatCard(
                          'Pending Verifications',
                          _pendingVerificationsCount.toString(),
                          Icons.pending_actions,
                          Colors.purple,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AssistantsPage(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),

            const SizedBox(height: 30),

            // --- RECENT JOBS SECTION ---
            const Text(
              "Live Activity: Recent Jobs",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            StreamBuilder<QuerySnapshot>(
              // Fetch only the 5 most recent jobs
              stream: FirebaseFirestore.instance
                  .collection('jobs')
                  .orderBy('createdAt', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Text("Waiting for new jobs...");
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text("No jobs posted recently."),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics:
                      const NeverScrollableScrollPhysics(), // Prevents scrolling conflicts
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data =
                        docs[index].data() as Map<String, dynamic>? ?? {};
                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[50],
                          child: const Icon(
                            Icons.work_outline,
                            color: Colors.blue,
                          ),
                        ),
                        title: Text(
                          data['patientName'] ?? 'Unknown Patient',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          data['medicalCondition'] ?? 'No condition listed',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Widget to build the cards safely ---
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Prevents bottom overflow!
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 12),
              FittedBox(
                // Shrinks text if it's too long
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

