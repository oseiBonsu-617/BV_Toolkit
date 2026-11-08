# Navigation redesign — design spec

- **Date:** 2026-11-08
- **Status:** Approved in conversation, awaiting spec review
- **Scope:** Navigation and information architecture of the BV Toolkit Flutter app (iOS + Android, phone)

## 1. Brief

### Goal
Make things **easier to find**. This is a navigation change, not a visual restyle.

### Users
Clinicians who use the app in two ways, often on the same day:
- **Patient sessions:** open or add a patient, record a session, get a diagnosis.
- **Quick tools:** check a value against norms, run Sheard's/Percival's or the ZCSBV plot, look up a condition.

Both must be quick to reach.

### Problems in the current app (observed on the iPhone 17 Pro simulator, 2026-11-08)
1. The bottom bar has six tabs. Five are separate calculators (Phoria, Vergence, Accommodation, Analysis, Diagnose).
2. **Patients** isn't in the bottom bar. It's only reachable from a card at the bottom of Home.
3. **Graphical analysis (ZCSBV)** is two levels deep: Analysis tab → "Open ZCSBV plot".
4. **Reference** is a small top-bar icon. While it's open, the bottom bar highlights **Home**, because `selectedIndex: _tab < 6 ? _tab : 0` falls back to Home.
5. **Profile** is only reachable through the avatar in the top-right corner.
6. Onboarding asks users to pick at least three tools "so BV Toolkit opens around your workflow". The picks (`_selectedTools`) and the goal (`_selectedGoal`) are never saved or used. Only `onboarding_complete` is stored.
7. Layout bugs:
   - On **Create account**, the status bar is white on a light background.
   - The **Gender** buttons on New patient are shifted right of the other fields.

### Success criteria
- Any tool, Patients or Reference is reachable in **one or two taps** from anywhere in the app.
- The bottom bar always shows the correct current location.
- Home opens with the tools the user said they use most.
- No calculation or clinical content changes.

### Constraints and assumptions
- Calculations, clinical content, colors and typography stay as they are.
- Phone layout only. iPad and landscape aren't a priority.
- Saved picks are stored per device, not per account.

## 2. App structure

### Tabs
The bottom bar has four tabs, always visible:

| # | Tab | First screen | Top bar |
|---|-----|--------------|---------|
| 0 | Home | `HomeScreen` (redesigned, §4) | "BV Toolkit" / "Clinical suite" + avatar |
| 1 | Patients | `PatientListScreen` | "Patients" + search icon + avatar; add-patient button bottom right |
| 2 | Tools | `ToolsHubScreen` (new, §3) | "Tools" + avatar |
| 3 | Reference | `ReferenceScreen` | "Reference" / "Norms & conditions" + avatar |

### Each tab keeps its own history
- Each tab has its own `Navigator`, keyed by a `GlobalKey<NavigatorState>`. The tab navigators sit inside an `IndexedStack`, so switching tabs keeps every tab's place.
- Screens pushed with `Navigator.of(context)` from inside a tab stay inside that tab, and the bottom bar stays visible. This covers:
  - patient detail, session record and session detail
  - assessment
  - the tool screen
- Tapping the tab that's already selected returns that tab to its first screen.
- **Full-screen overlays** push on the root navigator (`rootNavigator: true`), which hides the bottom bar. They are:
  - Profile
  - the New/Edit patient form
  - the Home-shortcuts picker

### Top bars
- `MainShell` no longer owns a shared `AppBar` or the `_titles` table. Each tab's first screen supplies its own `Scaffold` and `AppBar`.
- A shared `ProfileAvatarButton` widget (the existing initials circle, opening Profile on the root navigator) goes in the `actions` of all four tab top bars.
- The Reference book icon is removed from the top bar.

### Back behaviour
`MainShell` wraps everything in a `PopScope`:
1. If the current tab's navigator can pop, pop it.
2. Otherwise, if the current tab isn't Home, switch to Home.
3. Otherwise, let the system handle it (Android exits the app).

The iOS back swipe works inside each tab's navigator.

### Signing out
`MainShell` is rebuilt when `AuthService.isLoggedIn` changes. Its navigator keys are created in its `State`, so after a sign-out and new sign-in all four tabs start fresh. The next person never lands inside the previous user's patient.

