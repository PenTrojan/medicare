import 'package:flutter/material.dart';
import 'package:medicare/screens/admin/admin_dashboard.dart';
import 'package:medicare/screens/admin/assistants_page.dart';
import 'package:medicare/screens/admin/seekers_page.dart';
import 'package:medicare/screens/shared/profile_page.dart';
import 'package:medicare/screens/admin/admin_skills_page.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({Key? key}) : super(key: key);

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    const AdminDashboard(),
    const AssistantsPage(),
    const SeekersPage(),
    const AdminSkillsPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services),
            label: 'Assistants',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Seekers'),
          BottomNavigationBarItem(icon: Icon(Icons.psychology), label: 'Skills'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
