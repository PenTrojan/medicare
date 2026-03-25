# SmartMediLink Process Map

## Login/Register/RolePicker

- main.dart runs the app and creates the login page.
- 

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

## TODO:

* Make Skills Table and assistant pick skills from it
* Fix Geopoint Access
* Job Registration
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
