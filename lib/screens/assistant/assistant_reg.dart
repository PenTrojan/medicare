import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medicare/models/app_user.dart';
import 'package:medicare/services/auth_service.dart';
import 'package:medicare/services/image_upload_service.dart';

class AssistantReg extends StatefulWidget {
  const AssistantReg({super.key});

  @override
  State<AssistantReg> createState() => _AssistantRegState();
}

class _AssistantRegState extends State<AssistantReg> {
  final _formKey = GlobalKey<FormState>();
  final ImageUploadService _uploadService = ImageUploadService();
  final ImagePicker _picker = ImagePicker();

  // Controllers initialized with empty strings
  final _nicController = TextEditingController();
  final _addressController = TextEditingController();
  final _bioController = TextEditingController();
  final _experienceController = TextEditingController();
  final _skillController = TextEditingController();

  // State for complex data types
  final List<String> _skills = [];
  final List<String> _proofImageUrls = [];
  String? _nicImageUrl;
  
  bool _isUploadingNic = false;
  bool _isUploadingProof = false;
  bool _isSaving = false;
  bool _isInitialized = false;

  // Working Hours State
  final List<String> _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  late Map<String, bool> _dayEnabled;
  late Map<String, TimeOfDay?> _dayStart;
  late Map<String, TimeOfDay?> _dayEnd;

  @override
  void initState() {
    super.initState();
    _dayEnabled = {for (var d in _weekdays) d: false};
    _dayStart = {for (var d in _weekdays) d: null};
    _dayEnd = {for (var d in _weekdays) d: null};
  }

  // Initializing UI controllers from the Assistant object
  void _populateFromAssistant(Assistant assistant) {
    if (_isInitialized) return;
    
    _nicController.text = assistant.nic ?? '';
    _addressController.text = assistant.address ?? '';
    _bioController.text = assistant.bio ?? '';
    _experienceController.text = assistant.experienceDescription ?? '';
    _nicImageUrl = assistant.nicImageUrl;
    _skills.addAll(assistant.skills);
    _proofImageUrls.addAll(assistant.proofImageUrls);

    assistant.workingTimes.forEach((day, times) {
      if (times.length == 2) {
        _dayEnabled[day] = true;
        _dayStart[day] = _parseTime(times[0]);
        _dayEnd[day] = _parseTime(times[1]);
      }
    });
    _isInitialized = true;
  }

  // ================== Image Upload Methods ==================

  Future<void> _handleImageUpload({required String uid, required bool isNic}) async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile == null) return;

    setState(() => isNic ? _isUploadingNic = true : _isUploadingProof = true);

    try {
      final String url = await _uploadService.uploadImage(
        uid: uid,
        imageFile: File(pickedFile.path),
        category: isNic ? 'nic' : 'proof',
      );

      setState(() {
        if (isNic) {
          _nicImageUrl = url;
        } else {
          _proofImageUrls.add(url);
        }
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => isNic ? _isUploadingNic = false : _isUploadingProof = false);
    }
  }

  // ================== Form Submission ==================

  Future<void> _saveProfile(Assistant assistant) async {
    if (!_formKey.currentState!.validate()) return;
    if (_nicImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please upload NIC image")));
      return;
    }

    setState(() => _isSaving = true);

    try {
      // 1. Update the local object using your new method
      assistant.updateRegistrationDetails(
        nic: _nicController.text.trim(),
        nicImageUrl: _nicImageUrl,
        address: _addressController.text.trim(),
        bio: _bioController.text.trim(),
        experienceDescription: _experienceController.text.trim(),
        skills: _skills,
        workingTimes: _generateWorkingTimesMap(),
        proofText: [], // Add logic if you want text-based proof as well
        proofImageUrls: _proofImageUrls,
        registrationComplete: true,
      );

      // 2. Polymorphic save call
      await assistant.saveToFirestore();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Updated!")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Save failed: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ================== UI Build ==================

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    
    return Scaffold(
      appBar: AppBar(title: const Text("Assistant Registration")),
      body: StreamBuilder<AppUser?>(
        stream: AuthService().appUserStream(user),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final assistant = snapshot.data as Assistant;
          _populateFromAssistant(assistant);

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildTextField(_nicController, "NIC Number", Icons.badge),
                const SizedBox(height: 20),
                
                // NIC Image Preview/Upload
                _buildImageUploadTile(
                  title: "NIC Image",
                  url: _nicImageUrl,
                  isUploading: _isUploadingNic,
                  onTap: () => _handleImageUpload(uid: user.uid, isNic: true),
                ),
                
                const Divider(height: 40),
                _buildTextField(_addressController, "Residential Address", Icons.home),
                _buildTextField(_bioController, "Professional Bio", Icons.person, maxLines: 3),
                _buildTextField(_experienceController, "Work Experience", Icons.work, maxLines: 3),
                
                const SizedBox(height: 20),
                _buildSkillInput(),
                
                const SizedBox(height: 20),
                const Text("Certifications / Proof Images", style: TextStyle(fontWeight: FontWeight.bold)),
                _buildProofGallery(user.uid),

                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _isSaving ? null : () => _saveProfile(assistant),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                  child: _isSaving ? const CircularProgressIndicator() : const Text("Save & Complete"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ================== Helper Widgets ==================

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), border: const OutlineInputBorder()),
        validator: (v) => v!.isEmpty ? "Required" : null,
      ),
    );
  }

  Widget _buildImageUploadTile({required String title, required String? url, required bool isUploading, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      trailing: isUploading 
        ? const CircularProgressIndicator() 
        : (url != null ? const Icon(Icons.check_circle, color: Colors.green) : const Icon(Icons.upload)),
      onTap: onTap,
      shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _buildSkillInput() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: TextField(controller: _skillController, decoration: const InputDecoration(hintText: "Add Skill (e.g. Nursing)"))),
            IconButton(icon: const Icon(Icons.add), onPressed: () {
              if (_skillController.text.isNotEmpty) {
                setState(() => _skills.add(_skillController.text.trim()));
                _skillController.clear();
              }
            }),
          ],
        ),
        Wrap(children: _skills.map((s) => Chip(label: Text(s), onDeleted: () => setState(() => _skills.remove(s)))).toList()),
      ],
    );
  }

  Widget _buildProofGallery(String uid) {
    return Wrap(
      spacing: 10,
      children: [
        ..._proofImageUrls.map((url) => Image.network(url, width: 60, height: 60, fit: BoxFit.cover)),
        IconButton(
          icon: _isUploadingProof ? const CircularProgressIndicator() : const Icon(Icons.add_a_photo, size: 40),
          onPressed: () => _handleImageUpload(uid: uid, isNic: false),
        )
      ],
    );
  }

  // Time Parsing Helpers
  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  Map<String, List<String>> _generateWorkingTimesMap() {
    // Logic to build the Map from the UI state (e.g. Monday: [08:00, 17:00])
    return {}; // Implement based on your Switch/TimePicker UI
  }
}