import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/job.dart';

class AddJobPage extends StatefulWidget {
  const AddJobPage({super.key});

  @override
  State<AddJobPage> createState() => _AddJobPageState();
}

class _AddJobPageState extends State<AddJobPage> {
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _conditionController = TextEditingController();
  final _rateController = TextEditingController();

  GeoPoint? _jobLocation;
  bool _isLoading = false;

  Future<void> _getLocation() async {
    Position position = await Geolocator.getCurrentPosition();
    setState(
      () => _jobLocation = GeoPoint(position.latitude, position.longitude),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register Patient / Job")),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              "Patient Information",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _patientNameController,
              decoration: const InputDecoration(
                labelText: "Patient Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _ageController,
              decoration: const InputDecoration(
                labelText: "Age",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _conditionController,
              decoration: const InputDecoration(
                labelText: "Medical Condition / Bio",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            ListTile(
              tileColor: Colors.blue.withOpacity(0.1),
              title: const Text("Set Job Location"),
              subtitle: Text(
                _jobLocation == null ? "Not set" : "Location Captured",
              ),
              trailing: const Icon(Icons.my_location),
              onTap: _getLocation,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      /* Trigger job.saveToFirestore() */
                    },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Post Job & Find Assistants"),
            ),
          ],
        ),
      ),
    );
  }
}
