# Medicare: System Architecture

This document explains how Medicare is built.

---

## 1. 🚁 High-Level Overview

*   **Frontend (The App):** Built with Flutter. It runs on Android (and iOS `WIP`) and updates in real-time.
*   **Backend (The Server):** Powered by Firebase Cloud Functions. It handles the matching, scheduling, and billing safely behind the scenes.
*   **Database:** Cloud Firestore. It stores all user profiles, jobs, and chat messages.

---

## 2. 📱 Frontend Structure (Flutter)

The app's code inside the `lib/` folder is neatly organized by user roles so things don't get mixed up.

### User Types
We have one main `AppUser` blueprint (Abstract class), which splits into three specific roles:
*   **Seekers:** Patients or families posting jobs.
*   **Assistants:** Caregivers accepting jobs and managing their availability.
*   **Admins:** Platform moderators who verify assistants.

---

## 3. ⚙️ Backend Structure (Cloud Functions)

- Inside `functions/src/`.
- Handles the complex calculations so the mobile app stays fast.
- Critical functions are handled entirely on the server to prevent outside tampering.
- The mobile app is not allowed to make complex or sensitive changes directly to the database.

### Smart Matching
* When a Seeker posts a job, the Matching Engine finds the best Assistants by looking at location, skills, and availability.
* It filters the assistant layer by layer and finally assigns a score to the remaining assistants.
* Then it sends a list of top matched to the seeker to pick from.

### Double-Booking Prevention
* When an assistant tries to accept a job, the system checks their personal calendar to make absolutely sure the new job doesn't overlap with one they already accepted.
* If two assistants try to accept the same job at the exact same time, the database uses "Atomic Transactions" to guarantee only the first person gets it.

### Automatic Billing
* When a job is accepted, the server generates a strict financial ledger and securely holds the funds in escrow.

* It automatically calculates precise hourly pay rates, platform commission fees, and taxes to prevent math errors on the app.

* If a care contract is canceled early by either party, the system instantly calculates exact pro-rata refunds for the Seeker and payouts for the Assistant based on the hours completed.

* Background tasks automatically close out finished jobs and release the funds, ensuring payments happen without manual intervention. (Executed everyday at midnight)

---
## 4. 🔐 Database Access Control

* The firestore rules decides what each user can and cannot see or change.
* Admins are given full access. But admin accounts cannot be created by a user. (only manually by the Firebase Console).

* Other users can create thier profiles, but only as a 'seeker' or an 'assistant' and cannot modify it to admin.
* Users can only view their profiles. Seekers can view assistant profiles.
* Users can view their bookings but cannot create or modify them. (done by the backend).
* Most of the other functional like billing are done by the backend and users don't have direct access to them.

---

## 5. 🗂️ Complete Project File Structure

> **Note on Documentation:** The initial file descriptions in this section were drafted with AI assistance. All descriptions are actively reviewed, modified, and maintained by the development team to ensure accuracy.

This section explains what each file does briefly to view at a glance.

### 📄 Documentation (`docs/`)
*   `ARCHITECTURE.md` - High-level system design and file structure (this file).
*   `registered_skills.md` - Master list of all medical skills used in the platform.

### 🧠 Backend Server (`functions/`)
*   **`src/billing/`**
    *   `cancelJobEarly.ts` - Calculates pro-rata refunds when a job ends early.
    *   `confirm_payment.ts` - Validates and processes the release of escrow funds.
    *   `generate_bill.ts` - Creates the initial ledger and calculates platform fees.
*   **`src/config/`**
    *   `BillingConfig.ts` - Global settings like the platform commission percentage.
*   **`src/core/`**
    *   `BillEntity.ts` - Pure business rules for financial calculations.
    *   `Interfaces.ts` - Database data blueprints (DTOs).
    *   `InvitationEntity.ts` - Rules for how job invites expire or get accepted.
    *   `JobEntity.ts` - Rules for job statuses and schedule management.
*   **`src/handlers/`**
    *   `getAssistantSearch.ts` - API endpoint for manually looking up caregivers.
    *   `getPublicAssistants.ts` - API endpoint to fetch basic profiles for seekers.
    *   `invitation_lifecycle.ts` - API endpoint to trigger or cancel invites.
    *   `jobLifecycle.ts` - API endpoint for background tasks (like closing finished jobs).
    *   `jobs.ts` - Main API endpoint for creating and updating job states.
    *   `profiles.ts` - API endpoint for updating user profiles safely.
*   **`src/services/`**
    *   `MatchingEngine.ts` - Algorithmic tool for calculating distance and skill overlaps.
    *   `TransactionContext.ts` - Database wrapper to prevent double-booking.
*   `src/index.ts` - The main switchboard that exports all endpoints to Firebase.
*   `package.json` / `package-lock.json` - Node.js dependencies and versions.
*   `tsconfig.json` / `tsconfig.dev.json` - TypeScript compiler settings.

