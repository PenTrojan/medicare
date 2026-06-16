# SmartMediLink Process Map

## Login/Register/RolePicker

- main.dart runs the app and creates the login page.
- 

## Class and Object Architecture

### User
 * class is abstract.
 * has 3 children.
  1. Assistant
  2. Seeker
  3. Admin

### Assistant



## UI Screen folder structure

lib/
├── screens/
│   ├── seeker/
│   │   ├── seeker_main.dart        // Bottom Nav Logic
│   │   ├── home_page.dart          // Dashboard/Summary
│   │   ├── add_job_page.dart       // Patient registration form
│   │   ├── job_details_page.dart   // Active job status & matches
│   │   └── payments_page.dart
│   ├── assistant/
│   │   ├── assistant_main.dart     // Bottom Nav Logic
│   │   ├── invitations_page.dart     // Available jobs feed
│   │   ├── my_job_page.dart        // Currently accepted job
│   │   └── payments_page.dart
│   ├── shared/
│   │   ├── messaging_page.dart     // Shared by both
│   │   └── profile_page.dart       // Shared by both


## Cloud functions file structure
functions/
├── src/
│   ├── handlers/
│   │   ├── jobs.ts      // matchJobToAssistants
│   │   └── profiles.ts  // getAssistantPublicProfile
│   ├── utils/
│   │   └── helpers.ts   // getDistance, isTimeCompatible
│   └── index.ts         // Main entry point (exports everything)

functions/src/
├── index.ts                     # System Switchboard Entry Point (Controller)
├── core/                        # THE DOMAIN LAYER (Pure OOP Entities & Contracts)
│   ├── Interfaces.ts            # Raw Database Data Schemas (DTOs)
│   ├── JobEntity.ts             # Encapsulates Job State Rules
│   ├── InvitationEntity.ts      # Encapsulates Lifecycle Actions
│   └── BillEntity.ts            # Encapsulates Financial Math Formulas
└── services/                    # THE APPLICATION SERVICE LAYER
    ├── MatchingEngine.ts        # Pure Geolocation & Schedule Algorithms
    └── TransactionContext.ts    # Abstraction Layer for DB Operations (Unit of Work)


## TODO:

* Make Skills Table and assistant pick skills from it // Done
* Fix Geopoint Access   // Done
* Job Registration    // Done
* Matching Logic
* Top Match listing
* Pick Assistant
* Assistant -accept job
* Assistant booked
* Calculate payment
* Messaging

### Extra
* Themes
* Admin Interface
* Implement interface (OOP)
