import 'package:flutter/material.dart';
import 'package:medicare/screens/shared/profile_page.dart';
import 'package:medicare/screens/assistant/assistant_reg.dart';

class SeekerDash extends StatefulWidget {
  const SeekerDash({super.key}); //constructor

  final String title = "Seeker Dashboard";
  @override
  State<SeekerDash> createState() => _SeekerDashState();
}

class _SeekerDashState extends State<SeekerDash> {
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
            ),
          ],
        ),
      ),
    );
  }
}
