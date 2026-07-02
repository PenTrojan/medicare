import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'local_paginated_list.dart';

class AssistantsPage extends StatelessWidget {
  final int initialTabIndex;
  final VoidCallback? onDataChanged;

  const AssistantsPage({
    Key? key,
    this.initialTabIndex = 0,
    this.onDataChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tabIndex = initialTabIndex.clamp(0, 2);

    return DefaultTabController(
      initialIndex: tabIndex,
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
        body: TabBarView(
          children: [
            LocalPaginatedList(
              userType: 'assistant',
              onDataChanged: onDataChanged,
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'assistant')
                  .where('isVerified', isEqualTo: false)
                  .where('isSuspended', isEqualTo: false)
                  .snapshots(),
            ),
            LocalPaginatedList(
              userType: 'assistant',
              onDataChanged: onDataChanged,
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'assistant')
                  .where('isVerified', isEqualTo: true)
                  .where('isSuspended', isEqualTo: false)
                  .snapshots(),
            ),
            LocalPaginatedList(
              userType: 'assistant',
              onDataChanged: onDataChanged,
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('isSuspended', isEqualTo: true)
                  .where('role', isEqualTo: 'assistant')
                  .snapshots(),
            ),
          ],
        ),
      ),
    );
  }
}
