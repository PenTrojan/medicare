// This script adds dummy data to the firestore
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class DummyDataService {
  static Future<void> seedJobs(String currentUserId) async {
    final jobsRef = FirebaseFirestore.instance.collection('jobs');
    final random = Random();

    final names = [
      "Nimal",
      "Sunil",
      "Kamal",
      "Priyantha",
      "Anura",
      "Bandara",
      "Chathura",
      "Dinesh",
      "Aruni",
      "Kanti",
      "Nilanthi",
      "Dilani",
    ];
    final surnames = [
      "Perera",
      "Jayawardena",
      "Silvia",
      "Fernando",
      "Herath",
      "Rathnayake",
      "Liyanage",
    ];
    final conditions = [
      "Post-surgery recovery",
      "Diabetes management",
      "Elderly care",
      "Mobility assistance",
      "Physiotherapy support",
      "General companionship",
      "Dementia monitoring",
    ];

    final skillsPool = [
      "Vital Signs Monitoring (BP, Pulse, Temp)",
      "Wound Care & Dressing",
      "CPR / Basic Life Support (BLS)",
      "First Aid Administration",
      "Administering Injections (IM/SubQ)",
      "Catheter Care",
      "Mobility & Transfer Assistance",
      "Patient Bathing & Hygiene",
      "Feeding Assistance",
      "Medication Administration & Reminders",
      "Elderly Care",
      "Post-Operative Care",
      "Dementia / Alzheimer's Care",
      "Fluent in English",
      "Fluent in Sinhala",
      "Empathy & Bedside Manner",
    ];

    final weekdays = [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday",
    ];

    for (int i = 0; i < 50; i++) {
      // 1. Randomize Location (Radius around Kurunegala)
      double lat = 7.4818 + (random.nextDouble() - 0.5) * 0.15;
      double lng = 80.3609 + (random.nextDouble() - 0.5) * 0.15;

      // 2. Randomize Skills (Select 2 to 6 unique skills)
      List<String> selectedSkills = (List<String>.from(
        skillsPool,
      )..shuffle()).take(random.nextInt(5) + 2).toList();

      // 3. Randomize Working Days (1 to 4 days per week)
      List<String> selectedDays = (List<String>.from(
        weekdays,
      )..shuffle()).take(random.nextInt(4) + 1).toList();

      // 4. Randomize Working Times (Between 8 AM and 8 PM)
      // Logic: Start between 08:00 and 13:00, Duration 3 to 7 hours
      int startHour = 8 + random.nextInt(5);
      int duration = 3 + random.nextInt(5);
      int endHour = startHour + duration;

      String startTime = "${startHour.toString().padLeft(2, '0')}:00";
      String endTime = "${endHour.toString().padLeft(2, '0')}:00";

      Map<String, List<String>> workingTimes = {
        for (var day in selectedDays) day: [startTime, endTime],
      };

      // 5. Randomize Daily Rate based on skill count (Minimum 1500, higher for more skills)
      int baseRate = 1500 + (selectedSkills.length * 200);
      int randomBonus = random.nextInt(1000);
      int finalRate =
          ((baseRate + randomBonus) / 50).round() * 50; // Round to nearest 50

      Map<String, dynamic> jobData = {
        'seekerId': currentUserId,
        'patientName':
            "${names[random.nextInt(names.length)]} ${surnames[random.nextInt(surnames.length)]}",
        'patientAge': 45 + random.nextInt(45),
        'patientCondition': conditions[random.nextInt(conditions.length)],
        'address':
            "Kurunegala Zone ${random.nextInt(15)}, Sector ${String.fromCharCode(65 + random.nextInt(6))}",
        'location': GeoPoint(lat, lng),
        'requiredSkills': selectedSkills,
        'startDate': Timestamp.fromDate(
          DateTime.now().add(Duration(days: random.nextInt(7))),
        ),
        'endDate': Timestamp.fromDate(
          DateTime.now().add(Duration(days: 14 + random.nextInt(60))),
        ),
        'workingTimes': workingTimes,
        'maxDailyRate': finalRate,
        'preferredGender':
            Gender.values[random.nextInt(Gender.values.length)].name,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'topMatches': [],
      };

      await jobsRef.add(jobData);
    }
  }

  static Future<void> seedAssistants() async {
    final userRef = FirebaseFirestore.instance.collection('users');
    final random = Random();

    final firstNames = [
      "Kusal",
      "Dasun",
      "Pathum",
      "Wanindu",
      "Chamari",
      "Inoka",
      "Oshadi",
      "Udeshika",
      "Mahela",
      "Kumar",
    ];
    final lastNames = [
      "Mendis",
      "Shanaka",
      "Nissanka",
      "Hasaranga",
      "Atapattu",
      "Ranaweera",
      "Ranasinghe",
      "Prabath",
      "Jayawardena",
      "Sangakkara",
    ];

    final bioPool = [
      "Dedicated healthcare professional with a passion for elderly care.",
      "Certified nurse assistant with 5 years of experience in post-op recovery.",
      "Specialized in dementia care and mobility assistance. Patient-focused.",
      "Available for weekend shifts. Fluent in English and Sinhala.",
      "Experienced in wound care and vital signs monitoring. Reliable and punctual.",
    ];

    final skillsPool = [
      "Vital Signs Monitoring (BP, Pulse, Temp)",
      "Wound Care & Dressing",
      "CPR / Basic Life Support (BLS)",
      "First Aid Administration",
      "Administering Injections (IM/SubQ)",
      "Catheter Care",
      "Mobility & Transfer Assistance",
      "Patient Bathing & Hygiene",
      "Feeding Assistance",
      "Medication Administration & Reminders",
      "Elderly Care",
      "Post-Operative Care",
      "Dementia / Alzheimer's Care",
      "Fluent in English",
      "Fluent in Sinhala",
      "Empathy & Bedside Manner",
    ];

    final weekdays = [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday",
    ];

    for (int i = 0; i < 50; i++) {
      // 1. Randomize Location (Kurunegala area)
      double lat = 7.4818 + (random.nextDouble() - 0.5) * 0.2;
      double lng = 80.3609 + (random.nextDouble() - 0.5) * 0.2;

      // 2. Randomize Skills (3 to 8 skills)
      List<String> selectedSkills = (List<String>.from(
        skillsPool,
      )..shuffle()).take(random.nextInt(6) + 3).toList();

      // 3. Randomize Availability (3 to 6 days per week)
      List<String> availableDays = (List<String>.from(
        weekdays,
      )..shuffle()).take(random.nextInt(4) + 3).toList();

      // 4. Randomize Working Hours (Standard 8-hour blocks)
      // Usually assistants provide a wider window than jobs
      Map<String, List<String>> workingTimes = {
        for (var day in availableDays) day: ["07:00", "19:00"],
      };

      String firstName = firstNames[random.nextInt(firstNames.length)];
      String lastName = lastNames[random.nextInt(lastNames.length)];

      Map<String, dynamic> assistantData = {
        'uid': 'dummy_assistant_${i + 500}', // Unique dummy UIDs
        'name': "$firstName $lastName",
        'email':
            "${firstName.toLowerCase()}.${lastName.toLowerCase()}@example.com",
        'role': 'assistant',
        'gender': Gender.values[random.nextInt(Gender.values.length)].name,
        'age': 22 + random.nextInt(20),
        'profilePicUrl':
            'https://i.pravatar.cc/150?u=${i + 500}', // Nice random avatars
        'nic': '${random.nextInt(999999999)}V',
        'address': "Assistant Home ${random.nextInt(50)}, Kurunegala",
        'location': GeoPoint(lat, lng),
        'skills': selectedSkills,
        'dailyRate': 1200 + (random.nextInt(12) * 200), // 1200 to 3600
        'experienceLevel': ExperienceLevel
            .values[random.nextInt(ExperienceLevel.values.length)]
            .name,
        'isVerified': random.nextBool(), // Some verified, some not
        'isBooked': false,
        'isSuspended': false,
        'rating': (30 + random.nextInt(21)) / 10.0, // 3.0 to 5.0 rating
        'bio': bioPool[random.nextInt(bioPool.length)],
        'workingTimes': workingTimes,
        'registrationComplete': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await userRef.doc(assistantData['uid']).set(assistantData);
    }
  }
}
