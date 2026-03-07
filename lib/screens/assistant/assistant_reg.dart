import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medicare/models/app_user.dart';
import 'package:medicare/services/auth_service.dart';

class AssistantReg extends StatefulWidget {
  const AssistantReg({super.key}); //constructor

  @override
  State<AssistantReg> createState() => _FormPageState();
}

class _FormPageState extends State<AssistantReg> {
  final _formKey = GlobalKey<FormState>();

  final _nicController = TextEditingController();
  final _nicImageUrlController = TextEditingController();
  final _addressController = TextEditingController();
  final _bioController = TextEditingController();
  final _experienceController = TextEditingController();

  final _skillController = TextEditingController();
  final List<String> _skills = [];

  final _proofTextController = TextEditingController();
  final List<String> _proofText = [];

  final _proofImageUrlController = TextEditingController();
  final List<String> _proofImageUrls = [];

  bool _didInitFromUser = false;
  bool _isSaving = false;

  static const List<String> _weekdays = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  final Map<String, bool> _dayEnabled = {
    for (final d in _weekdays) d: false,
  };
  final Map<String, TimeOfDay?> _dayStart = {
    for (final d in _weekdays) d: null,
  };
  final Map<String, TimeOfDay?> _dayEnd = {
    for (final d in _weekdays) d: null,
  };

