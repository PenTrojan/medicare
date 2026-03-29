import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminSeekerProfilePage extends StatefulWidget {
  final String uid;
  const AdminSeekerProfilePage({Key? key, required this.uid}) : super(key: key);

  @override
  State<AdminSeekerProfilePage> createState() => _AdminSeekerProfilePageState();
}

class _AdminSeekerProfilePageState extends State<AdminSeekerProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seeker Profile')),
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
            return const Center(child: Text('Seeker not found'));
          }
          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final name = data['name'] ?? 'No Name';
          final photoUrl = data['photoUrl'] as String?;
          final isSuspended = data['isSuspended'] ?? false;
          final email = data['email'] ?? 'N/A';

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
                const SizedBox(height: 20),
                ListTile(title: const Text('Email'), subtitle: Text(email)),
              ],
            ),
          );
        },
      ),
    );
  }
}
