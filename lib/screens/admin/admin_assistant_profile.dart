import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final name = data['name'] ?? 'No Name';
          final photoUrl = data['photoUrl'] as String?;
          final isVerified = data['isVerified'] ?? false;
          final isSuspended = data['isSuspended'] ?? false;
          final nic = data['nic'] ?? 'N/A';
          final gender = data['gender'] ?? 'N/A';
          final age = data['age']?.toString() ?? 'N/A';
          final address = data['address'] ?? 'N/A';
          final bio = data['bio'] ?? 'N/A';
          final dailyRate = data['dailyRate']?.toString() ?? 'N/A';
          final experience = data['experience'] ?? 'N/A';
          final skills = (data['skills'] as List?)?.cast<String>() ?? [];

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 24),
                Center(
                  child: CircleAvatar(
                    radius: 48,
                    backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                        ? NetworkImage(photoUrl)
                        : null,
                    child: photoUrl == null || photoUrl.isEmpty
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
