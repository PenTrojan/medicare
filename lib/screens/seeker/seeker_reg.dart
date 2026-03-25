import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medicare/models/app_user.dart';
import 'package:medicare/services/auth_service.dart';

class SeekerReg extends StatefulWidget {
  const SeekerReg({super.key});

  @override
  State<SeekerReg> createState() => _SeekerRegState();
}

class _SeekerRegState extends State<SeekerReg> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  bool _isSaving = false;
  bool _isInitialized = false;

  void _populateFromSeeker(Seeker seeker) {
    if (_isInitialized) return;
    _nameController.text = seeker.displayName ?? '';
    _isInitialized = true;
  }

  Future<void> _saveProfile(Seeker seeker) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      // Assuming Seeker model has a similar update method
      seeker.updateRegistrationDetails(
        displayName: _nameController.text.trim(),
        registrationComplete: true,
      );

      await seeker.saveToFirestore();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Profile Updated!")));
        // You might want to navigate to the Home screen here
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(title: const Text("Seeker Registration")),
      body: StreamBuilder<AppUser?>(
        stream: AuthService().appUserStream(user),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final seeker = snapshot.data as Seeker;
          _populateFromSeeker(seeker);

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const SizedBox(height: 20),
                const Text(
                  "Welcome! Please enter your name to get started.",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 30),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Full Name",
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.isEmpty)
                      ? "Please enter your name"
                      : null,
                ),

                const SizedBox(height: 40),

                ElevatedButton(
                  onPressed: _isSaving ? null : () => _saveProfile(seeker),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 55),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Complete Registration"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
