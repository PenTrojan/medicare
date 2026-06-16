//==================================================
//"Smart" Container
//This file handles the Firestore checks,
//the Cloud Functions,
//and the "Cancel" vs "Request" button logic.
//It uses the UI widget as its body.
//==================================================
//

import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'assistant_profile_ui.dart'; // Import the Dumb UI

class AssistantBookingSheet extends StatefulWidget {
  final Map<String, dynamic> profile;
  final String jobId;

  const AssistantBookingSheet({
    super.key,
    required this.profile,
    required this.jobId,
  });

  @override
  State<AssistantBookingSheet> createState() => _AssistantBookingSheetState();
}

class _AssistantBookingSheetState extends State<AssistantBookingSheet> {
  bool _isSubmitting = false;
  bool _alreadySent = false;
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    _checkExistingRequest();
  }

  Future<void> _checkExistingRequest() async {
    try {
      final inviteId = "${widget.jobId}_${widget.profile['assistantId']}";
      final doc = await FirebaseFirestore.instance
          .collection('invitations')
          .doc(inviteId)
          .get();
      if (mounted) {
        setState(() {
          final String? status = doc.data()?['status'];
          _alreadySent =
              doc.exists && status != 'declined' && status != 'cancelled';
          _isInitialLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isInitialLoading = false);
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
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close bottom sheet
              Navigator.pushNamed(context, '/register');
            },
            child: const Text("Sign In"),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCancelRequest() async {
    setState(() => _isSubmitting = true);

    try {
      // 1. Call the backend command
      await FirebaseFunctions.instance
          .httpsCallable('cancelAssistantBooking')
          .call({
            'jobId': widget.jobId,
            'assistantId': widget.profile['assistantId'],
          });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Request cancelled.")));
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Cancellation failed: ${e.message}")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("An unexpected error occurred.")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
        setState(() => _isSubmitting = false);
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. The Grab Handle (Adds that "Panel" vibe)
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 8),

          // 2. The Presenter (Dumb UI)
          // Constrain the height so it doesn't push the button off-screen
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AssistantProfileUI(profile: widget.profile),
            ),
          ),

          // 3. The Logic Button (Smart Action)
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: _buildActionButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    if (_isInitialLoading) return const CircularProgressIndicator();

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: _alreadySent
          ? OutlinedButton.icon(
              onPressed: _isSubmitting ? null : _handleCancelRequest,
              icon: const Icon(Icons.close, color: Colors.red),
              label: const Text("Cancel Request"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
            )
          : ElevatedButton(
              onPressed: _isSubmitting ? null : _handleBookingRequest,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Request Booking"),
            ),
    );
  }
}
