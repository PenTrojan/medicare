import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medicare/models/app_user.dart';
import 'package:medicare/models/assistant.dart';
import 'package:medicare/services/auth_service.dart';
import 'package:medicare/services/image_upload_service.dart';
import 'package:medicare/widgets/skill_selector.dart';

class AssistantReg extends StatefulWidget {
  const AssistantReg({super.key});

  @override
  State<AssistantReg> createState() => _AssistantRegState();
}

class _AssistantRegState extends State<AssistantReg> {
  final _formKey = GlobalKey<FormState>();
  final ImageUploadService _uploadService = ImageUploadService();
  final ImagePicker _picker = ImagePicker();

  // Controllers
  final _nameController = TextEditingController();
  final _nicController = TextEditingController();
  final _addressController = TextEditingController();
  final _bioController = TextEditingController();
  final _experienceController = TextEditingController();
  //final _skillController = TextEditingController();
  final _ageController = TextEditingController();
  final _rateController = TextEditingController();

  // State
  final List<String> _skills = [];
  final List<String> _proofImageUrls = [];
  String? _nicImageUrl;
  String? _profilePicUrl;

  Gender _selectedGender = Gender.unspecified;
  ExperienceLevel _selectedExpLevel = ExperienceLevel.unspecified;
  GeoPoint? _currentLocation;

  bool _isUploadingNic = false;
  bool _isUploadingProof = false;
  bool _isUploadingProfilePic = false;
  bool _isSaving = false;
  bool _isInitialized = false;
  bool _isGettingLocation = false;

  final List<String> _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
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