### 📱 Frontend Application (`lib/`)
*   **`models/`** (Data Blueprints)
    *   `admin.dart` - Data structure for Admin users.
    *   `app_user.dart` - The core user blueprint everyone inherits from.
    *   `assistant.dart` - Data structure for Assistant users.
    *   `bill_model.dart` - Data structure for invoices and payments.
    *   `firestore_object.dart` - Helper for parsing database documents.
    *   `job.dart` - Data structure for care requests.
    *   `seeker.dart` - Data structure for Seeker users.
    *   `skill_manager.dart` - Helper for sorting and categorizing medical skills.
    *   `verification_file.dart` - Data structure for uploaded ID/Certificates.
*   **`screens/admin/`** (Moderator UI)
    *   `admin_assistant_profile.dart` - Detailed view of a caregiver for review.
    *   `admin_assistant_verification.dart` - Screen to approve/reject background checks.
    *   `admin_dashboard.dart` - Main control center overview.
    *   `admin_main.dart` - The bottom navigation shell for admins.
    *   `admin_seeker_profile.dart` - View of patient accounts.
    *   `admin_skills_page.dart` - Screen to add/remove platform-wide skills.
    *   `assistants_page.dart` - List of all registered caregivers.
    *   `full_screen_file_viewer.dart` - Image viewer for uploaded ID documents.
    *   `local_paginated_list.dart` - UI tool for loading long lists smoothly.
    *   `paginated_firebase_list.dart` - Database tool for fetching data in chunks.
    *   `seekers_page.dart` - List of all registered patients.
*   **`screens/assistant/`** (Caregiver UI)
    *   `assistant_dashboard.dart` - Overview of upcoming shifts and earnings.
    *   `assistant_jobs_page.dart` - History of completed and active care jobs.
    *   `assistant_main_page.dart` - The bottom navigation shell for assistants.
    *   `assistant_profile_page.dart` - Screen to edit bio, skills, and availability.
    *   `assistant_reg.dart` - Specific onboarding form for caregivers.
    *   `invitations_page.dart` - Feed of incoming job requests to accept/decline.
*   **`screens/seeker/`** (Patient UI)
    *   `add_job_page.dart` - Multi-step form to request care and set a schedule.
    *   `seeker_dashboard.dart` - Overview of active requests and active care.
    *   `seeker_find_list_view.dart` - UI to browse available assistants.
    *   `seeker_job_list_stream_view.dart` - Live-updating list of job statuses.
    *   `seeker_jobs_page.dart` - History of posted care requests.
    *   `seeker_main_page.dart` - The bottom navigation shell for seekers.
    *   `seeker_reg.dart` - Specific onboarding form for patients.
*   **`screens/shared/`** (Common UI)
    *   `billing_details_page.dart` - Screen showing the specific math/fees for a job.
    *   `chat_detail_screen.dart` - Individual messaging thread between two users.
    *   `job_details_page.dart` - Full breakdown of a specific care request.
    *   `messaging_page.dart` - Inbox list of all active chats.
    *   `payments_page.dart` - Global wallet view for history and earnings.
    *   `profile_page.dart` - Generic settings screen for common user details.
    *   `splash_page.dart` - The initial loading screen when the app opens.
*   **`screens/`** (Core Auth)
    *   `login.dart` - Login/Register page.-
    *   `role_picker.dart` - Page for picking the role as assistant/seeker.-
*   **`services/`** (External Connections)
    *   `admin_dashboard_service.dart` - Helper to fetch platform-wide stats.
    *   `auth_service.dart` - Wrapper for Firebase login/logout.
    *   `dummy_data_service.dart` - Script for generating fake users for testing. (used for development)
    *   `firebase_service.dart` - Core wrapper for all Firestore database reads/writes.
    *   `image_upload_service.dart` - Helper to send files to Firebase Storage.
*   **`themes/`**
    *   `app_colors.dart` - Defining color palette (blues, whites, etc.).-
    *   `app_theme.dart` - Global font and widget styling rules.
*   **`widgets/`** (Reusable Pieces)
    *   `assistant_booking_sheet.dart` - Pop-up UI for confirming a job acceptance.
    *   `assistant_profile_ui.dart` - For viewing public information about an assistant (by the seeker).-
    *   `availability_selector.dart` - For selecting dates and time ranges.-
    *   `billing_summary_view.dart` - Mini receipt UI for displaying totals.
    *   `dashboard_stat_card.dart` - Small metric boxes for the dashboards.
    *   `invoice_breakdown_card.dart` - UI card showing the split of fees/taxes.
    *   `job_list_view.dart` - Reusable scrolling list of care requests.
    *   `location_picker_sheet.dart` - For picking location using google maps.-
    *   `main_navigation_layout.dart` - Contains the bottom naviagtion bar style.-
    *   `profile_header_card.dart` - To show the profile image and name on the dashboards.-
    *   `section_header.dart` - Standardized title text for different screen sections.
    *   `skill_selector.dart` - For selecting skills of the assistant.-
*   `firebase_options.dart` - Auto-generated file connecting Flutter to your Firebase project.
*   `main.dart` - The starting point that runs the entire application.-
