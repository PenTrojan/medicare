import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/seeker.dart';
import 'admin_assistant_profile.dart';
import 'admin_seeker_profile.dart';

class LocalPaginatedList extends StatefulWidget {
  final Stream<QuerySnapshot> stream;
  final String userType;
  final VoidCallback? onDataChanged;

  const LocalPaginatedList({
    Key? key,
    required this.stream,
    required this.userType,
    this.onDataChanged,
  }) : super(key: key);

  @override
  State<LocalPaginatedList> createState() => _LocalPaginatedListState();
}

class _LocalPaginatedListState extends State<LocalPaginatedList> {
  int _currentLimit = 20;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _nameFromData(Map<String, dynamic> data) {
    final displayName = (data['displayName'] as String?)?.trim();
    final name = (data['name'] as String?)?.trim();
    return (displayName?.isNotEmpty == true ? displayName : name) ?? 'No Name';
  }

  String? _profileImageUrlFromData(Map<String, dynamic> data) {
    final url = (data['profileImageUrl'] as String?)?.trim();
    if (url != null && url.isNotEmpty) {
      return url;
    }

    final fallback = (data['profilePicUrl'] as String?)?.trim();
    if (fallback != null && fallback.isNotEmpty) {
      return fallback;
    }

    return null;
  }

  Future<void> _openProfile(BuildContext context, String uid) async {
    if (widget.userType == 'assistant') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AdminAssistantProfilePage(uid: uid)),
      );
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AdminSeekerProfilePage(uid: uid)),
      );
    }

    widget.onDataChanged?.call();
  }

  Widget _buildLeadingAvatar(String? profileImageUrl) {
    if (profileImageUrl == null) {
      return CircleAvatar(
        backgroundColor: Colors.deepPurple.shade50,
        child: Icon(Icons.person, color: Colors.deepPurple.shade300),
      );
    }

    return CircleAvatar(
      backgroundColor: Colors.deepPurple.shade50,
      child: ClipOval(
        child: SizedBox(
          width: 40,
          height: 40,
          child: Image.network(
            profileImageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) {
              return Icon(Icons.person, color: Colors.deepPurple.shade300);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildUserTile(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final name = _nameFromData(data);
    final profileImageUrl = _profileImageUrlFromData(data);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      color: Colors.deepPurple.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: widget.userType == 'seeker'
            ? (() {
                final seeker = Seeker.fromMap(doc.id, data);
                final seekerProfileImageUrl = seeker.profilePicUrl?.trim();
                final hasSeekerProfileImage =
                    seekerProfileImageUrl != null &&
                    seekerProfileImageUrl.isNotEmpty;

                return CircleAvatar(
                  backgroundColor: Colors.deepPurple.shade50,
                  child: hasSeekerProfileImage
                      ? ClipOval(
                          child: Image.network(
                            seekerProfileImageUrl,
                            fit: BoxFit.cover,
                            width: 40,
                            height: 40,
                            errorBuilder: (_, __, ___) {
                              return Icon(
                                Icons.person,
                                color: Colors.deepPurple.shade300,
                              );
                            },
                          ),
                        )
                      : Icon(Icons.person, color: Colors.deepPurple.shade300),
                );
              })()
            : _buildLeadingAvatar(profileImageUrl),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 17),
        ),
        onTap: () => _openProfile(context, doc.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value.trim().toLowerCase();
                _currentLimit = 20;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search by name',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                          _currentLimit = 20;
                        });
                      },
                    ),
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: widget.stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData) {
                return const Center(child: Text('No users found'));
              }

              final docs = snapshot.data!.docs;
              final filteredDocs = _searchQuery.isEmpty
                  ? docs
                  : docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>? ?? {};
                      final displayName =
                          ((data['displayName'] as String?) ?? '')
                              .toLowerCase();
                      final name = ((data['name'] as String?) ?? '')
                          .toLowerCase();
                      return displayName.contains(_searchQuery) ||
                          name.contains(_searchQuery);
                    }).toList();

              final displayedDocs = filteredDocs.take(_currentLimit).toList();

              if (displayedDocs.isEmpty) {
                return const Center(child: Text('No users found'));
              }

              return ListView.builder(
                itemCount: displayedDocs.length + 1,
                itemBuilder: (context, index) {
                  if (index == displayedDocs.length) {
                    if (filteredDocs.length > _currentLimit) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _currentLimit += 20;
                              });
                            },
                            child: const Text('Load More'),
                          ),
                        ),
                      );
                    }

                    return const SizedBox.shrink();
                  }

                  return _buildUserTile(context, displayedDocs[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
