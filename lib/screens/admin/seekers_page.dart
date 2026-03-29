import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'admin_seeker_profile.dart';
import '../../models/seeker.dart';

class SeekersPage extends StatelessWidget {
  const SeekersPage({Key? key}) : super(key: key);

  Future<void> _suspendSeeker(DocumentSnapshot doc) async {
    await doc.reference.update({'isSuspended': true});
  }

  Future<void> _deleteSeeker(DocumentSnapshot doc) async {
    await doc.reference.delete();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Seekers'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'Suspended'),
            ],
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'seeker')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Error loading seekers'));
            }

            final seekers = snapshot.data?.docs ?? [];
            if (seekers.isEmpty) {
              return const Center(child: Text('No seekers found'));
            }

            final active = <Seeker>[];
            final suspended = <Seeker>[];
            for (final doc in seekers) {
              final seeker = Seeker.fromMap(doc.id, doc.data() as Map<String, dynamic>);
              final isSuspended = (doc.data() as Map<String, dynamic>)['isSuspended'] ?? false;
              if (isSuspended == true) {
                suspended.add(seeker);
              } else {
                active.add(seeker);
              }
            }

            List<Widget> buildList(List<Seeker> list) {
              return [
                if (list.isEmpty)
                  const Center(child: Text('No seekers found'))
                else
                  ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final seeker = list[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          title: Text(seeker.displayName ?? 'No Name'),
                          subtitle: Text(seeker.email ?? 'No Email'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AdminSeekerProfilePage(uid: seeker.uid),
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
              children: [...buildList(active), ...buildList(suspended)],
            );
          },
        ),
      ),
    );
  }
}
