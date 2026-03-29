import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'admin_assistant_profile.dart';
import '../../models/assistant.dart';

class AssistantsPage extends StatelessWidget {
  const AssistantsPage({Key? key}) : super(key: key);

  Future<void> _updateAssistantStatus(
    DocumentSnapshot doc,
    String action,
  ) async {
    final docRef = doc.reference;
    if (action == 'verify') {
      await docRef.update({'isVerified': true});
    } else if (action == 'suspend') {
      await docRef.update({'isSuspended': true});
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Assistants'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Verified'),
              Tab(text: 'Suspended'),
            ],
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'assistant')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Error loading assistants'));
            }

            final assistants = snapshot.data?.docs ?? [];
            if (assistants.isEmpty) {
              return const Center(child: Text('No assistants found'));
            }

            final pending = <Assistant>[];
            final verified = <Assistant>[];
            final suspended = <Assistant>[];
            for (final doc in assistants) {
              final assistant = Assistant.fromMap(doc.id, doc.data() as Map<String, dynamic>);
              final isVerified = assistant.isVerified;
              final isSuspended = (doc.data() as Map<String, dynamic>)['isSuspended'] ?? false;
              if (!isVerified && !isSuspended) {
                pending.add(assistant);
              } else if (isVerified && !isSuspended) {
                verified.add(assistant);
              } else if (isSuspended == true) {
                suspended.add(assistant);
              }
            }

            List<Widget> buildList(List<Assistant> list) {
              return [
                if (list.isEmpty)
                  const Center(child: Text('No assistants found'))
                else
                  ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final assistant = list[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          title: Text(assistant.displayName ?? 'No Name'),
                          subtitle: Text('NIC: ${assistant.nic ?? 'No NIC'}\nVerified: ${assistant.isVerified ? 'Yes' : 'No'}'),
                          isThreeLine: true,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AdminAssistantProfilePage(uid: assistant.uid),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
              ];
            }

            return TabBarView(
              children: [
                ...buildList(pending),
                ...buildList(verified),
                ...buildList(suspended),
              ],
            );
          },
        ),
      ),
    );
  }
}
