import 'package:flutter/material.dart';

// Seeker-specific pages
import 'assistant_dashboard.dart';
import 'invitations_page.dart';
//import '_page.dart';

// shared pages
import '../shared/messaging_page.dart';
import '../shared/profile_page.dart';

class AssistantMain extends StatefulWidget {
  const AssistantMain({super.key});

  @override
  State<AssistantMain> createState() => _AssistantMainState();
}

class _AssistantMainState extends State<AssistantMain> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const InvitationsPage(), // Tab 1: focusing on Invitations
    //const MyJobPage(), // Tab 2: The current active work
    const MessagingPage(), // Tab 3: Communication
    const ProfilePage(), // Tab 4: Self-management
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.mail_outline),
            label: 'Invitations',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services),
            label: 'Active Job',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Messages'),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
