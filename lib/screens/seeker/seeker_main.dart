//====================================
//======== Bottom Nv Bar Logic =======
//====================================

import 'package:flutter/material.dart';

// Seeker-specific pages
import 'seeker_dashboard.dart';
import 'add_job_page.dart';
import 'job_details_page.dart';

// shared pages
import '../shared/messaging_page.dart';
import '../shared/profile_page.dart';

class SeekerMain extends StatefulWidget {
  const SeekerMain({super.key});

  @override
  State<SeekerMain> createState() => _SeekerMainState();
}

class _SeekerMainState extends State<SeekerMain> {
  int _selectedIndex = 0; // manages which page is the current page

  // Available Pages
  final List<Widget> _pages = [
    const SeekerDash(),
    const AddJobPage(),
    const SeekerJobDetailsPage(),
    const MessagingPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /** instead of if else using indexed stack keeps the other pages
	* in the background and preserves their state*/
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType
            .fixed, // Ensure icons and labels stays visible
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Add Job',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Status',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
