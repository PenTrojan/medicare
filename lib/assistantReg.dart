import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class assistantReg extends StatefulWidget {
  const assistantReg({super.key}); //constructor

  @override
  State<assistantReg> createState() => _FormPageState();
}

class _FormPageState extends State<assistantReg> {
  // 1. Create a global key that uniquely identifies the Form widget
  final _formKey = GlobalKey<FormState>();

  // 2. Create controllers to retrieve the text values
  final _nameController = TextEditingController();
  final _NICController = TextEditingController();
  final _CityController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _NICController.dispose();
    _CityController.dispose(); // Clean up the controller when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Input Form")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ================ Name =========================
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Enter your name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),

              // ================= NIC =========================
              TextFormField(
                controller: _NICController,
                decoration: const InputDecoration(labelText: 'Enter your NIC'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your NIC';
                  }
                  return null;
                },
              ),

              // ================= City =========================
              TextFormField(
                controller: _CityController,
                decoration: const InputDecoration(labelText: 'Enter your City'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter you city';
                  }
                  return null;
                },
              ),

              //===================submit button======================
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  // Validate returns true if the form is valid, or false otherwise.
                  /*if (_formKey.currentState!.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Processing Data: ${_nameController.text}',
                        ),
                      ),
                    );
                  }*/

                  // Sending data to the database
                  if (_formKey.currentState!.validate()) {
                    try {
                      // Logic to save to Firestore
                      await FirebaseFirestore.instance
                          .collection('assistants')
                          .add({
                            'name': _nameController.text,
                            'nic': _NICController.text,
                            'city': _CityController.text,
                            'created_at':
                                FieldValue.serverTimestamp(), // Best practice for sorting
                          });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Registration Successful!'),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
