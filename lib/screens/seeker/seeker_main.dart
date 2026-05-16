//====================================
//======== Bottom Nv Bar Logic =======
//====================================

import 'package:flutter/material.dart';

// Seeker-specific pages
import 'seeker_dashboard.dart';
import 'seeker_jobs.dart';

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
    const SeekerJobsPage(),
    const MessagingPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /** * IndexedStack ensures that if a user is halfway through filling the 
       * 'Create Job' form in SeekerJobsPage and switches to 'Chat', 
       * their form data isn't lost when they switch back.
       */
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Find'),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            label: 'My Jobs',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
