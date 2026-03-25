import 'package:flutter/material.dart';
import 'package:medicare/screens/assistant/assistant_reg.dart';
import 'package:medicare/screens/shared/profile_page.dart';

class AssistantDash extends StatefulWidget {
  const AssistantDash({super.key}); //constructor

  final String title = "Assistant Dashboard";
  @override
  State<AssistantDash> createState() => _AssistantDashState();
}

class _AssistantDashState extends State<AssistantDash> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AssistantReg()),
                );
              },
              child: const Text('Register'),
            ),

            // go to profile button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              },
              child: const Text('Profile'),
            ), // go to profile button
          ],
        ),
      ),
    );
  }
}
