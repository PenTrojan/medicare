import 'package:flutter/material.dart';

// Admin-specific pages
//import 'admin_dashboard.dart';
//import '_page.dart';

// shared pages
import '../shared/profile_page.dart';

class AdminMain extends StatefulWidget {
  const AdminMain({super.key});

  @override
  State<AdminMain> createState() => _AdminMainState();
}

class _AdminMainState extends State<AdminMain> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    //const InvitationsPage(), // Tab 1: focusing on Invitations
    //const MyJobPage(), // Tab 2: The current active work
    //const MessagingPage(), // Tab 3: Communication
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
