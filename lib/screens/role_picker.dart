import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medicare/services/auth_service.dart';

class RolePicker extends StatefulWidget {
  const RolePicker({super.key});

  @override
  State<RolePicker> createState() => _RolePickerState();
}

class _RolePickerState extends State<RolePicker> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _selectRole(String role) async {
    setState(() => _isLoading = true);

    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      try {
        await _authService.createUserProfile(firebaseUser, role);
      } catch (e) {
        // check if user had gone away
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Error saving role: $e")));
        }
        setState(() => _isLoading = false);
      }
    }
  }

  // =======================================================================================
  // ============  UI  =====================================================================
  // =======================================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Choose Your Role")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "How will you be using Medicare?",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Assistant Option
                  _RoleCard(
                    title: "Medical Assistant",
                    subtitle: "I want to offer my services to patients.",
                    icon: Icons.medical_services,
                    onTap: () => _selectRole('assistant'),
                  ),

                  const SizedBox(height: 20),

                  // Seeker Option
                  _RoleCard(
                    title: "Patient / Seeker",
                    subtitle: "I am looking for medical assistance.",
                    icon: Icons.person_search,
                    onTap: () => _selectRole('seeker'),
                  ),
                ],
              ),
            ),
    );
  }
}

// A reusable private widget for the Role Cards
class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(icon, size: 50, color: Colors.blue),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(subtitle, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
