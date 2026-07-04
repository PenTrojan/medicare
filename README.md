# SmartMediLink (Project Medicare)

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20Functions%20%7C%20Firestore-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green?style=flat)](#)
[![Architecture](https://img.shields.io/badge/Architecture-Domain_Driven_Design-blueviolet?style=flat)](#)

**SmartMediLink** (developed under the working title **Project Medicare**) is an advanced, automated medical assistant matching platform. Built using Flutter and backed by a serverless Firebase infrastructure, the platform cleanly connects patients (Seekers) with qualified medical assistants. 

Moving beyond basic job boards, SmartMediLink utilizes a custom matching engine and automated lifecycle orchestration to handle granular scheduling, geospatial routing, and complex pro-rata financial escrow splits hour-by-hour.

---

## 📖 Overview

The core problem in the gig-economy healthcare sector is managing the strict constraints of medical requirements, precise hourly schedules, and fair financial distribution when life happens (e.g., sickness, cancellations, or delays).

SmartMediLink solves this through a strict **Domain-Driven Design (DDD)** backend architecture. By isolating "Managers" (Cloud Functions) from "Brains" (Domain Entities), the system provides:
* **Hyper-Precise Matching:** Assistants can stack back-to-back shifts on the same day. The engine uses Base-10 integer conversion and the Overlap Theorem to match availability down to the minute.
* **Automated Lifecycles:** Nightly background CRON jobs seamlessly activate scheduled care contracts, close out completed ones, and release escrow funds without manual intervention.
* **Immutable Financial Ledgers:** Strict tracking of platform fees, taxes, and pro-rata hourly splits if a contract is terminated early by either party.

---
## 📸 App Preview

| Seeker Dashboard | Assistant Matching | Escrow Billing |
| :---: | :---: | :---: |
| <img src="docs/assets/seeker_home.png" width="250"/> | <img src="docs/assets/matching.png" width="250"/> | <img src="docs/assets/billing.png" width="250"/> |

---

## 🚀 Core Platform Features

### For Seekers (Patients / Families)
* **Granular Care Requests:** Post detailed jobs specifying required medical skills, patient conditions, budget bounds, and exact hourly schedules per weekday.
* **Geospatial Proximity Calculation:** In-app map matching built on high-precision `GeoPoint` coordinates with dynamic visual fallback routines to find nearby caregivers.
* **Smart Matching:** Receive a ranked list of top assistants based on a blended score of skill overlap and geographic distance.
* **Financial Security:** Funds are securely held in an escrow-style ledger and only released upon successful completion of the schedule. Early cancellations automatically trigger precise, shift-accurate pro-rata refunds.

### For Assistants
* **Dynamic Matrix Scheduling:** Robust availability tracking mapped across exact weekday time frames (using millisecond-padded UTC string ranges).
* **Automated Calendar Management:** Accepting a job instantly blocks those specific hours in a strict `bookings` sub-collection, preventing double-booking while leaving the rest of the day open for other matches.
* **Coverage Requests (Sub-Contracting):** An integrated safety net. If an assistant falls ill, the platform seamlessly carves out the missed days from the financial ledger, generates a "Child Job," and automatically routes a substitute caregiver for those specific days.

---

## 🏗️ System Architecture

SmartMediLink is built on a strict separation of concerns, heavily utilizing Firebase Cloud Functions as a powerful backend orchestrator.

👉 **[Click here to view the complete System Architecture & File Structure](docs/ARCHITECTURE.md)** 👈

### The Backend Engine (Node.js / TypeScript)
The backend enforces a strict **1:1:1 Relationship** (`1 Job = 1 Assistant = 1 Financial Bill`). 
* **Gateway Callable Functions:** Secure HTTPS endpoints (`acceptInvitation`, `cancelJobEarly`) that handle authentication, authorization, and database transactions.
* **Domain Entities (`JobEntity`, `BillEntity`):** Pure, untainted business logic classes. These entities handle the complex math (like converting shift strings to billable days and calculating pro-rata splits) and return immutable objects to the orchestrators.
* **Matching Engine:** A stateless utility utilizing the Haversine formula for distance and the Overlap Theorem for schedule compatibility.
* **Lifecycle CRON:** An automated `jobLifecycle.ts` engine that wakes up nightly to handle natural state transitions (Pending -> In Progress -> Completed) and clean up database indexing via "Hard Deletes" on expired calendar blocks.

### The Frontend App (Flutter)
* **Dual-Role Subsystems:** Independent workflows, UI/UX, and data models mapped for both Seekers and Assistants.
* **Serverless Data Management:** Reactive synchronization handled via real-time Cloud Firestore `StreamBuilders`.

---

## 🛠️ Tech Stack & Tooling

| Layer | Technology | Purpose |
| :--- | :--- | :--- |
| **Frontend Framework** | Flutter (Dart) | Cross-platform UI compilation & reactive state management |
| **Backend Orchestration**| Firebase Cloud Functions | TypeScript-based serverless execution, CRON jobs, and secure gateways |
| **Database** | Cloud Firestore | NoSQL document store utilizing `runTransaction` for atomic, ACID-compliant operations |
| **Authentication** | Firebase Auth | Secure identity verification & token validation |
| **Storage Layer** | Firebase Cloud Storage | Upload management for profile assets & documentation proofs |
| **Location Processing** | Geolocator / Google Maps API | Precise coordinates translation & custom gesture mapping |

---

## ⚙️ Getting Started (Local Development)

### Prerequisites

* Flutter SDK (3.x+)
* Node.js (18+)
* Firebase CLI (`npm install -g firebase-tools`)

### Standard Setup Instructions

1. **Clone the repository:**
```bash
git clone https://github.com/penTrojan/medicare.git
```


2. **Configure Firebase (Frontend):**
* Run `flutterfire configure` to link the app to your Firebase project and automatically generate the necessary `google-services.json` and `GoogleService-Info.plist` files.

3. **Configure Local Environment Keys (Maps API):**
   The Google Maps SDK key is securely decoupled from the codebase to prevent exposure. Create or open the `local.properties` file inside your `android/` directory using your editor of choice:
   ```bash
   nvim android/local.properties
   ```
   Add your Google Maps API key to the bottom of the file:
   ```
     MAPS_API_KEY=AIzaSyYourActualKeyGoesHere
   ```
   Note: This file is included in `.gitignore` and will never be tracked by Git.
   
5. **Configure Backend Functions:**
```bash
cd functions
npm install
```

5. **Deploy the Database Rules & Functions:**
```bash
firebase deploy --only firestore:rules
firebase deploy --only functions

```


6. **Run the App:**
```bash
cd ..
flutter run

```



---

### ❄️ Advanced: Reproducible Development Environment (Nix)

For developers on Linux (especially those utilizing declarative or immutable systems), this repository includes a fully sandboxed, reproducible development shell. Instead of polluting your global system packages, the included `shell.nix` spins up an isolated File Hierarchy Standard (FHS) environment containing the exact required toolchain.

**Key Environment Features:**

* **Dynamic Android Composition:** Automatically provisions the precise Android SDKs, NDKs (`28.2.13676358`), and Build Tools (`35.0.0`, `34.0.0`) required for compilation without manual Android Studio setup.
* **Mutable Flutter Overlay:** Generates a dynamically linked, writable mock Flutter root (`.gradle_home/mock_flutter`) to seamlessly bypass Nix store read-only constraints, allowing standard Gradle build mutations.
* **Full-Stack Tooling:** Pre-loads `nodejs_22`, `firebase-tools`, and `jdk17` so you can orchestrate the Firebase backend and Flutter frontend from a single terminal.

#### Activating the Workspace

Ensure you have the Nix package manager installed, navigate to the project root, and execute:

```bash
nix-shell
```

If you need to tweak the toolchain versions to match your local setup, you can edit the configuration file directly:

```bash
nvim shell.nix
```