### Files
| File | Change |
|------|--------|
| `lib/main.dart` | `MainShell` becomes the four-tab shell with per-tab navigators and the back logic above. The six-screen `IndexedStack`, shared `AppBar` and `_titles` are removed. |
| `lib/screens/patients/patient_list_screen.dart` | Becomes a tab's first screen. No back arrow (`automaticallyImplyLeading: false`), avatar added. The add-patient button opens the form on the root navigator. |
| `lib/screens/tools/reference_screen.dart` | Gets its own `Scaffold`/`AppBar`, since it no longer sits inside the shared top bar. Its content is unchanged. |
| `lib/widgets/profile_avatar_button.dart` | New. Extracted from `MainShell`. |

## 3. The Tools tab and tool screen

### Tools list (`lib/screens/tools/tools_hub_screen.dart`, new)
A grouped list. Each row shows an icon, a name and a one-line description, and opens the tool screen on that tool.

| Group | Tool id | Name | Description | Icon | Body widget |
|-------|---------|------|-------------|------|-------------|
| Measurements | `phoria` | Phoria & ratios | AC/A and CA/C | `remove_red_eye_outlined` | `PhoriaScreen` |
| Measurements | `vergence` | Vergence & NPC | Ranges vs. norms | `compare_arrows` | `VergenceScreen` |
| Measurements | `accommodation` | Accommodation | Norms & ranges | `zoom_in_outlined` | `AccommodationScreen` |
| Analysis | `analysis` | Sheard's & Percival's | Prism criteria | `balance_outlined` | `AnalysisScreen` |
| Analysis | `graphical` | Graphical analysis | ZCSBV plot | `stacked_line_chart_outlined` | Graphical analysis body (see below) |
| Diagnosis | `diagnose` | Diagnose | Ranked BV diagnosis | `medical_services_outlined` | `DiagnosisScreen` |

All three places that list tools read from this one table, defined as a `ToolDef` list in `lib/config/tools.dart` (new):
- the Tools list
- the tool screen's switcher strip
- the Home picks