  void _populateFromAssistant(Assistant assistant) {
    if (_isInitialized) return;

    _nameController.text = assistant.displayName ?? '';
    _nicController.text = assistant.nic ?? '';
    _addressController.text = assistant.address ?? '';
    _bioController.text = assistant.bio ?? '';
    _experienceController.text = assistant.experienceDescription ?? '';
    _ageController.text = assistant.age?.toString() ?? '';
    _rateController.text = assistant.dailyRate?.toString() ?? '';

    _selectedGender = assistant.gender;
    _selectedExpLevel =
        assistant.experienceLevel ?? ExperienceLevel.unspecified;
    _currentLocation = assistant.location;
    _nicImageUrl = assistant.nicImageUrl;
    _profilePicUrl = assistant.profilePicUrl;

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

  // ================== Image & Location Methods ==================

  Future<void> _handleProfilePicUpload(String uid) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // Higher compression for profile pics
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
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isUploadingProfilePic = false);
    }
  }

  Future<void> _handleImageUpload({
    required String uid,
    required bool isNic,
  }) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (pickedFile == null) return;
    setState(() => isNic ? _isUploadingNic = true : _isUploadingProof = true);
    try {
      final String url = await _uploadService.uploadImage(
        uid: uid,
        imageFile: File(pickedFile.path),
        category: isNic ? 'nic' : 'proof',
      );
      setState(() => isNic ? _nicImageUrl = url : _proofImageUrls.add(url));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(
        () => isNic ? _isUploadingNic = false : _isUploadingProof = false,
      );
    }
  }

  // ... (keeping _getExpLabel, _getCurrentLocation, _parseTime, _generateWorkingTimesMap from previous response) ...
  String _getExpLabel(ExperienceLevel level) {
    switch (level) {
      case ExperienceLevel.lessThanOne:
        return "< 1 Year";
      case ExperienceLevel.oneToThree:
        return "1 - 3 Years";
      case ExperienceLevel.threeToFive:
        return "3 - 5 Years";
      case ExperienceLevel.fivePlus:
        return "5+ Years";
      case ExperienceLevel.unspecified:
        return "Not Specified";
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied)
        permission = await Geolocator.requestPermission();
      Position position = await Geolocator.getCurrentPosition();
      setState(
        () =>
            _currentLocation = GeoPoint(position.latitude, position.longitude),
      );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Location Error")));
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _saveProfile(Assistant assistant) async {
    if (!_formKey.currentState!.validate()) return;
    if (_nicImageUrl == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Upload NIC image")));
      return;
    }

    setState(() => _isSaving = true);
    try {
      assistant.updateRegistrationDetails(
        displayName: _nameController.text.trim(),
        nic: _nicController.text.trim(),
        nicImageUrl: _nicImageUrl,
        address: _addressController.text.trim(),
        bio: _bioController.text.trim(),
        experienceDescription: _experienceController.text.trim(),
        skills: _skills,
        workingTimes: _generateWorkingTimesMap(),
        proofText: [],
        proofImageUrls: _proofImageUrls,
        registrationComplete: true,
        gender: _selectedGender,
        age: int.tryParse(_ageController.text) ?? 0,
        dailyRate: int.tryParse(_rateController.text) ?? 0,
        experienceLevel: _selectedExpLevel,
        profilePicUrl: _profilePicUrl,
        location: _currentLocation,
      );

      await assistant.saveToFirestore();
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Profile Updated!")));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(title: const Text("Assistant Registration")),
      body: StreamBuilder<AppUser?>(
        stream: AuthService().appUserStream(user),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final assistant = snapshot.data as Assistant;
          _populateFromAssistant(assistant);

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // PROFILE PICTURE UPLOAD
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

                _buildTextField(
                  _nameController,
                  "Full Name",
                  Icons.person_outline,
                ),
                _buildTextField(
                  _nicController,
                  "NIC Number",
                  Icons.badge_outlined,
                  textCapitalization: TextCapitalization.characters,
                  customValidator: (v) {
                    final nicRegex = RegExp(r'^(\d{9}V|\d{12})$');
                    if (v == null || v.isEmpty)
                      return 'Please enter a valid Sri Lankan NIC';
                    if (!nicRegex.hasMatch(v.trim()))
                      return 'Please enter a valid Sri Lankan NIC';
                    return null;
                  },
                ),

                DropdownButtonFormField<Gender>(
                  value: _selectedGender,
                  decoration: const InputDecoration(
                    labelText: "Gender",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.wc),
                  ),
                  items: Gender.values
                      .map(
                        (g) => DropdownMenuItem(
                          value: g,
                          child: Text(g.name.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _selectedGender = val!),
                ),
                const SizedBox(height: 15),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        _ageController,
                        "Age",
                        Icons.cake,
                        isNumber: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        _rateController,
                        "Daily Rate (Rs)",
                        Icons.payments,
                        isNumber: true,
                      ),
                    ),
                  ],
                ),

                DropdownButtonFormField<ExperienceLevel>(
                  value: _selectedExpLevel,
                  decoration: const InputDecoration(
                    labelText: "Experience Level",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.bolt),
                  ),
                  items: ExperienceLevel.values
                      .map(
                        (l) => DropdownMenuItem(
                          value: l,
                          child: Text(_getExpLabel(l)),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _selectedExpLevel = val!),
                ),
                const SizedBox(height: 15),

                ListTile(
                  title: const Text("Home Location"),
                  subtitle: Text(
                    _currentLocation == null ? "Not set" : "Location Captured",
                  ),
                  trailing: _isGettingLocation
                      ? const CircularProgressIndicator()
                      : const Icon(Icons.my_location, color: Colors.blue),
                  onTap: _getCurrentLocation,
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 15),

                _buildImageUploadTile(
                  title: "NIC Image",
                  url: _nicImageUrl,
                  isUploading: _isUploadingNic,
                  onTap: () => _handleImageUpload(uid: user.uid, isNic: true),
                ),

                const Divider(height: 40),
                _buildTextField(
                  _addressController,
                  "Residential Address",
                  Icons.home_outlined,
                ),
                _buildTextField(
                  _bioController,
                  "Professional Bio",
                  Icons.notes,
                  maxLines: 3,
                ),
                _buildTextField(
                  _experienceController,
                  "Experience Description",
                  Icons.history_edu,
                  maxLines: 3,
                ),

                const SizedBox(height: 10),
                SkillSelector(
                  selectedSkills: _skills,
                  onSkillToggled: (skill, isSelected) {
                    setState(() {
                      if (isSelected) {
                        _skills.add(skill);
                      } else {
                        _skills.remove(skill);
                      }
                    });
                  },
                ),

                if (_skills.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      "Please select at least one skill",
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),

                const Divider(height: 40),
                const Text(
                  "Working Hours",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                ..._weekdays.map((day) => _buildDayTile(day)),

                const SizedBox(height: 20),
                const Text(
                  "Portfolio / Proof Images",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                _buildProofGallery(user.uid),

                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _isSaving ? null : () => _saveProfile(assistant),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 55),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Save & Complete"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ... (keeping _buildDayTile, _buildTextField, _buildImageUploadTile, _buildSkillInput, _buildProofGallery, _parseTime, _generateWorkingTimesMap from previous response) ...
  Widget _buildDayTile(String day) {
    return ExpansionTile(
      leading: Checkbox(
        value: _dayEnabled[day],
        onChanged: (v) => setState(() => _dayEnabled[day] = v!),
      ),
      title: Text(day),
      subtitle: Text(
        _dayEnabled[day]!
            ? "${_dayStart[day]?.format(context) ?? '--'} to ${_dayEnd[day]?.format(context) ?? '--'}"
            : "Unavailable",
      ),
      children: [
        if (_dayEnabled[day]!)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () async {
                    final t = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (t != null) setState(() => _dayStart[day] = t);
                  },
                  child: const Text("Set Start"),
                ),
                TextButton(
                  onPressed: () async {
                    final t = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (t != null) setState(() => _dayEnd[day] = t);
                  },
                  child: const Text("Set End"),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
    bool isNumber = false,
    String? Function(String?)? customValidator,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        textCapitalization: textCapitalization,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        validator: customValidator ?? (v) => v!.isEmpty ? "Required" : null,
      ),
    );
  }

  Widget _buildImageUploadTile({
    required String title,
    required String? url,
    required bool isUploading,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(title),
      trailing: isUploading
          ? const CircularProgressIndicator()
          : Icon(
              url != null ? Icons.check_circle : Icons.cloud_upload,
              color: url != null ? Colors.green : null,
            ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  /*Widget _buildSkillInput() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _skillController,
                decoration: const InputDecoration(hintText: "Add Skill"),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle),
              onPressed: () {
                if (_skillController.text.isNotEmpty) {
                  setState(() => _skills.add(_skillController.text.trim()));
                  _skillController.clear();
                }
              },
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          children: _skills
              .map(
                (s) => Chip(
                  label: Text(s),
                  onDeleted: () => setState(() => _skills.remove(s)),
                ),
              )
              .toList(),
        ),
      ],
    );
  }*/

  Widget _buildProofGallery(String uid) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ..._proofImageUrls.map(
          (url) => ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(url, width: 70, height: 70, fit: BoxFit.cover),
          ),
        ),
        InkWell(
          onTap: () => _handleImageUpload(uid: uid, isNic: false),
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _isUploadingProof
                ? const Center(child: CircularProgressIndicator())
                : const Icon(Icons.add_a_photo),
          ),
        ),
      ],
    );
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  Map<String, List<String>> _generateWorkingTimesMap() {
    Map<String, List<String>> map = {};
    _dayEnabled.forEach((day, enabled) {
      if (enabled && _dayStart[day] != null && _dayEnd[day] != null) {
        map[day] = [
          "${_dayStart[day]!.hour}:${_dayStart[day]!.minute}",
          "${_dayEnd[day]!.hour}:${_dayEnd[day]!.minute}",
        ];
      }
    });
    return map;
  }
}
