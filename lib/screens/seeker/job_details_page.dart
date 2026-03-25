import 'package:flutter/material.dart';

class SeekerJobDetailsPage extends StatelessWidget {
  const SeekerJobDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Active Jobs")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              "Finding your best match...",
              style: TextStyle(fontSize: 16),
            ),
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: LinearProgressIndicator(),
            ),
            // When matches exist, this will be replaced by a ListView of matched Assistants
          ],
        ),
      ),
    );
  }
}
