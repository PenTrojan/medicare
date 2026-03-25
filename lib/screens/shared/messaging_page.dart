import 'package:flutter/material.dart';

class MessagingPage extends StatelessWidget {
  const MessagingPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Messages")),
      body: ListView.separated(
        itemCount: 5, // Replace with StreamBuilder of ChatRooms
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text("Chat with Assistant ${index + 1}"),
            subtitle: const Text("Latest message preview goes here..."),
            trailing: const Text("12:45 PM"),
            onTap: () {
              // Navigate to ChatDetailScreen
            },
          );
        },
      ),
    );
  }
}
