import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import 'package:medicare/models/app_user.dart';
import 'package:medicare/models/assistant.dart';
import 'package:medicare/models/seeker.dart';
import 'package:medicare/services/auth_service.dart';
import 'package:medicare/services/image_upload_service.dart';
import 'package:medicare/themes/app_colors.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Not logged in")));
    }

    return StreamBuilder<AppUser?>(
      stream: AuthService().appUserStream(user),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final appUser = snapshot.data;
        if (appUser == null) {
          return const Scaffold(
            body: Center(child: Text("User profile not found")),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              "Profile",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: AppColors.textMain,
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),

                // Profile Picture & Name Header
                _buildProfileHeader(appUser, user.uid, context),

                const SizedBox(height: 24),

                // Conditional Layout Rendering for Specific Roles
                if (appUser is Assistant)
                  _buildAssistantDetails(appUser, user.uid, context),
                if (appUser is Seeker)
                  _buildSeekerDetails(appUser, user.uid, context),

                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 12.0,
                  ),
                  child: Divider(height: 40),
                ),
                _buildAccountActionButton(context, appUser),

                // CRITICAL: Floating Bar Cushion Buffer
                const SizedBox(height: 100),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Header with Profile Picture & Name ---
  Widget _buildProfileHeader(
    AppUser appUser,
    String uid,
    BuildContext context,
  ) {
    bool isGuest = appUser is Seeker && appUser.isGuest;
    String? profilePicUrl = appUser.profilePicUrl;

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 56,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage: profilePicUrl != null
                    ? NetworkImage(profilePicUrl)
                    : null,
                child: profilePicUrl == null
                    ? const Icon(
                        Icons.person,
                        size: 70,
                        color: AppColors.primary,
                      )
                    : null,
              ),
            ),
            if (!isGuest)
              Positioned(
                bottom: 0,
                right: 4,
                child: GestureDetector(
                  onTap: () => _updateProfilePicture(context, uid),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          isGuest ? "Guest User" : (appUser.displayName ?? "User"),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          appUser is Assistant
              ? "Medical Assistant Account"
              : "Care Seeker Account",
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  // --- Assistant Specific UI (Clean, split list layout) ---
  Widget _buildAssistantDetails(
    Assistant assistant,
    String uid,
    BuildContext context,
  ) {
    String formattedWorkingTimes = "Not configured";
    if (assistant.workingTimes.isNotEmpty) {
      formattedWorkingTimes = assistant.workingTimes.entries
          .map((e) => "${e.key}: ${e.value.join(' - ')}")
          .join('\n');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle("Identity Verification (Static)"),
          _infoCard(
            Icons.badge_outlined,
            "NIC Number",
            assistant.nic ?? "Not Provided",
          ),
          _infoCard(Icons.wc, "Gender", assistant.gender.name.toUpperCase()),

          const SizedBox(height: 20),
          _buildSectionTitle("Professional Management (Editable)"),

          _editableInfoCard(
            icon: Icons.cake_outlined,
            label: "Age",
            value: assistant.age != null && assistant.age! > 0
                ? "${assistant.age} years"
                : "Not Provided",
            onEdit: () => _showEditDialog(
              context,
              "Age",
              assistant.age?.toString() ?? "",
              "age",
              uid,
              isLucyNum: true,
            ),
          ),
          _editableInfoCard(
            icon: Icons.location_on_outlined,
            label: "Residential Address",
            value: assistant.address ?? "Not Provided",
            onEdit: () => _showEditDialog(
              context,
              "Residential Address",
              assistant.address ?? "",
              "address",
              uid,
            ),
          ),
          _editableInfoCard(
            icon: Icons.payments_outlined,
            label: "Daily Service Rate",
            value: assistant.dailyRate != null && assistant.dailyRate! > 0
                ? "LKR ${assistant.dailyRate}"
                : "Not Provided",
            onEdit: () => _showEditDialog(
              context,
              "Daily Service Rate",
              assistant.dailyRate?.toString() ?? "",
              "dailyRate",
              uid,
              isLucyNum: true,
            ),
          ),
          _editableInfoCard(
            icon: Icons.notes_outlined,
            label: "Professional Bio",
            value: assistant.bio != null && assistant.bio!.isNotEmpty
                ? assistant.bio!
                : "Not Provided",
            onEdit: () => _showEditDialog(
              context,
              "Professional Bio",
              assistant.bio ?? "",
              "bio",
              uid,
              isMultiline: true,
            ),
          ),
          _editableInfoCard(
            icon: Icons.history_edu_outlined,
            label: "Work Experience Description",
            value:
                assistant.experienceDescription != null &&
                    assistant.experienceDescription!.isNotEmpty
                ? assistant.experienceDescription!
                : "Not Provided",
            onEdit: () => _showEditDialog(
              context,
              "Work Experience Description",
              assistant.experienceDescription ?? "",
              "experienceDescription",
              uid,
              isMultiline: true,
            ),
          ),
          _editableInfoCard(
            icon: Icons.access_time_outlined,
            label: "Working Availability Profile",
            value: formattedWorkingTimes,
            onEdit: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "Please modify hours via Registration settings context.",
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 12),
          _buildSkillsCard(context, assistant.skills, uid),
        ],
      ),
    );
  }

  // --- Seeker Specific UI (Clean form fields alignment) ---
  Widget _buildSeekerDetails(Seeker seeker, String uid, BuildContext context) {
    if (seeker.isGuest) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text(
          "You are browsing as a guest. Register a Seeker account to save information.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle("Account Information"),
          _infoCard(
            Icons.email_outlined,
            "Registered Email",
            seeker.email ?? "Not configured",
          ),
          _editableInfoCard(
            icon: Icons.person_outline,
            label: "Profile Display Name",
            value: seeker.displayName ?? "Not configured",
            onEdit: () => _showEditDialog(
              context,
              "Display Name",
              seeker.displayName ?? "",
              "name",
              uid,
            ),
          ),
        ],
      ),
    );
  }

  // --- Subcomponents & Shared Utilities ---
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSkillsCard(
    BuildContext context,
    List<String> skills,
    String uid,
  ) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => _showEditSkillsDialog(context, skills, uid),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(
                        Icons.local_hospital_outlined,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      SizedBox(width: 12),
                      Text(
                        "Registered Medical Skills",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                        ),
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: skills.isEmpty
                    ? [
                        const Text(
                          "No skills declared",
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ]
                    : skills
                          .map(
                            (skill) => Chip(
                              label: Text(
                                skill,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              backgroundColor: AppColors.primary.withOpacity(
                                0.08,
                              ),
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          )
                          .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard(IconData icon, String label, String value) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.textSecondary.withOpacity(0.7)),
        title: Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textMain,
          ),
        ),
      ),
    );
  }

  Widget _editableInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onEdit,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: ListTile(
        onTap: onEdit,
        leading: Icon(icon, color: AppColors.primary),
        title: Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textMain,
          ),
        ),
        trailing: const Icon(
          Icons.edit_note,
          color: AppColors.primary,
          size: 22,
        ),
      ),
    );
  }

  // --- Dialog Business Logic Execution ---
  Future<void> _showEditDialog(
    BuildContext context,
    String title,
    String initialValue,
    String dbField,
    String uid, {
    bool isLucyNum = false,
    bool isMultiline = false,
  }) async {
    TextEditingController controller = TextEditingController(
      text: initialValue,
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "Edit $title",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: controller,
            keyboardType: isLucyNum
                ? TextInputType.number
                : (isMultiline ? TextInputType.multiline : TextInputType.text),
            maxLines: isMultiline ? 3 : 1,
            decoration: InputDecoration(
              hintText: "Update entry details...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                dynamic valueToSave = controller.text.trim();
                if (isLucyNum) valueToSave = int.tryParse(valueToSave) ?? 0;

                try {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .update({dbField: valueToSave});
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Profile sync complete!")),
                    );
                  }
                } catch (e) {
                  if (context.mounted)
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text("Error: $e")));
                }
              },
              child: const Text("Save Changes"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditSkillsDialog(
    BuildContext context,
    List<String> currentSkills,
    String uid,
  ) async {
    TextEditingController controller = TextEditingController(
      text: currentSkills.join(", "),
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "Edit Specializations",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: controller,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: "e.g., CPR, Wound Dressing, Elderly Care",
              helperText: "Separate multiple values with a comma",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                List<String> newSkills = controller.text
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();
                try {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .update({'skills': newSkills});
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Skills list refreshed!")),
                    );
                  }
                } catch (e) {
                  if (context.mounted)
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text("Error: $e")));
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateProfilePicture(BuildContext context, String uid) async {
    final ImagePicker picker = ImagePicker();
    final ImageUploadService uploadService = ImageUploadService();

    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxWidth: 400,
    );
    if (pickedFile == null) return;

    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      final String url = await uploadService.uploadImage(
        uid: uid,
        imageFile: File(pickedFile.path),
        category: 'profile_pics',
      );
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'profilePicUrl': url,
      });
      if (context.mounted) {
        Navigator.pop(context); // Pop loading screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Avatar update complete!")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
      }
    }
  }

  Widget _buildAccountActionButton(BuildContext context, AppUser appUser) {
    final bool isGuest = appUser is Seeker && appUser.isGuest;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: isGuest
          ? ElevatedButton.icon(
              onPressed: () async {
                // Signs out the temporary anonymous session and kicks back to the login interface
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
              icon: const Icon(Icons.login_rounded),
              label: const Text("Sign In / Register"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            )
          : OutlinedButton.icon(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text("Sign Out of Account"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: BorderSide(color: Colors.red.shade200),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
    );
  }
}
