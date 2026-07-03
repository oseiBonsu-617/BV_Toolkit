# BV Toolkit

A Flutter mobile application for optometrists and vision therapists to perform binocular vision (BV) assessments, record patient test results, and generate clinical interpretations at the point of care.

## Features

### Clinical modules
| Module | What it does |
|---|---|
| **Phoria** | Classifies distance and near phoria against Morgan's norms |
| **Vergence & NPC** | Compares BI/BO vergence ranges to expected norms; evaluates NPC break and recovery |
| **Analysis** | Evaluates Sheard's and Percival's criteria; computes prism correction needed on failure |
| **Diagnosis** | Ranks differential BV diagnoses (CI, CE, divergence insufficiency, etc.) from entered findings |
| **Reference** | Quick-reference card of clinical norms and common BV conditions |

### Patient management
- Add, edit, and delete patient profiles (name, DOB, gender, MRN, contact, chief complaint, notes)
- Searchable patient list by name or MRN
- Per-patient session timeline

### Session recording
- Record any combination of test results per visit (phoria, AC/A, NPC, vergence, Sheard's, Percival's, diagnosis inputs)
- Live result computation as values are entered — no separate Calculate step
- Visit notes attached to each session
- Sessions stored locally and viewable with full recomputed results

### Authentication
- Server-backed clinician authentication with Firebase Authentication
- Email/password sign-up, hosted password verification, enforced email confirmation, password reset, and secure session persistence
- Firestore-backed clinician profile metadata for title/clinic details
- Per-clinician patient/session scoping through the authenticated Firebase user id
- Firebase Analytics, Crashlytics, and Remote Config are initialized at app startup

## Tech stack

- **Flutter 3.41** / **Dart 3.11** — iOS and Android
- **Material 3** with a custom green theme (`#1D9E75`)
- **provider** — `ChangeNotifier` + `ChangeNotifierProxyProvider` for scoped state
- **Firebase Auth** — hosted clinician identity, email verification, password reset
- **Cloud Firestore** — clinician profile metadata
- **Firebase Analytics** — route/event analytics
- **Firebase Crashlytics** — fatal Flutter and zone error reporting
- **Firebase Remote Config** — runtime product flags/defaults
- **sqflite** — local SQLite database (schema versioned, v1 → v2 migration)
- **intl** — date formatting
- **uuid** — ID generation

## Project structure

```
lib/
├── firebase_options.dart        # Firebase compile-time config
├── main.dart                    # App entry, MultiProvider setup, auth gate
├── theme.dart                   # Color constants, ThemeData builders
├── models/
│   ├── app_user.dart            # Authenticated user model
│   ├── patient.dart             # Patient record model
│   └── test_session.dart        # Session model with JSON data blob
├── services/
│   ├── auth_service.dart        # Registration, sign-in, profile, password change
│   ├── database_helper.dart     # SQLite singleton with schema migrations
│   ├── patient_service.dart     # Patient CRUD, search, per-user scoping
│   ├── product_infra_service.dart # Analytics, Crashlytics, Remote Config
│   └── session_service.dart     # Session save/delete/query with caching
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── patients/
│   │   ├── patient_list_screen.dart
│   │   ├── patient_form_screen.dart
│   │   ├── patient_detail_screen.dart   # Sessions timeline + New session FAB
│   │   ├── session_record_screen.dart   # Enter and save test results
│   │   └── session_detail_screen.dart   # View saved session with computed results
│   ├── home_screen.dart
│   ├── phoria_screen.dart
│   ├── vergence_screen.dart
│   ├── analysis_screen.dart
│   ├── diagnosis_screen.dart
│   ├── reference_screen.dart
│   └── profile_screen.dart
└── widgets/
    └── result_card.dart         # Shared UI components (ResultCard, AppCard, NumField, etc.)
```

## Getting started

**Prerequisites:** Flutter 3.41+, Xcode 15+ (for iOS), Android Studio (for Android).

```bash
# Install dependencies
flutter pub get

# Run on a connected device with Firebase configured
flutter run \
  --dart-define=FIREBASE_API_KEY=your-api-key \
  --dart-define=FIREBASE_PROJECT_ID=your-project-id \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=your-sender-id \
  --dart-define=FIREBASE_ANDROID_APP_ID=your-android-app-id \
  --dart-define=FIREBASE_IOS_APP_ID=your-ios-app-id

# Build a debug iOS archive (for wireless or Xcode deployment)
flutter build ios --debug \
  --dart-define=FIREBASE_API_KEY=your-api-key \
  --dart-define=FIREBASE_PROJECT_ID=your-project-id \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=your-sender-id \
  --dart-define=FIREBASE_IOS_APP_ID=your-ios-app-id
```

For iOS deployment on a physical device, open `ios/Runner.xcworkspace` in Xcode, select your device, and press ⌘R.

### Firebase setup

1. Create a Firebase project.
2. Add Android and iOS apps to the Firebase project.
3. Enable Email/Password in Authentication → Sign-in method.
4. Create Firestore in production mode and add a `users/{uid}` security rule scoped to `request.auth.uid`.
5. Enable Analytics, Crashlytics, and Remote Config in the Firebase console.
6. Configure the app using either:
   - FlutterFire CLI (`dart pub global activate flutterfire_cli`, then `flutterfire configure`), or
   - the `--dart-define` values shown above.
7. The app intentionally shows a configuration error screen if Firebase values are missing.

Example Firestore rule for clinician profile documents:

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Database schema

```sql
-- patients (v1)
CREATE TABLE patients (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  first_name TEXT NOT NULL, last_name TEXT NOT NULL,
  dob TEXT, gender TEXT, mrn TEXT,
  phone TEXT, email TEXT,
  chief_complaint TEXT, notes TEXT,
  created_at TEXT NOT NULL, updated_at TEXT NOT NULL
);

-- test_sessions (v2)
CREATE TABLE test_sessions (
  id TEXT PRIMARY KEY,
  patient_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  date TEXT NOT NULL,
  visit_note TEXT,
  data TEXT NOT NULL,   -- JSON blob of all recorded test values
  created_at TEXT NOT NULL
);
```

Session test data is stored as a flat JSON map (e.g. `ph_dist`, `npc_brk`, `bi_brk_d`, `sh_ph`) so any subset of tests can be recorded per visit without schema changes.
