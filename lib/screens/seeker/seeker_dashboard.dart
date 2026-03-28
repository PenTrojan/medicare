import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'assistant_profile_page.dart';

class SeekerDash extends StatefulWidget {
  const SeekerDash({super.key});

  @override
  State<SeekerDash> createState() => _SeekerDashState();
}

class _SeekerDashState extends State<SeekerDash> {
  @override
  Widget build(BuildContext context) {
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
            // 🔍 Search (UI only)
            TextField(
              decoration: InputDecoration(
                hintText: 'Search assistants...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 📋 Assistant List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('role', isEqualTo: 'assistant')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return const Center(
                        child: Text('Error loading assistants'));
                  }

                  if (!snapshot.hasData ||
                      snapshot.data!.docs.isEmpty) {
                    return const Center(
                        child: Text('No assistants found'));
                  }

                  final assistants = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: assistants.length,
                    itemBuilder: (context, index) {
                      final data = assistants[index].data()
                          as Map<String, dynamic>;

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AssistantProfilePage(data: data),
                            ),
                          );
                        },
                        child: _buildAssistantCard(data),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🧑 Assistant Card
  Widget _buildAssistantCard(Map<String, dynamic> data) {
    final imageUrl = data['profilePicUrl'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
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
          style:
              const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          data['experience'] ?? 'No experience info',
        ),
        trailing:
            const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}