import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AssistantProfileView extends StatefulWidget {
  final Map<String, dynamic> profile;
  final String? jobId; // Non-null when coming from JobExpanded
  final String seekerId;

  const AssistantProfileView({
    super.key,
    required this.profile,
    this.jobId,
    required this.seekerId,
  });

  @override
  State<AssistantProfileView> createState() => _AssistantProfileViewState();
}

class _AssistantProfileViewState extends State<AssistantProfileView> {
  bool _isSubmitting = false;
  bool _alreadySent = false;
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    _checkExistingRequest();
  }

  Future<void> _checkExistingRequest() async {
    if (widget.jobId == null) {
      setState(() => _isInitialLoading = false);
      return;
    }

    try {
      final inviteId = "${widget.jobId}_${widget.profile['assistantId']}";
      final doc = await FirebaseFirestore.instance
          .collection('invitations')
          .doc(inviteId)
          .get();

      if (mounted) {
        setState(() {
          // It's considered "sent" if it exists and isn't declined
          _alreadySent = doc.exists && doc.data()?['status'] != 'declined';
          _isInitialLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isInitialLoading = false);
    }
  }

  Future<void> _handleCancelRequest() async {
    setState(() => _isSubmitting = true);

    try {
      final inviteId = "${widget.jobId}_${widget.profile['assistantId']}";

      // We update the status to 'cancelled'
      await FirebaseFirestore.instance
          .collection('invitations')
          .doc(inviteId)
          .update({'status': 'cancelled'});

      if (mounted) {
        Navigator.pop(context); // 👈 Close the modal on success
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Request cancelled.")));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to cancel request.")),
        );
      }
    }
  }

  /// Backend-driven booking logic
  Future<void> _handleBookingRequest() async {
    final user = FirebaseAuth.instance.currentUser;

    // 1. Auth Guard for Anonymous users
    if (user == null || user.isAnonymous) {
      _showAuthRequiredDialog();
      return;
    }

    // 2. We only allow booking if we have a specific Job Context (JobExpanded)
    if (widget.jobId == null) return;

    setState(() => _isSubmitting = true);

    try {
      // Calls the backend function we discussed
      await FirebaseFunctions.instance
          .httpsCallable('requestAssistantBooking')
          .call({
            'jobId': widget.jobId,
            'assistantId': widget.profile['assistantId'],
          });

      if (mounted) {
        Navigator.pop(context); // Close BottomSheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Booking request sent successfully!")),
        );
      }
    } on FirebaseFunctionsException catch (e) {
      String message = "Server Error: ${e.message}";
      if (e.code == 'already-exists') {
        message = "A request has already been sent to this assistant.";
        setState(() => _alreadySent = true);
      }
      if (mounted) {
        setState(() => _isSubmitting = false); // 👈 Ensure loader stops
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("An unexpected error occurred.")),
        );
      }
    }
  }

  void _showAuthRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sign In Required"),
        content: const Text(
          "You need a permanent account to book an assistant.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              Navigator.pushNamed(context, '/register');
            },
            child: const Text("Sign In"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final workingTimes = profile['workingTimes'] as Map<String, dynamic>? ?? {};

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: profile['profilePicUrl'] != null
                      ? NetworkImage(profile['profilePicUrl'])
                      : null,
                  child: profile['profilePicUrl'] == null
                      ? const Icon(Icons.person, size: 40)
                      : null,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile['name'] ?? 'Assistant',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${profile['experienceLevel']?.toString().toUpperCase()} Helper",
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        "Rs. ${profile['dailyRate']}/day",
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 40),
            _buildSectionTitle("Bio"),
            Text(
              profile['bio'] ?? "No bio available.",
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 20),
            _buildSectionTitle("Experience Details"),
            Text(
              profile['experienceDescription'] ?? "No details provided.",
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 20),
            _buildSectionTitle("Skills"),
            Wrap(
              spacing: 8,
              children: (profile['skills'] as List<dynamic>? ?? [])
                  .map(
                    (skill) => Chip(
                      label: Text(skill.toString()),
                      backgroundColor: Colors.blue[50],
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
            _buildSectionTitle("Weekly Availability"),
            ...workingTimes.entries.map((entry) {
              final times = entry.value as List<dynamic>;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      "${times[0]} - ${times[1]}",
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 30),

            // Button is ONLY visible if accessed from JobExpanded (jobId != null)
            if (widget.jobId != null)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: _isInitialLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _alreadySent
                    ? OutlinedButton.icon(
                        onPressed: _isSubmitting ? null : _handleCancelRequest,
                        icon: const Icon(Icons.close, color: Colors.red),
                        label: const Text(
                          "Cancel Request",
                          style: TextStyle(color: Colors.red),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: _isSubmitting ? null : _handleBookingRequest,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text("Request Booking"),
                      ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
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
}
