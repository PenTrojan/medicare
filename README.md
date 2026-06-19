# SmartMediLink (Project Medicare)

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20WayDroid-green?style=flat)](#)

**SmartMediLink** (developed under the working project title **Medicare**) is an advanced medical assistant matching cross-platform mobile application. Built using Flutter and backed by a serverless Firebase infrastructure, the platform cleanly connects patients/seekers with qualified medical assistants based on granular matching criteria, including real-time geographical proximity, verified skill sets, precise daily scheduling, and budget bounds.

---

## 🚀 Core Architectural Features

*   **Dual-Role Subsystems:** Independent workflows and data models mapped for both Medical Seekers (Patients) and Professional Assistants.
*   **Dynamic Matrix Scheduling:** Robust availability tracking mapped across exact weekday time frames (using millisecond-padded UTC string ranges).
*   **Geospatial Proximity Calculation:** In-app map matching built on high-precision `GeoPoint` coordinates with dynamic visual fallback routines.
*   **Serverless Data Management:** Reactive synchronization handled via real-time Cloud Firestore pipelines and secure structural schema models wrapped inside defensive `try-catch` factories.

---

## 🛠️ Tech Stack & Tooling

| Layer | Technology | Purpose |
| :--- | :--- | :--- |
| **Frontend Framework** | Flutter (Dart) | Cross-platform UI compilation & state management |
| **Backend / Database** | Cloud Firestore | Real-time reactive document store |
| **Authentication** | Firebase Auth | Secure identity verification & token validation |
| **Storage Layer** | Firebase Cloud Storage | Upload management for profile assets & documentation proofs |
| **Location Processing** | Geolocator / Google Maps API | Precise coordinates translation & custom gesture mapping |

---

## 📦 Project Structure

```text
medicare/
├── android/
│   ├── app/
│   │   ├── google-services.json    # Firebase registration configurations
│   │   └── build.gradle.kts       # Custom Kotlin DSL text-parsed environment configuration
│   └── local.properties            # Machine-specific environment variables (API Keys)
├── lib/
│   ├── models/
│   │   ├── app_user.dart           # Safe multi-role industrial data factory schema
│   │   ├── assistant.dart          # Medical assistant registration definitions
│   │   └── job.dart                # Patient posting and metadata constraints
│   ├── pages/
│   │   ├── assistant/              # Onboarding pipelines & verification forms
│   │   └── jobs/                   # Job posting workflows & interactive selectors
│   └── widgets/
│       ├── availability_selector.dart   # Granular calendar time-frame picker
│       ├── location_picker_sheet.dart  # Modal Google Map touch intercept viewport
│       └── skill_selector.dart         # Multi-tag professional qualifications chip array
└──
