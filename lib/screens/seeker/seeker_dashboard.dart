import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SeekerDash extends StatefulWidget {
  const SeekerDash({super.key});

  @override
  State<SeekerDash> createState() => _SeekerDashState();
}

class _SeekerDashState extends State<SeekerDash> {
  // =========================
  // PAGINATION
  // =========================
  final int _limit = 20;

  final List<DocumentSnapshot> _documents = [];

  DocumentSnapshot? _lastDocument;

  bool _isLoading = false;
  bool _hasMore = true;

  // =========================
  // SEARCH
  // =========================
  final TextEditingController _searchController =
      TextEditingController();

  String _searchText = '';

  List<DocumentSnapshot> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _loadAssistants();
  }

  // =========================
  // LOAD NORMAL ASSISTANTS
  // =========================
  Future<void> _loadAssistants() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      Query query = FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'assistant')
          .limit(_limit);

      // Pagination
      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final QuerySnapshot snapshot = await query.get();

      if (snapshot.docs.length < _limit) {
        _hasMore = false;
      }

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;

        _documents.addAll(snapshot.docs);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error loading assistants: $e"),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // =========================
  // GLOBAL SEARCH
  // =========================
  Future<void> _searchAssistants(String value) async {
    setState(() {
      _searchText = value;
    });

    // Clear search
    if (value.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
      });

      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'assistant')
          .get();

      final results = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;

        final name =
            (data['name'] ?? '').toString().toLowerCase();

        return name.contains(value.toLowerCase());
      }).toList();

      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Search error: $e"),
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // =========================
    // DISPLAY LIST
    // =========================
    final bool isSearching = _searchText.isNotEmpty;

    final List<DocumentSnapshot> displayList =
        isSearching ? _searchResults : _documents;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Find Medical Assistants',
          style: TextStyle(
            color: Color(0xFF1E3A8A),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            // =========================
            // SEARCH FIELD
            // =========================
            TextField(
              controller: _searchController,

              onChanged: _searchAssistants,

              decoration: InputDecoration(
                hintText: 'Search assistants...',
                prefixIcon: const Icon(Icons.search),

                suffixIcon: _searchText.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),

                        onPressed: () {
                          _searchController.clear();

                          setState(() {
                            _searchText = '';
                            _searchResults.clear();
                          });
                        },
                      )
                    : null,

                filled: true,
                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // =========================
            // LIST
            // =========================
            Expanded(
              child: displayList.isEmpty && _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : displayList.isEmpty
                      ? const Center(
                          child: Text('No assistants found'),
                        )
                      : ListView.builder(
                          itemCount:
                              displayList.length +
                                  (!isSearching && _hasMore
                                      ? 1
                                      : 0),

                          itemBuilder: (context, index) {
                            // =========================
                            // SEE MORE BUTTON
                            // =========================
                            if (!isSearching &&
                                index == displayList.length) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(
                                        vertical: 20),

                                child: Center(
                                  child: _isLoading
                                      ? const CircularProgressIndicator()
                                      : ElevatedButton(
                                          onPressed:
                                              _loadAssistants,

                                          child:
                                              const Text("See More"),
                                        ),
                                ),
                              );
                            }

                            final data =
                                displayList[index].data()
                                    as Map<String, dynamic>;

                            return _buildAssistantCard(data);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // CARD
  // =========================
  Widget _buildAssistantCard(Map<String, dynamic> data) {
    final imageUrl = data['profilePicUrl'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),

      child: ListTile(
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: Colors.grey[200],

          child: ClipOval(
            child: (imageUrl != null &&
                    imageUrl.toString().isNotEmpty)
                ? Image.network(
                    imageUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,

                    errorBuilder:
                        (context, error, stackTrace) {
                      return const Icon(Icons.person);
                    },
                  )
                : const Icon(Icons.person),
          ),
        ),

        title: Text(
          data['name'] ?? 'No Name',

          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        subtitle: Text(
          data['experience'] ?? 'No experience info',
        ),

        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
        ),
      ),
    );
  }
}