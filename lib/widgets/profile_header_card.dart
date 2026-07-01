// ===============================================
//         reusable widget to display name
//      and profile picture in the home screen
// ===============================================

import 'package:flutter/material.dart';
import 'package:medicare/themes/app_colors.dart';

class ProfileHeaderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? profilePicUrl;
  final Color statusColor;
  final VoidCallback onTap;

  const ProfileHeaderCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.profilePicUrl,
    required this.statusColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasProfilePic =
        profilePicUrl != null && profilePicUrl!.isNotEmpty;

    return Card(
      color: statusColor.withOpacity(0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withOpacity(0.2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: statusColor,
                backgroundImage: hasProfilePic
                    ? NetworkImage(profilePicUrl!)
                    : null,
                child: !hasProfilePic
                    ? const Icon(Icons.person, color: Colors.white, size: 28)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
