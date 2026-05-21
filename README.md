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
- Local multi-user support — each clinician's patients and sessions are kept separate
- Credentials stored in the iOS Keychain / Android Keystore via `flutter_secure_storage`
- SHA-256 password hashing with a per-user UUID salt

## Tech stack

- **Flutter 3.41** / **Dart 3.11** — iOS and Android
- **Material 3** with a custom green theme (`#1D9E75`)
- **provider** — `ChangeNotifier` + `ChangeNotifierProxyProvider` for scoped state
- **sqflite** — local SQLite database (schema versioned, v1 → v2 migration)
- **flutter_secure_storage** — encrypted credential storage
- **crypto** — SHA-256 password hashing
- **intl** — date formatting
- **uuid** — ID generation

## Project structure

```
lib/
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

# Run on a connected device
flutter run

# Build a debug iOS archive (for wireless or Xcode deployment)
flutter build ios --debug
```

For iOS deployment on a physical device, open `ios/Runner.xcworkspace` in Xcode, select your device, and press ⌘R.

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