  @override
  void dispose() {
    _nicController.dispose();
    _nicImageUrlController.dispose();
    _addressController.dispose();
    _bioController.dispose();
    _experienceController.dispose();
    _skillController.dispose();
    _proofTextController.dispose();
    _proofImageUrlController.dispose();
    super.dispose();
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String _formatTime24(TimeOfDay t) =>
      '${_two(t.hour)}:${_two(t.minute)}';

  static TimeOfDay? _parseTime24(String? s) {
    if (s == null) return null;
    final parts = s.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    if (h < 0 || h > 23) return null;
    if (m < 0 || m > 59) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  void _initFromAssistant(Assistant assistant) {
    _nicController.text = assistant.nic ?? '';
    _nicImageUrlController.text = assistant.nicImageUrl ?? '';
    _addressController.text = assistant.address ?? '';
    _bioController.text = assistant.bio ?? '';
    _experienceController.text = assistant.experienceDescription ?? '';

    _skills
      ..clear()
      ..addAll(assistant.skills);

    _proofText
      ..clear()
      ..addAll(assistant.proofText);

    _proofImageUrls
      ..clear()
      ..addAll(assistant.proofImageUrls);

    for (final day in _weekdays) {
      final times = assistant.workingTimes[day];
      if (times != null && times.length >= 2) {
        _dayEnabled[day] = true;
        _dayStart[day] = _parseTime24(times[0]);
        _dayEnd[day] = _parseTime24(times[1]);
      } else {
        _dayEnabled[day] = false;
        _dayStart[day] = null;
        _dayEnd[day] = null;
      }
    }
  }

  void _addToList(List<String> list, String value) {
    final v = value.trim();
    if (v.isEmpty) return;
    if (!list.contains(v)) {
      setState(() => list.add(v));
    }
  }

  void _removeFromList(List<String> list, String value) {
    setState(() => list.remove(value));
  }

  bool _hasAtLeastOneValidWorkingDay() {
    for (final d in _weekdays) {
      if (_dayEnabled[d] == true && _dayStart[d] != null && _dayEnd[d] != null) {
        return true;
      }
    }
    return false;
  }

  Map<String, List<String>> _buildWorkingTimes() {
    final Map<String, List<String>> out = {};
    for (final d in _weekdays) {
      if (_dayEnabled[d] != true) continue;
      final s = _dayStart[d];
      final e = _dayEnd[d];
      if (s == null || e == null) continue;
      out[d] = <String>[_formatTime24(s), _formatTime24(e)];
    }
    return out;
  }

  Future<void> _pickTime(String day, bool isStart) async {
    final initial = (isStart ? _dayStart[day] : _dayEnd[day]) ?? const TimeOfDay(hour: 9, minute: 0);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _dayStart[day] = picked;
      } else {
        _dayEnd[day] = picked;
      }
      _dayEnabled[day] = true;
    });
  }

  Future<void> _submit(Assistant assistant) async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_skills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one skill.')),
      );
      return;
    }
    if (!_hasAtLeastOneValidWorkingDay()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set working hours for at least one day.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      assistant.updateRegistrationDetails(
        nic: _nicController.text,
        nicImageUrl: _nicImageUrlController.text,
        address: _addressController.text,
        bio: _bioController.text,
        experienceDescription: _experienceController.text,
        skills: List<String>.from(_skills),
        workingTimes: _buildWorkingTimes(),
        proofText: List<String>.from(_proofText),
        proofImageUrls: List<String>.from(_proofImageUrls),
        registrationComplete: true,
      );

      await assistant.saveToFirestore();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration saved.')),
      );

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving registration: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _chipWrap(List<String> items, void Function(String) onRemove) {
    if (items.isEmpty) {
      return const Text('None added yet.', style: TextStyle(color: Colors.grey));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in items)
          Chip(
            label: Text(item),
            onDeleted: () => onRemove(item),
          ),
      ],
    );
  }

  Widget _workingTimesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Working hours',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        for (final day in _weekdays)
          Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          day,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Switch(
                        value: _dayEnabled[day] ?? false,
                        onChanged: (v) {
                          setState(() {
                            _dayEnabled[day] = v;
                            if (!v) {
                              _dayStart[day] = null;
                              _dayEnd[day] = null;
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  if (_dayEnabled[day] == true)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _pickTime(day, true),
                            child: Text(
                              _dayStart[day] == null
                                  ? 'Start'
                                  : _formatTime24(_dayStart[day]!),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _pickTime(day, false),
                            child: Text(
                              _dayEnd[day] == null
                                  ? 'End'
                                  : _formatTime24(_dayEnd[day]!),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      return const Scaffold(
        body: Center(child: Text('Not signed in.')),
      );
    }

    final authService = AuthService();

    return StreamBuilder<AppUser?>(
      stream: authService.appUserStream(firebaseUser),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null || user is! Assistant) {
          return const Scaffold(
            body: Center(child: Text('Assistant profile not found.')),
          );
        }

        if (!_didInitFromUser) {
          _didInitFromUser = true;
          _initFromAssistant(user);
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Complete assistant registration'),
          ),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (user.displayName != null || user.email != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.displayName ?? 'Assistant',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.email ?? '',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _nicController,
                    decoration: const InputDecoration(
                      labelText: 'NIC',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'NIC is required';
                      if (v.trim().length < 6) return 'NIC looks too short';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nicImageUrlController,
                    decoration: const InputDecoration(
                      labelText: 'NIC image URL (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Address is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _bioController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Bio',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Bio is required';
                      if (v.trim().length < 20) return 'Bio is too short';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _experienceController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Experience',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Experience is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Skills',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _skillController,
                          decoration: const InputDecoration(
                            hintText: 'Add a skill (e.g., Wound dressing)',
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (v) {
                            _addToList(_skills, v);
                            _skillController.clear();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          _addToList(_skills, _skillController.text);
                          _skillController.clear();
                        },
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _chipWrap(_skills, (s) => _removeFromList(_skills, s)),

                  const SizedBox(height: 20),
                  _workingTimesSection(),

                  const SizedBox(height: 20),
                  const Text(
                    'Proof (text)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _proofTextController,
                          decoration: const InputDecoration(
                            hintText: 'Add certification / proof text',
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (v) {
                            _addToList(_proofText, v);
                            _proofTextController.clear();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          _addToList(_proofText, _proofTextController.text);
                          _proofTextController.clear();
                        },
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _chipWrap(_proofText, (s) => _removeFromList(_proofText, s)),

                  const SizedBox(height: 20),
                  const Text(
                    'Proof image URLs (optional)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _proofImageUrlController,
                          decoration: const InputDecoration(
                            hintText: 'Add image URL',
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (v) {
                            _addToList(_proofImageUrls, v);
                            _proofImageUrlController.clear();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          _addToList(_proofImageUrls, _proofImageUrlController.text);
                          _proofImageUrlController.clear();
                        },
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _chipWrap(
                    _proofImageUrls,
                    (s) => _removeFromList(_proofImageUrls, s),
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : () => _submit(user),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save & continue'),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
} 