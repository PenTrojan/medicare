import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/assistant.dart';
import '../../models/seeker.dart';
import 'admin_assistant_profile.dart';
import 'admin_seeker_profile.dart';

class PaginatedFirebaseList extends StatefulWidget {
  final Query query;
  final String userType;

  const PaginatedFirebaseList({
    Key? key,
    required this.query,
    required this.userType,
  }) : super(key: key);

  @override
  State<PaginatedFirebaseList> createState() => _PaginatedFirebaseListState();
}

class _PaginatedFirebaseListState extends State<PaginatedFirebaseList> {
  final List<DocumentSnapshot> _items = [];
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  bool _isLoading = false;
  String _searchText = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (_isLoading || !_hasMore) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Query q = widget.query;

      if (_searchText.isNotEmpty) {
        q = q
            .where('name', isGreaterThanOrEqualTo: _searchText)
            .where('name', isLessThan: _searchText + '\uf8ff');
      }

      q = q.limit(20);

      if (_lastDocument != null) {
        q = q.startAfterDocument(_lastDocument!);
      }

      final snapshot = await q.get();

      if (!mounted) {
        return;
      }

      setState(() {
        _items.addAll(snapshot.docs);
        if (snapshot.docs.isNotEmpty) {
          _lastDocument = snapshot.docs.last;
        }
        if (snapshot.docs.length < 20) {
          _hasMore = false;
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchText = value.trim();
      _items.clear();
      _lastDocument = null;
      _hasMore = true;
    });
    _fetchData();
  }

  Widget _buildLoadMore() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: TextButton(
          onPressed: _fetchData,
          child: const Text('Load More'),
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    if (widget.userType == 'assistant') {
      final assistant = Assistant.fromMap(doc.id, data);
      final profileImageUrl = assistant.profileImageUrl;
      final hasProfileImage =
          profileImageUrl != null && profileImageUrl.trim().isNotEmpty;

      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        elevation: 0,
        color: Colors.grey.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: CircleAvatar(
            backgroundImage: hasProfileImage
                ? NetworkImage(profileImageUrl!)
                : null,
            child: hasProfileImage
                ? null
                : const Icon(Icons.person, color: Colors.grey),
          ),
          title: Text(assistant.displayName ?? 'No Name'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AdminAssistantProfilePage(uid: assistant.uid),
              ),
            );
          },
        ),
      );
    }

    final seeker = Seeker.fromMap(doc.id, data);
    final profileImageUrl = seeker.profilePicUrl;
    final hasProfileImage =
        profileImageUrl != null && profileImageUrl.trim().isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage:
              hasProfileImage ? NetworkImage(profileImageUrl!) : null,
          child: hasProfileImage
              ? null
              : const Icon(Icons.person, color: Colors.grey),
        ),
        title: Text(seeker.displayName ?? 'No Name'),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminSeekerProfilePage(uid: seeker.uid),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = _items.length + (_hasMore ? 1 : 0);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search by name',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchText.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    ),
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: _items.isEmpty && _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _items.isEmpty
              ? const Center(child: Text('No users found'))
              : ListView.builder(
                  itemCount: itemCount,
                  itemBuilder: (context, index) {
                    if (index == _items.length) {
                      return _buildLoadMore();
                    }
                    return _buildUserCard(context, _items[index]);
                  },
                ),
        ),
      ],
    );
  }
}