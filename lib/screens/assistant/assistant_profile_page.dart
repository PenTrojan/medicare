import 'package:flutter/material.dart';

class AssistantProfilePage extends StatelessWidget {
  final Map<String, dynamic> data;

  const AssistantProfilePage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final imageUrl = data['profilePicUrl'];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Assistant Profile"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 👤 Profile Image
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey[200],
              child: ClipOval(
                child: (imageUrl != null &&
                        imageUrl.toString().isNotEmpty)
                    ? Image.network(
                        imageUrl,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) {
                          return const Icon(Icons.person,
                              size: 50);
                        },
                      )
                    : const Icon(Icons.person, size: 50),
              ),
            ),

            const SizedBox(height: 16),

            // 📛 Name
            Text(
              data['name'] ?? '',
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            // 📄 Details
            _infoRow("Experience", data['experience']),
            _infoRow(
                "Daily Rate", "Rs ${data['dailyRate'] ?? '-'}"),
            _infoRow("Address", data['address']),
            _infoRow(
                "Rating", "${data['rating'] ?? '0'} ⭐"),

            const SizedBox(height: 20),

            // 📝 Bio
            if (data['bio'] != null)
              Text(
                data['bio'],
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            "$title: ",
            style:
                const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value?.toString() ?? '-'),
          ),
        ],
      ),
    );
  }
}