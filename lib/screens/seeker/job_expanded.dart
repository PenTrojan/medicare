import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../models/job.dart';
import '../../widgets/assistant_profile_view.dart';
import 'dart:convert';

class JobExpanded extends StatefulWidget {
  final Job job;
  const JobExpanded({super.key, required this.job});

  @override
  State<JobExpanded> createState() => _JobExpandedState();
}

class _JobExpandedState extends State<JobExpanded> {
  bool _isFetchingProfile = false;

  /// Calls the Cloud Function to get detailed profile information
  Future<void> _viewAssistantProfile(String assistantId) async {
    setState(() => _isFetchingProfile = true);

    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('getAssistantPublicProfile')
          .call({'assistantId': assistantId});

      if (!mounted) return;

      // Show the reusable profile widget in a bottom sheet
      final String rawJson = jsonEncode(result.data);
      final Map<String, dynamic> profileData = jsonDecode(rawJson);

      _showProfileModal(profileData);
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${e.message}")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("An unexpected error occurred")),
        );
      }
    } finally {
      if (mounted) setState(() => _isFetchingProfile = false);
    }
  }

  /// Displays the reusable AssistantProfileView widget
  void _showProfileModal(Map<String, dynamic> profileData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AssistantProfileView(profile: profileData),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.job.patientName}'s Case"),
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader("Patient Information"),
                _buildPatientDetailsCard(),
                const SizedBox(height: 30),
                _buildSectionHeader("Top Matched Assistants"),
                const SizedBox(height: 10),
                _buildMatchesSection(),
              ],
            ),
          ),
          // Global loader overlay when fetching profile details
          if (_isFetchingProfile)
            Container(
              color: Colors.black45,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPatientDetailsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDetailRow(Icons.person, "Name", widget.job.patientName),
            _buildDetailRow(
              Icons.cake,
              "Age",
              "${widget.job.patientAge} years",
            ),
            _buildDetailRow(
              Icons.medical_information,
              "Condition",
              widget.job.patientCondition,
            ),
            _buildDetailRow(Icons.location_on, "Address", widget.job.address),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchesSection() {
    if (widget.job.topMatches.isEmpty) {
      return _buildMatchingLoader();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.job.topMatches.length,
      itemBuilder: (context, index) {
        final assistant = widget.job.topMatches[index];
        return _buildAssistantMiniCard(assistant);
      },
    );
  }

  Widget _buildAssistantMiniCard(Map<String, dynamic> assistant) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: Colors.blue[50],
          backgroundImage: assistant['profilePicUrl'] != null
              ? NetworkImage(assistant['profilePicUrl'])
              : null,
          child: assistant['profilePicUrl'] == null
              ? const Icon(Icons.person, color: Colors.blue)
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                assistant['name'] ?? "Assistant",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            _buildExperienceBadge(assistant['experienceLevel']),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                Text(" ${assistant['distance'].toStringAsFixed(1)} km away"),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "Rs. ${assistant['dailyRate']}/day",
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => _viewAssistantProfile(assistant['assistantId']),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text("View Profile"),
        ),
      ),
    );
  }

  Widget _buildExperienceBadge(String? level) {
    if (level == null || level.isEmpty || level == "unspecified") {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue[900],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        level.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey,
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue[700]),
          const SizedBox(width: 12),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchingLoader() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            "Searching for nearby assistants...",
            style: TextStyle(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
