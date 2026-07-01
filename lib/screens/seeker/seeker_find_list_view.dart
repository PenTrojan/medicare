import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../widgets/assistant_profile_ui.dart';

class SeekerFindListView extends StatefulWidget {
  const SeekerFindListView({super.key});

  @override
  State<SeekerFindListView> createState() => _SeekerFindListViewState();
}

class _SeekerFindListViewState extends State<SeekerFindListView> {
  final int _limit = 20;
  final List<Map<String, dynamic>> _assistants = [];
  int _currentOffset = 0;
  bool _isLoading = false;
  bool _hasMore = true;

  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  // ====================================================================
  // DISTINCT DEPLOYED FUNCTION ENDPOINTS
  // ====================================================================
  final String _getAssistantsUrl =
      'https://getpublicassistants-ggu4zm5tta-uc.a.run.app';

  final String _getProfileUrl =
      'https://us-central1-medicare-9d0de.cloudfunctions.net/getPublicAssistantProfile';

  @override
  void initState() {
    super.initState();
    _loadAssistants(isRefresh: true);
  }

  Future<void> _loadAssistants({bool isRefresh = false}) async {
    if (_isLoading || (!_hasMore && !isRefresh)) return;

    setState(() => _isLoading = true);

    if (isRefresh) {
      _currentOffset = 0;
      _assistants.clear();
      _hasMore = true;
    }

    try {
      final uri = Uri.parse(_getAssistantsUrl).replace(
        queryParameters: {
          'limit': _limit.toString(),
          'offset': _currentOffset.toString(),
          'search': _searchText,
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> fetchedList = data['assistants'] ?? [];

        if (mounted) {
          setState(() {
            _hasMore = data['hasMore'] ?? false;
            _assistants.addAll(
              fetchedList.map((e) => Map<String, dynamic>.from(e)),
            );
            _currentOffset += fetchedList.length;
          });
        }
      }
    } catch (e) {
      _showSnackBar("Error loading assistants: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAndShowFullProfile(String assistantId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final uri = Uri.parse(
        _getProfileUrl,
      ).replace(queryParameters: {'assistantId': assistantId});

      final response = await http.get(uri);

      if (mounted) Navigator.of(context).pop();

      if (response.statusCode == 200) {
        final Map<String, dynamic> fullProfile = json.decode(response.body);

        if (mounted) {
          _showProfileModal(fullProfile);
        }
      } else {
        throw Exception("Profile returned status code ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      _showSnackBar("Could not fetch detailed profile: $e");
    }
  }

  void _showProfileModal(Map<String, dynamic> fullProfileData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: AssistantProfileUI(profile: fullProfileData),
        ),
      ),
    );
  }

  void _onSearchChanged(String value) {
    setState(() => _searchText = value);
    _loadAssistants(isRefresh: true);
  }

  void _showSnackBar(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search assistants by name...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchText.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
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
        if (_assistants.isEmpty && _isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_assistants.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text('No assistants found'),
            ),
          )
        else ...[
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _assistants.length,
            itemBuilder: (context, index) {
              final item = _assistants[index];
              return GestureDetector(
                onTap: () => _fetchAndShowFullProfile(item['assistantId']),
                child: _buildAssistantCard(item),
              );
            },
          ),
          if (_hasMore)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : TextButton.icon(
                        onPressed: () => _loadAssistants(isRefresh: false),
                        icon: const Icon(Icons.add),
                        label: const Text("Load More"),
                      ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildAssistantCard(Map<String, dynamic> data) {
    final imageUrl = data['profilePicUrl'];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.grey[200],
          child: ClipOval(
            child: (imageUrl != null && imageUrl.toString().isNotEmpty)
                ? Image.network(
                    imageUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.person),
                  )
                : const Icon(Icons.person),
          ),
        ),
        title: Text(
          data['name'] ?? 'No Name',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(data['experience'] ?? 'No experience info'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      ),
    );
  }
}