### Tool screen (`lib/screens/tools/tool_workspace_screen.dart`, new)
Pushed inside the Tools tab with an initial tool id. It contains:
- **Top bar:** back arrow, the current tool's name and description, and the current tool's actions. Only Graphical analysis has an action ("Example").
- **Switcher strip:** a scrollable row of buttons under the top bar, one per tool (short labels: Phoria · Vergence · Acc. · Sheard's · ZCSBV · Diagnose). The current tool is highlighted. Tapping a button switches tools in place without pushing a new screen.
- **Body:** an `IndexedStack` holding all six tool bodies, so typed values survive switching tools and switching tabs. Values clear only when the user presses back to the Tools list, which disposes the screen.

### Opening a tool from elsewhere
`MainShell` provides `openTool(String toolId)`, through an `InheritedWidget` or a callback passed down. It:
1. switches to the Tools tab
2. pops the Tools navigator back to the Tools list
3. pushes the tool screen with the given tool id

Home tiles use this, so a tool always lives under Tools.

### Changes to existing tool code
- **`graphical_analysis_screen.dart`:**
  - Split into a body widget with no `Scaffold`, used by the tool screen.
  - Its "Example" action is exposed so the tool screen can show it in the top bar, for example as a `GlobalKey` to the body's state or an `onExample` hook.
  - The existing `GraphicalAnalysisScreen` route class is removed once nothing pushes it.
- **`analysis_screen.dart`:** the large "Graphical analysis" card with "Open ZCSBV plot" becomes a small "View on ZCSBV plot" link. It switches the tool screen to `graphical`, using an `InheritedWidget`/callback provided by the tool screen.
- **Phoria, Vergence, Accommodation and Diagnose:** no changes.

## 4. Home and saved tool picks

### Pickable items
The tool table above plus two tabs:

| id | Name | Opens |
|----|------|-------|
| six tool ids | as above | `openTool(id)` |
| `patients` | Patients | switch to the Patients tab |
| `reference` | Reference | switch to the Reference tab |

- **Defaults:** `phoria`, `vergence`, `graphical` (today's onboarding defaults).
- **Minimum:** 3, in both onboarding and the picker.

### Storage (`lib/services/preferences_service.dart`, new)
- A `ChangeNotifier` registered in the app's `MultiProvider`.
- Stores the picks as a string list under the `SharedPreferences` key `home_shortcuts`.
- API:
  - `List<String> homeShortcuts`: always valid. Defaults are used when nothing is saved, when the saved value can't be read, or when no saved id is valid.
  - `Future<void> setHomeShortcuts(List<String> ids)`: saves the list and notifies listeners.
- Unknown ids are dropped on read.
- Read and write failures are caught. The in-memory value is still updated and the UI is never blocked, matching how `onboarding_complete` is handled today.

### Home screen layout (`lib/screens/home_screen.dart`)
1. **Your tools:** a two-column grid of shortcut tiles for `homeShortcuts`, in saved order. The section heading has an **Edit** link that opens the picker.
2. **Recent patients:** up to three patients, ordered by `updatedAt` (newest first).
   - Tapping a patient switches to the Patients tab and pushes their detail screen there.
   - **See all** switches to the Patients tab.
   - With no patients, the section shows an **Add your first patient** button, which opens the patient form on the root navigator.
3. **Morgan's norms:** the existing table, moved below the two sections above.

`HomeScreen` no longer takes `onNavigate(int tab)`. It uses the shell's `openTool`, `openTab` and `openPatient` hooks instead.

### Keeping "recent" accurate
- `PatientService` gets a `recent` getter: the top three by `updatedAt`, newest first.
- When a session is saved, the patient's `updatedAt` is updated. In `session_record_screen.dart`, after `SessionService.save(...)` succeeds (currently around line 277), call `PatientService.touch(patientId)` (new). `touch` sets `updatedAt` to now, writes it to the database and re-sorts.

### Picker (`lib/widgets/home_shortcuts_picker.dart`, new)
- The same grid as onboarding page 2, showing the eight pickable items, with at least three required.
- Shown as a full-screen sheet with Save and Cancel.
- Opened from:
  - Home's **Edit** link
  - a new **Home shortcuts** row in Profile, under Edit profile

### Onboarding (`lib/screens/onboarding_screen.dart`)
- **Tool page:** offers the eight pickable items, in a 2×4 grid. The tiles for "Sessions" and "Plans" are removed.
- **Goals page:** removed. Onboarding becomes two pages: welcome, then tools. The dot indicator shows 2. `_next` finishes on page 1.
- `_selectedGoal` and `_goals` are removed.
- **Saving:** finishing onboarding saves the picks through `PreferencesService.setHomeShortcuts` before calling `onComplete`. "Log In" on page 0 skips the picker, so the defaults apply.

## 5. Layout fixes

1. **Status bar:** set `systemOverlayStyle` in `AppBarTheme` in `lib/theme.dart`:
   - light mode: dark icons (`SystemUiOverlayStyle.dark`)
   - dark mode: light icons

   This fixes `RegisterScreen`, whose `AppBar` has a transparent background.
2. **Gender buttons:** in `patient_form_screen.dart`, the `_genderPicker` column is wrapped so it takes the full row width (`SizedBox(width: double.infinity, …)`). The label and buttons then line up with the other fields.
3. **Wrong tab highlighted:** fixed by §2, since Reference is now a real tab.

## 6. Edge cases

| Case | Behaviour |
|------|-----------|
| Saved picks can't be read or saved | Defaults or the in-memory value are used. Nothing blocks. |
| A saved pick no longer exists | Dropped. If none are left, defaults are used. |
| Back pressed at the first screen of a non-Home tab | Switch to Home. |
| Back pressed at Home's first screen | System default (Android exits). |
| Sign out, then sign in | All tab histories reset. |
| A patient opened from Home is deleted | The detail screen already handles a missing patient (`getById` returns null, `patient_detail_screen.dart` around line 114). No change needed. |

## 7. Testing

### Automated (`test/`)
- **`navigation_shell_test.dart`:**
  - four tabs are shown
  - the correct tab is highlighted for each, Reference included
  - switching tabs keeps each tab's pushed screen
  - re-tapping the current tab returns it to its first screen
  - back from the first screen of a non-Home tab goes to Home
- **`tools_test.dart`:**
  - the Tools list shows all six tools
  - opening one shows the switcher strip
  - switching tools and back keeps a value typed into a field
- **`home_shortcuts_test.dart`:**
  - Home shows the saved picks
  - defaults appear when nothing is saved (`SharedPreferences.setMockInitialValues({})`)
  - editing the picks updates Home
  - finishing onboarding saves the picks
- **`preferences_service_test.dart`:**
  - reads the saved list
  - uses defaults when the list is empty
  - drops unknown ids
  - keeps the in-memory value when a write fails
- **`widget_test.dart`:** updated for the new shell. It still finds "BV Toolkit".
- The existing `assessment_engine_test.dart` and `graphical_analysis_test.dart` must still pass.
- `flutter analyze` must stay clean.

### Manual
In the iPhone simulator, screenshot every screen in light and dark mode and compare with the 2026-11-08 screenshots. Specifically check:
- the status bar on Create account
- the Gender row alignment
- the Reference tab highlight

## 8. Out of scope
- a visual restyle (colors, fonts, spacing system)
- iPad and landscape layouts
- syncing picks to the clinician's account (Firestore)
- a "New session" button on Home (a session needs a patient first)
- any change to calculations or clinical content
