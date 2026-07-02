import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'local_paginated_list.dart';

class SeekersPage extends StatelessWidget {
  final VoidCallback? onDataChanged;

  const SeekersPage({Key? key, this.onDataChanged}) : super(key: key);

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
        body: TabBarView(
          children: [
            LocalPaginatedList(
              userType: 'seeker',
              onDataChanged: onDataChanged,
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'seeker')
                  .where('isSuspended', isEqualTo: false)
                  .snapshots(),
            ),
            LocalPaginatedList(
              userType: 'seeker',
              onDataChanged: onDataChanged,
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('isSuspended', isEqualTo: true)
                  .where('role', isEqualTo: 'seeker')
                  .snapshots(),
            ),
          ],
        ),
      ),
    );
  }
}

