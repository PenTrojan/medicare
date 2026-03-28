import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medicare/models/app_user.dart';
import 'package:medicare/models/seeker.dart';
import 'package:medicare/services/auth_service.dart';
import 'package:medicare/services/image_upload_service.dart';

class SeekerReg extends StatefulWidget {
  const SeekerReg({super.key});

  @override
  State<SeekerReg> createState() => _SeekerRegState();
}

class _SeekerRegState extends State<SeekerReg> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final ImageUploadService _uploadService = ImageUploadService();
  final ImagePicker _picker = ImagePicker();

  String? _profilePicUrl;
  bool _isUploadingProfilePic = false;
  bool _isSaving = false;
  bool _isInitialized = false;

  void _populateFromSeeker(Seeker seeker) {
    if (_isInitialized) return;
    _nameController.text = seeker.displayName ?? '';
    _profilePicUrl = seeker.profilePicUrl;
    _isInitialized = true;
  }

  Future<void> _handleProfilePicUpload(String uid) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxWidth: 400,
    );
    if (pickedFile == null) return;

    setState(() => _isUploadingProfilePic = true);
    try {
      final String url = await _uploadService.uploadImage(
        uid: uid,
        imageFile: File(pickedFile.path),
        category: 'profile_pics',
      );
      setState(() => _profilePicUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
      }
    } finally {
      if (mounted) setState(() => _isUploadingProfilePic = false);
    }
  }

  Future<void> _saveProfile(Seeker seeker) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      seeker.updateRegistrationDetails(
        displayName: _nameController.text.trim(),
        profilePicUrl: _profilePicUrl,
        registrationComplete: true,
      );

      await seeker.saveToFirestore();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Profile Updated!")));
        // Add navigation here, e.g., Navigator.pushReplacementNamed(context, '/home');
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
          if (snapshot.connectionState == ConnectionState.waiting &&
              !_isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("User data not found"));
          }

          final seeker = snapshot.data as Seeker;
          _populateFromSeeker(seeker);

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Profile Picture Section
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: _profilePicUrl != null
                            ? NetworkImage(_profilePicUrl!)
                            : null,
                        child: _profilePicUrl == null && !_isUploadingProfilePic
                            ? const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                      if (_isUploadingProfilePic)
                        const Positioned.fill(
                          child: CircularProgressIndicator(),
                        ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor,
                          radius: 20,
                          child: IconButton(
                            icon: const Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: Colors.white,
                            ),
                            onPressed: () => _handleProfilePicUpload(user.uid),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  "Welcome! Please enter your name to get started.",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 20),
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
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
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

