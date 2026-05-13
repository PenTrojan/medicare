import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/job.dart';
import '../../models/app_user.dart'; // For Gender enum
import '../../widgets/skill_selector.dart';
import '../../widgets/availability_selector.dart'; // Our shared widget

class AddJobPage extends StatefulWidget {
  const AddJobPage({super.key});

  @override
  State<AddJobPage> createState() => _AddJobPageState();
}

class _AddJobPageState extends State<AddJobPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _conditionController = TextEditingController();
  final _addressController = TextEditingController();
  final _maxRateController = TextEditingController();

  // State
  DateTimeRange? _selectedDateRange;
  Gender _preferredGender = Gender.unspecified;
  GeoPoint? _jobLocation;
  bool _isLoading = false;
  final List<String> _selectedSkills = [];

  // Availability State (to be passed to AvailabilitySelector)
  late Map<String, bool> _dayEnabled;
  late Map<String, TimeOfDay?> _dayStart;
  late Map<String, TimeOfDay?> _dayEnd;

  @override
  void initState() {
    super.initState();
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    _dayEnabled = {for (var d in weekdays) d: false};
    _dayStart = {for (var d in weekdays) d: null};
    _dayEnd = {for (var d in weekdays) d: null};
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _conditionController.dispose();
    _addressController.dispose();
    _maxRateController.dispose();
    super.dispose();
  }

  void _handleSkillToggled(String skill, bool isSelected) {
    setState(() {
      isSelected ? _selectedSkills.add(skill) : _selectedSkills.remove(skill);
    });
  }

  // Same logic as AssistantReg to ensure matching string formats
  Map<String, List<String>> _generateWorkingTimesMap() {
    Map<String, List<String>> map = {};
    _dayEnabled.forEach((day, enabled) {
      if (enabled && _dayStart[day] != null && _dayEnd[day] != null) {
        final startH = _dayStart[day]!.hour.toString().padLeft(2, '0');
        final startM = _dayStart[day]!.minute.toString().padLeft(2, '0');
        final endH = _dayEnd[day]!.hour.toString().padLeft(2, '0');
        final endM = _dayEnd[day]!.minute.toString().padLeft(2, '0');
        map[day] = ["$startH:$startM", "$endH:$endM"];
      }
    });
    return map;
  }

  Future<void> _getLocation() async {
    setState(() => _isLoading = true);
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(
        () => _jobLocation = GeoPoint(position.latitude, position.longitude),
      );
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
        const SnackBar(content: Text("Please set the job location")),
      );
      return;
    }

    if (_selectedDateRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a date range")),
      );
      return;
    }

    final workingTimes = _generateWorkingTimesMap();
    if (workingTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select required working hours")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final newJob = Job(
        id: '',
        seekerId: user!.uid,
        patientName: _nameController.text.trim(),
        patientAge: int.parse(_ageController.text.trim()),
        patientCondition: _conditionController.text.trim(),
        address: _addressController.text.trim(),
        location: _jobLocation!,
        requiredSkills: _selectedSkills,
        startDate: _selectedDateRange!.start,
        endDate: _selectedDateRange!.end,
        workingTimes: workingTimes,
        maxDailyRate: int.parse(_maxRateController.text.trim()),
        preferredGender: _preferredGender,
        createdAt: DateTime.now(),
        status: JobStatus.pending,
      );

      await newJob.saveToFirestore();

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to save: $e")));
      }
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
                  _buildTextField(
                    _nameController,
                    "Patient Name",
                    Icons.person,
                  ),
                  _buildTextField(
                    _ageController,
                    "Age",
                    Icons.cake,
                    isNumber: true,
                  ),
                  _buildTextField(
                    _addressController,
                    "Full Address",
                    Icons.home,
                  ),
                  _buildTextField(
                    _conditionController,
                    "Medical Condition",
                    Icons.medical_services,
                    maxLines: 2,
                  ),

                  const Divider(height: 40),
                  const Text(
                    "Matching Preferences",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),

                  DropdownButtonFormField<Gender>(
                    value: _preferredGender,
                    decoration: const InputDecoration(
                      labelText: "Preferred Gender",
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
                    onChanged: (val) => setState(() => _preferredGender = val!),
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    _maxRateController,
                    "Max Daily Budget (Rs)",
                    Icons.payments,
                    isNumber: true,
                  ),

                  const SizedBox(height: 10),
                  SkillSelector(
                    selectedSkills: _selectedSkills,
                    onSkillToggled: _handleSkillToggled,
                  ),

                  const Divider(height: 40),
                  const Text(
                    "Schedule",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  ListTile(
                    title: const Text("Select Date Range"),
                    subtitle: Text(
                      _selectedDateRange == null
                          ? "Not Set"
                          : "${_selectedDateRange!.start.toString().split(' ')[0]} to ${_selectedDateRange!.end.toString().split(' ')[0]}",
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null)
                        setState(() => _selectedDateRange = picked);
                    },
                  ),

                  AvailabilitySelector(
                    dayEnabled: _dayEnabled,
                    dayStart: _dayStart,
                    dayEnd: _dayEnd,
                    onChanged: (day, enabled, start, end) {
                      setState(() {
                        _dayEnabled[day] = enabled;
                        _dayStart[day] = start;
                        _dayEnd[day] = end;
                      });
                    },
                  ),

                  const SizedBox(height: 20),
                  ListTile(
                    tileColor: _jobLocation == null
                        ? Colors.red[50]
                        : Colors.green[50],
                    title: const Text("Set Precise Job Location"),
                    trailing: Icon(
                      Icons.my_location,
                      color: _jobLocation == null ? Colors.red : Colors.green,
                    ),
                    onTap: _getLocation,
                  ),

                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _submitJob,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text("Post Job & Start Matching"),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        validator: (v) => v!.isEmpty ? "Required" : null,
      ),
    );
  }
}
