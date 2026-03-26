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

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    // Safety check if user session is lost
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
            title: const Text("My Profile"), 
            elevation: 0,
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // Profile Picture & Name Header
                _buildProfileHeader(appUser, user.uid, context),
                
                const SizedBox(height: 20),

                // Logic to show different UI based on the User Class
                if (appUser is Assistant) _buildAssistantDetails(appUser, user.uid, context),
                if (appUser is Seeker) _buildSeekerDetails(appUser),

                const Padding(padding: EdgeInsets.all(20.0), child: Divider()),
                _buildLogoutButton(context),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Header with Profile Picture & Name ---
  Widget _buildProfileHeader(AppUser appUser, String uid, BuildContext context) {
    bool isGuest = appUser is Seeker && appUser.isGuest;
    
    // Get profile pic url if available
    String? profilePicUrl;
    if (appUser is Assistant) {
      profilePicUrl = appUser.profilePicUrl;
    } else if (appUser is Seeker) {
      profilePicUrl = (appUser as dynamic).profilePicUrl; 
    }

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.blue[100],
              backgroundImage: profilePicUrl != null ? NetworkImage(profilePicUrl) : null,
              child: profilePicUrl == null 
                  ? const Icon(Icons.person, size: 80, color: Colors.blue) 
                  : null,
            ),
            // Edit button for everyone EXCEPT guests
            if (!isGuest)
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => _updateProfilePicture(context, uid),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit, color: Colors.white, size: 20),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 15),
        
        // Display Name
        Text(
          isGuest ? "Guest User" : (appUser.displayName ?? "Unknown User"),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // --- Assistant Specific UI ---
  Widget _buildAssistantDetails(Assistant assistant, String uid, BuildContext context) {
    String formattedWorkingTimes = "Not set";
    if (assistant.workingTimes.isNotEmpty) {
      formattedWorkingTimes = assistant.workingTimes.entries
          .map((e) => "${e.key}: ${e.value.join(' - ')}")
          .join('\n');
    }

    String ratingDisplay = "Not rated yet";
    try {
       ratingDisplay = (assistant as dynamic).rating != null ? "${(assistant as dynamic).rating} / 5.0" : "Not rated yet";
    } catch(e) {
       // Fallback
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Non-editable fields
          _infoCard(Icons.badge, "NIC Number", assistant.nic ?? "Not Provided"),
          _infoCard(Icons.wc, "Gender", assistant.gender.name.toUpperCase()),
          _infoCard(Icons.star, "Rating", ratingDisplay), 

          const SizedBox(height: 10),
          const Divider(),
          const SizedBox(height: 10),

          // Editable fields
          _editableInfoCard(
            icon: Icons.cake,
            label: "Age",
            value: assistant.age != null ? "${assistant.age} years" : "Not Provided",
            onEdit: () => _showEditDialog(context, "Age", assistant.age?.toString() ?? "", "age", uid, isNumber: true),
          ),

          _editableInfoCard(
            icon: Icons.location_on,
            label: "Location",
            value: assistant.address ?? "Not Provided",
            onEdit: () => _showEditDialog(context, "Location", assistant.address ?? "", "address", uid),
          ),

          _editableInfoCard(
            icon: Icons.payments,
            label: "Daily Rate",
            value: assistant.dailyRate != null ? "Rs. ${assistant.dailyRate}" : "Not Provided",
            onEdit: () => _showEditDialog(context, "Daily Rate", assistant.dailyRate?.toString() ?? "", "dailyRate", uid, isNumber: true),
          ),

          _editableInfoCard(
            icon: Icons.work,
            label: "Professional Bio",
            value: assistant.bio != null && assistant.bio!.isNotEmpty 
                ? assistant.bio! 
                : "Not Provided",
            onEdit: () => _showEditDialog(context, "Professional Bio", assistant.bio ?? "", "bio", uid, isMultiline: true),
          ),

          _editableInfoCard(
            icon: Icons.history_edu,
            label: "Work Experience",
            value: assistant.experienceDescription != null && assistant.experienceDescription!.isNotEmpty 
                ? assistant.experienceDescription! 
                : "Not Provided",
            onEdit: () => _showEditDialog(context, "Work Experience", assistant.experienceDescription ?? "", "experienceDescription", uid, isMultiline: true),
          ),

          _editableInfoCard(
            icon: Icons.access_time,
            label: "Working Days & Hours",
            value: formattedWorkingTimes,
            onEdit: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Please go to Settings -> Schedule to edit working hours.")),
              );
            },
          ),

          // Skills Section (Editable)
          Card(
            elevation: 0,
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey[200]!),
            ),
            child: InkWell(
              onTap: () => _showEditSkillsDialog(context, assistant.skills, uid),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star_border, color: Colors.blue),
                            const SizedBox(width: 16),
                            const Text(
                              "Skills",
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        const Icon(Icons.edit, color: Colors.blue, size: 20),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: assistant.skills.isEmpty
                          ? [const Text("No skills listed", style: TextStyle(fontSize: 16))]
                          : assistant.skills
                              .map((skill) => Chip(
                                    label: Text(skill),
                                    backgroundColor: Colors.blue[50],
                                  ))
                              .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Seeker Specific UI ---
  Widget _buildSeekerDetails(Seeker seeker) {
    if (seeker.isGuest) {
      return const SizedBox.shrink(); 
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _infoCard(
            Icons.email,
            "Email Address",
            seeker.email ?? "Not provided",
          ),
        ],
      ),
    );
  }

  // --- Generic Edit Logic via Dialogs ---
  Future<void> _showEditDialog(BuildContext context, String title, String initialValue, String dbField, String uid, {bool isNumber = false, bool isMultiline = false}) async {
    TextEditingController controller = TextEditingController(text: initialValue);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit $title"),
          content: TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : (isMultiline ? TextInputType.multiline : TextInputType.text),
            maxLines: isMultiline ? 3 : 1,
            decoration: InputDecoration(
              hintText: "Enter your $title",
              border: const OutlineInputBorder(),
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
                
                if (isNumber) {
                  valueToSave = int.tryParse(valueToSave) ?? 0;
                }

                try {
                  // IMPORTANT: Ensure 'users' matches your Firestore collection name!
                  await FirebaseFirestore.instance.collection('users').doc(uid).update({
                    dbField: valueToSave,
                  });
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Updated successfully!")));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to update: $e")));
                  }
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditSkillsDialog(BuildContext context, List<String> currentSkills, String uid) async {
    TextEditingController controller = TextEditingController(text: currentSkills.join(", "));

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Skills"),
          content: TextField(
            controller: controller,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: "e.g. CPR, First Aid",
              helperText: "Separate multiple skills with commas",
              border: OutlineInputBorder(),
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
                  // IMPORTANT: Ensure 'users' matches your Firestore collection name!
                  await FirebaseFirestore.instance.collection('users').doc(uid).update({
                    'skills': newSkills,
                  });
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Skills updated!")));
                  }
                } catch (e) {
                   if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to update: $e")));
                  }
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // --- Profile Picture Update Logic ---
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
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      final String url = await uploadService.uploadImage(
        uid: uid,
        imageFile: File(pickedFile.path),
        category: 'profile_pics',
      );

      // IMPORTANT: Ensure 'users' matches your Firestore collection name!
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'profilePicUrl': url,
      });

      if (context.mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile picture updated!")));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload Error: $e")));
      }
    }
  }

  // --- Reusable Static Info Card ---
  Widget _infoCard(IconData icon, String label, String value) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueGrey),
        title: Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  // --- Reusable Editable Info Card ---
  Widget _editableInfoCard({
    required IconData icon, 
    required String label, 
    required String value, 
    required VoidCallback onEdit
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue[100]!), 
      ),
      child: ListTile(
        onTap: onEdit, // <-- Makes the ENTIRE CARD clickable
        leading: Icon(icon, color: Colors.blue),
        title: Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(Icons.edit, color: Colors.blue, size: 20),
      ),
    );
  }

  // --- Logout Button ---
  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton.icon(
        onPressed: () async {
          await FirebaseAuth.instance.signOut();
          if (context.mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
        icon: const Icon(Icons.logout),
        label: const Text("Log Out"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[50],
          foregroundColor: Colors.red,
          elevation: 0,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

