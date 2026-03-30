import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/assistant.dart';
import 'admin_assistant_verification.dart';

class AdminAssistantProfilePage extends StatefulWidget {
  final String uid;
  const AdminAssistantProfilePage({Key? key, required this.uid})
    : super(key: key);

  @override
  State<AdminAssistantProfilePage> createState() =>
      _AdminAssistantProfilePageState();
}

class _AdminAssistantProfilePageState extends State<AdminAssistantProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assistant Profile')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Assistant not found'));
          }
          final assistant = Assistant.fromFirestore(snapshot.data!);
          final name = assistant.displayName ?? 'No Name';
          final isVerified = assistant.isVerified;
          final isSuspended = assistant.isSuspended;
          final nic = assistant.nic ?? 'N/A';
          final gender = assistant.gender.name;
          final age = assistant.age?.toString() ?? 'N/A';
          final address = assistant.address ?? 'N/A';
          final bio = assistant.bio ?? 'N/A';
          final dailyRate = assistant.dailyRate?.toString() ?? 'N/A';
          final experience = assistant.experienceDescription ?? 'N/A';
          final skills = assistant.skills;

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 24),
                Center(
                  child: CircleAvatar(
                    radius: 48,
                    backgroundImage:
                        assistant.profileImageUrl != null &&
                            assistant.profileImageUrl!.isNotEmpty
                        ? NetworkImage(assistant.profileImageUrl!)
                        : null,
                    child:
                        assistant.profileImageUrl == null ||
                            assistant.profileImageUrl!.isEmpty
                        ? const Icon(Icons.person, size: 48)
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isVerified
                            ? Colors.orange
                            : Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(widget.uid)
                            .update({'isVerified': !isVerified});
                      },
                      icon: Icon(
                        isVerified
                            ? Icons.remove_circle_outline
                            : Icons.verified,
                      ),
                      label: Text(
                        isVerified ? 'Revoke Verification' : 'Verify Profile',
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSuspended ? Colors.grey : Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(widget.uid)
                            .update({'isSuspended': !isSuspended});
                      },
                      icon: Icon(isSuspended ? Icons.restore : Icons.block),
                      label: Text(
                        isSuspended ? 'Reactivate Account' : 'Suspend Account',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AdminAssistantVerificationPage(uid: widget.uid),
                          ),
                        );
                      },
                      icon: const Icon(Icons.assignment_ind),
                      label: const Text('View Verification Details'),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(title: const Text('NIC'), subtitle: Text(nic)),
                ListTile(title: const Text('Gender'), subtitle: Text(gender)),
                ListTile(title: const Text('Age'), subtitle: Text(age)),
                ListTile(title: const Text('Address'), subtitle: Text(address)),
                ListTile(title: const Text('Bio'), subtitle: Text(bio)),
                ListTile(
                  title: const Text('Daily Rate'),
                  subtitle: Text(dailyRate),
                ),
                ListTile(
                  title: const Text('Experience'),
                  subtitle: Text(experience),
                ),
                ListTile(
                  title: const Text('Skills'),
                  subtitle: skills.isEmpty
                      ? const Text('None')
                      : Wrap(
                          spacing: 8,
                          children: skills
                              .map((s) => Chip(label: Text(s)))
                              .toList(),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
