//====================================
//======== Bottom Nv Bar Logic =======
//====================================

import 'package:flutter/material.dart';
import '../../widgets/main_navigation_layout.dart';
import 'seeker_dashboard.dart';
import 'seeker_jobs_page.dart';
import '../shared/payments_page.dart';
import '../shared/messaging_page.dart';
import '../shared/profile_page.dart';

class SeekerMain extends StatelessWidget {
  const SeekerMain({super.key});

  @override
  Widget build(BuildContext context) {
    return MainNavigationLayout(
      items: [
        NavigationItemConfig(
          icon: Icons.home_rounded,
          label: 'Home',
          // Matches the dynamic layout shell pattern used in AssistantMain
          pageBuilder: (goToTab) => SeekerDash(
            onTabRequested: (mainTab, innerTab) => goToTab(mainTab, innerTab),
          ),
        ),
        NavigationItemConfig(
          icon: Icons.assignment_outlined,
          label: 'Jobs',
          pageBuilder: (goToTab) => const SeekerJobsPage(),
        ),
        NavigationItemConfig(
          icon: Icons.payments_outlined,
          label: 'Payments',
          pageBuilder: (goToTab) => const PaymentsPage(isSeeker: true),
        ),
        NavigationItemConfig(
          icon: Icons.message,
          label: 'Chat',
          pageBuilder: (goToTab) => const MessagingPage(),
        ),
        NavigationItemConfig(
          icon: Icons.person,
          label: 'Profile',
          pageBuilder: (goToTab) => const ProfilePage(),
        ),
      ],
    );
  }
}
