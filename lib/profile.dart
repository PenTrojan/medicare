import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medicare/models/app_user.dart';
import 'package:medicare/services/auth_service.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    // Safety check if user session is lost
    if (user == null) return const Scaffold(body: Center(child: Text("Not logged in")));

    return StreamBuilder<AppUser?>(
      // We use your existing AuthService to get the specific Assistant/Seeker data
      stream: AuthService().appUserStream(user),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final appUser = snapshot.data;
        if (appUser == null) return const Scaffold(body: Center(child: Text("User profile not found")));

        return Scaffold(
          appBar: AppBar(
            title: const Text("My Profile"),
            elevation: 0,
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(appUser),
                const SizedBox(height: 20),
                
                // Logic to show different UI based on the User Class
                if (appUser is Assistant) _buildAssistantDetails(appUser),
                if (appUser is Seeker) _buildSeekerDetails(appUser),
                
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Divider(),
                ),
                  _buildLogoutButton(context),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Header with Circular Profile Picture ---
  Widget _buildHeader(AppUser user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 60,
            backgroundColor: Colors.blue,
            child: Icon(Icons.person, size: 80, color: Colors.white),
          ),
          const SizedBox(height: 15),
          Text(
            user.displayName ?? "User Name",
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            user is Assistant ? "Medical Assistant" : "Patient / Seeker",
            style: TextStyle(color: Colors.blueGrey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  // --- Assistant Specific UI ---
  Widget _buildAssistantDetails(Assistant assistant) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoCard(Icons.star, "Rating", assistant.isVerified ? "Verified Assistant" : "Pending Verification"),
          _infoCard(Icons.badge, "NIC Number", assistant.nic ?? "Not Provided"),
          _infoCard(Icons.location_on, "Address", assistant.address ?? "Not Provided"),
          _infoCard(Icons.work, "Experience", assistant.experienceDescription ?? "Not Provided"),
          _infoCard(Icons.description, "Bio", assistant.bio ?? "No bio available"),
          
          const SizedBox(height: 20),
          const Text("  Skills & Expertise", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: assistant.skills.isEmpty 
              ? [const Text("  No skills listed")]
              : assistant.skills.map((skill) => Chip(
                  label: Text(skill),
                  backgroundColor: Colors.blue[50],
                )).toList(),
          ),
        ],
      ),
    );
  }

  // --- Seeker Specific UI ---
  Widget _buildSeekerDetails(Seeker seeker) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _infoCard(Icons.email, "Email Address", seeker.email ?? "Not provided"),
          _infoCard(Icons.security, "Account Type", seeker.isGuest ? "Guest Access" : "Registered User"),
        ],
      ),
    );
  }

  // --- Reusable Info Card Widget ---
  Widget _infoCard(IconData icon, String label, String value) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        subtitle: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      ),
    );
  }

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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}