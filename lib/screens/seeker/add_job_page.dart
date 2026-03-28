import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/job.dart';
import '../../widgets/skill_selector.dart'; // Ensure this path is correct

class AddJobPage extends StatefulWidget {
  const AddJobPage({super.key});

  @override
  State<AddJobPage> createState() => _AddJobPageState();
}

class _AddJobPageState extends State<AddJobPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _conditionController = TextEditingController();
  final _addressController = TextEditingController();

  GeoPoint? _jobLocation;
  bool _isLoading = false;

  // This list will now be updated by the SkillSelector
  final List<String> _selectedSkills = [];

  // Helper to update state when skills are toggled
  void _handleSkillToggled(String skill, bool isSelected) {
    setState(() {
      if (isSelected) {
        if (!_selectedSkills.contains(skill)) _selectedSkills.add(skill);
      } else {
        _selectedSkills.remove(skill);
      }
    });
  }

  Future<void> _getLocation() async {
    setState(() => _isLoading = true);
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );
      setState(() {
        _jobLocation = GeoPoint(position.latitude, position.longitude);
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Location Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitJob() async {
    if (!_formKey.currentState!.validate()) return;

    if (_jobLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please set the job location first.")),
      );
      return;
    }

    if (_selectedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select at least one required skill."),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final newJob = Job(
        id: '',
        seekerId: user.uid,
        patientName: _nameController.text.trim(),
        patientAge: int.parse(_ageController.text.trim()),
        patientCondition: _conditionController.text.trim(),
        address: _addressController.text.trim(),
        location: _jobLocation!,
        requiredSkills: _selectedSkills, // Now uses the live selected list
        createdAt: DateTime.now(),
        status: JobStatus.pending,
      );

      await newJob.saveToFirestore();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Job Posted! Matching in progress...")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to save: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create New Job")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    "Patient Details",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: "Patient Name",
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _ageController,
                    decoration: const InputDecoration(
                      labelText: "Age",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: "Full Address",
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _conditionController,
                    decoration: const InputDecoration(
                      labelText: "Medical Condition / Notes",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 25),

                  // Integrated Skill Selector
                  SkillSelector(
                    selectedSkills: _selectedSkills,
                    onSkillToggled: _handleSkillToggled,
                  ),

                  const SizedBox(height: 25),

                  // Location Selector
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    tileColor: _jobLocation == null
                        ? Colors.red[50]
                        : Colors.green[50],
                    title: const Text("Set Precise Job Location"),
                    subtitle: Text(
                      _jobLocation == null
                          ? "Required for finding nearby assistants"
                          : "Location Captured",
                    ),
                    trailing: Icon(
                      _jobLocation == null
                          ? Icons.location_off
                          : Icons.my_location,
                      color: _jobLocation == null ? Colors.red : Colors.green,
                    ),
                    onTap: _getLocation,
                  ),

                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _submitJob,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text(
                      "Post Job & Find Assistants",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

