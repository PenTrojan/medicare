import 'package:flutter/material.dart';
import '../../widgets/main_navigation_layout.dart';
import 'assistant_dashboard.dart';
import 'assistant_jobs_page.dart';
import '../shared/payments_page.dart';
import '../shared/messaging_page.dart';
import '../shared/profile_page.dart';

class AssistantMain extends StatelessWidget {
  const AssistantMain({super.key});

  @override
  Widget build(BuildContext context) {
    return MainNavigationLayout(
      items: [
        NavigationItemConfig(
          icon: Icons.home_rounded,
          label: 'Home',
          // Receives the public callback function directly from the parent layout shell
          pageBuilder: (goToTab) => AssistantDash(
            onTabRequested: (mainTab, innerTab) => goToTab(mainTab, innerTab),
          ),
        ),
        NavigationItemConfig(
          icon: Icons.assignment_outlined,
          label: 'Jobs',
          pageBuilder: (goToTab) => const AssistantJobsPage(),
        ),
        NavigationItemConfig(
          icon: Icons.payments_outlined,
          label: 'Earnings',
          pageBuilder: (goToTab) => const PaymentsPage(isSeeker: false),
        ),
        NavigationItemConfig(
          icon: Icons.chat,
          label: 'Messages',
          pageBuilder: (goToTab) => const MessagingPage(isSeeker: false),
        ),
        NavigationItemConfig(
          icon: Icons.account_circle,
          label: 'Profile',
          pageBuilder: (goToTab) => const ProfilePage(),
        ),
      ],
    );
  }
}
