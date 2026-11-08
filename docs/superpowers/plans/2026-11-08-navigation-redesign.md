# Navigation Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the six-calculator bottom bar with four tabs (Home · Patients · Tools · Reference). Add a Tools list and a tool screen with a switcher strip. Rebuild Home around the tool picks saved during onboarding.

**Architecture:**
- `MainShell` holds four tab `Navigator`s inside an `IndexedStack`, under a `PopScope`.
- A `ShellScope` `InheritedWidget` gives screens `openTab` / `openTool` / `openPatient` / `openShortcut`.
- Tool and shortcut definitions live in one config table.
- A `PreferencesService` (a `ChangeNotifier` backed by `SharedPreferences`) stores the Home picks.

**Tech Stack:** Flutter 3.41 / Dart 3.11, Material 3, provider ^6.1.0, shared_preferences ^2.5.5, sqflite, flutter_test.

**Spec:** `docs/superpowers/specs/2026-11-08-navigation-redesign-design.md`

## Global Constraints

- No change to calculations or clinical content. `assessment_engine_test.dart` and `graphical_analysis_test.dart` must keep passing.
- Colors, typography and `kPrimary` (`#1D9E75`) stay as they are. No visual restyle.
- Phone layout only.
- `SharedPreferences` key for the picks: `home_shortcuts`.
- Default picks, in order: `phoria`, `vergence`, `graphical`.
- At least 3 picks, in onboarding and in the picker.
- Tab order: Home (0) · Patients (1) · Tools (2) · Reference (3).
- Profile, the New/Edit patient form and the shortcuts picker push on the root navigator, which hides the bottom bar.
- `flutter analyze` must report "No issues found!" after every task.
- Commit messages end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Work on branch `navigation-redesign`. The spec is already committed there.

## Review Focus

1. **Sign out, then sign in again:** the user expects every tab to start fresh, with no previous patient or tool screen showing. Test in Task 4.
2. **Saved picks with duplicates or unknown ids** (for example from a future rename): the user expects Home to show each valid pick once, or the defaults if none are valid. Test in Task 1.
3. **Cancelling the shortcuts picker:** the user expects Home to be unchanged and nothing saved. Test in Task 5.
4. **Onboarding finished via "Log In"** (the picker is skipped): the user expects the default picks on Home. Test in Task 6.
5. **Opening a tool from Home while another tool is already open in the Tools tab:** the user expects the requested tool to open and the bottom bar to show Tools. Test in Task 4.

---

### Task 1: Tool config and PreferencesService

**Files:**
- Create: `lib/config/tools.dart`
- Create: `lib/services/preferences_service.dart`
- Test: `test/preferences_service_test.dart`

**Interfaces:**
- Produces: the following, in `lib/config/tools.dart`:
  - `class ToolDef { final String id, name, shortLabel, description, group; final IconData icon; const ToolDef({...}); }`
  - `const List<ToolDef> kTools`. Six entries, in this order, with these exact values:

    | id | name | shortLabel | description | group | icon |
    |----|------|------------|-------------|-------|------|
    | `phoria` | Phoria & ratios | Phoria | AC/A and CA/C | Measurements | `Icons.remove_red_eye_outlined` |
    | `vergence` | Vergence & NPC | Vergence | Ranges vs. norms | Measurements | `Icons.compare_arrows` |
    | `accommodation` | Accommodation | Acc. | Norms & ranges | Measurements | `Icons.zoom_in_outlined` |
    | `analysis` | Sheard's & Percival's | Sheard's | Prism criteria | Analysis | `Icons.balance_outlined` |
    | `graphical` | Graphical analysis | ZCSBV | ZCSBV plot | Analysis | `Icons.stacked_line_chart_outlined` |
    | `diagnose` | Diagnose | Diagnose | Ranked BV diagnosis | Diagnosis | `Icons.medical_services_outlined` |

  - `const List<String> kToolGroups = ['Measurements', 'Analysis', 'Diagnosis'];`
  - `ToolDef? toolById(String id)`
  - `class ShortcutDef { final String id, name; final IconData icon; const ShortcutDef(...); }`
  - `final List<ShortcutDef> kShortcuts`: the six tools (using `ToolDef.name` and `ToolDef.icon`), then `patients` (Patients, `Icons.people_outline`) and `reference` (Reference, `Icons.menu_book_outlined`). Eight entries.
  - `const List<String> kDefaultShortcuts = ['phoria', 'vergence', 'graphical'];`
  - `const int kMinShortcuts = 3;`
- Produces: the following, in `lib/services/preferences_service.dart`:
  - `class PreferencesService extends ChangeNotifier`
  - `PreferencesService({Future<SharedPreferences> Function()? prefs})`. Defaults to `SharedPreferences.getInstance`.
  - `static const homeShortcutsKey = 'home_shortcuts';`
  - `List<String> get homeShortcuts`. Always cleaned up: unknown ids dropped, duplicates removed (first occurrence kept). Falls back to `kDefaultShortcuts` when nothing valid is left.
  - `Future<void> load()`. Reads the key. Any error leaves the defaults in place. Notifies listeners.
  - `Future<void> setHomeShortcuts(List<String> ids)`. Cleans up the list and updates it in memory, notifies listeners, then writes. Write errors are caught and swallowed.

- [ ] **Step 1: Write the failing tests** in `test/preferences_service_test.dart`. Call `SharedPreferences.setMockInitialValues(...)` in each test.

```dart
test('defaults when nothing saved', () async {
  SharedPreferences.setMockInitialValues({});
  final s = PreferencesService(); await s.load();
  expect(s.homeShortcuts, ['phoria', 'vergence', 'graphical']);
});
test('reads saved list in order', () async {
  SharedPreferences.setMockInitialValues({'home_shortcuts': ['diagnose', 'reference', 'analysis']});
  final s = PreferencesService(); await s.load();
  expect(s.homeShortcuts, ['diagnose', 'reference', 'analysis']);
});
test('drops unknown ids and duplicates', () async {
  SharedPreferences.setMockInitialValues({'home_shortcuts': ['plans', 'diagnose', 'diagnose', 'sessions', 'patients']});
  final s = PreferencesService(); await s.load();
  expect(s.homeShortcuts, ['diagnose', 'patients']);
});
test('only unknown ids falls back to defaults', () async {
  SharedPreferences.setMockInitialValues({'home_shortcuts': ['plans', 'sessions']});
  final s = PreferencesService(); await s.load();
  expect(s.homeShortcuts, kDefaultShortcuts);
});
test('setHomeShortcuts persists and notifies', () async {
  SharedPreferences.setMockInitialValues({});
  final s = PreferencesService(); await s.load();
  var notified = 0; s.addListener(() => notified++);
  await s.setHomeShortcuts(['graphical', 'patients', 'diagnose']);
  expect(s.homeShortcuts, ['graphical', 'patients', 'diagnose']);
  expect(notified, 1);
  final again = PreferencesService(); await again.load();
  expect(again.homeShortcuts, ['graphical', 'patients', 'diagnose']);
});
test('storage failure keeps in-memory value and never throws', () async {
  final s = PreferencesService(prefs: () async => throw Exception('disk'));
  await s.load();
  expect(s.homeShortcuts, kDefaultShortcuts);
  await s.setHomeShortcuts(['diagnose', 'reference', 'analysis']);
  expect(s.homeShortcuts, ['diagnose', 'reference', 'analysis']);
});
test('kTools and kShortcuts shape', () {
  expect(kTools.map((t) => t.id), ['phoria', 'vergence', 'accommodation', 'analysis', 'graphical', 'diagnose']);
  expect(kShortcuts.length, 8);
  expect(kShortcuts.map((s) => s.id).skip(6), ['patients', 'reference']);
});
```

- [ ] **Step 2: Run the tests and check they fail.**
  - Run: `flutter test test/preferences_service_test.dart`
  - Expected: compilation errors, because the imports don't exist yet.
- [ ] **Step 3: Create `lib/config/tools.dart` and `lib/services/preferences_service.dart`** with the interfaces above.
- [ ] **Step 4: Register the service in `main()`** (`lib/main.dart`): add `ChangeNotifierProvider(create: (_) => PreferencesService()..load())` to the `MultiProvider` list. In `test/widget_test.dart`, add the same provider.
- [ ] **Step 5: Run the tests and check they pass.**
  - Run: `flutter test test/preferences_service_test.dart && flutter analyze`
  - Expected: all pass, and "No issues found!"
- [ ] **Step 6: Commit.**
  - `git add lib/config/tools.dart lib/services/preferences_service.dart lib/main.dart test/preferences_service_test.dart test/widget_test.dart`
  - Message: `feat: add tool config and PreferencesService for home shortcuts`

---

### Task 2: Recent patients and refreshing "last updated" on session save

**Files:**
- Modify: `lib/services/patient_service.dart`
- Modify: `lib/screens/patients/session_record_screen.dart:277-280`
- Test: `test/patient_recent_test.dart`

**Interfaces:**
- Produces: the following, in `PatientService`:
  - `static List<Patient> recentOf(Iterable<Patient> all, {int limit = 3})`: newest `updatedAt` first, at most `limit` patients.
  - `List<Patient> get recent => recentOf(_patients);` Ignores the search query.
  - `Future<void> touch(String patientId)`. Does nothing if the id is unknown. Otherwise `await update(p.copyWith())`, because `copyWith` already sets `updatedAt` to now (`patient.dart:76`).

- [ ] **Step 1: Write the failing test.**
  - Build four `Patient`s with `updatedAt` = 2026-01-01, 2026-03-01, 2026-02-01 and 2026-04-01 (ids `a`, `b`, `c`, `d`).
  - Assert `PatientService.recentOf(list).map((p) => p.id)` equals `['d', 'b', 'c']`.
  - Assert `recentOf([])` is empty.
- [ ] **Step 2: Run the test and check it fails.**
  - Run: `flutter test test/patient_recent_test.dart`
  - Expected: FAIL, because `recentOf` isn't defined.
- [ ] **Step 3: Implement `recentOf`, `recent` and `touch`** in `lib/services/patient_service.dart`.
- [ ] **Step 4: Call `touch` after a session is saved.** In `session_record_screen.dart`, right after the `SessionService.save(...)` call succeeds and before `Navigator.pop`, add:
  `await context.read<PatientService>().touch(widget.patientId);`
  Check `mounted` first, as the surrounding code already does.
- [ ] **Step 5: Run the tests and check they pass.**
  - Run: `flutter test && flutter analyze`
  - Expected: all pass, and "No issues found!"
- [ ] **Step 6: Commit.**
  - Message: `feat: recent patients and touch on session save`

---

### Task 3: Tools list and tool screen

**Files:**
- Create: `lib/screens/tools/tools_hub_screen.dart`
- Create: `lib/screens/tools/tool_workspace_screen.dart`
- Modify: `lib/screens/tools/graphical_analysis_screen.dart`: split into a body with no `Scaffold`
- Modify: `lib/screens/tools/analysis_screen.dart`: the card around line 203 becomes a link
- Test: `test/tools_test.dart`

**Interfaces:**
- Consumes: `kTools`, `kToolGroups`, `toolById` (Task 1); `appRoute` (`lib/theme.dart:107`).
- Produces:
  - `class ToolsHubScreen extends StatelessWidget`
    - Its own `Scaffold`, with `AppBar(title: Text('Tools'), automaticallyImplyLeading: false)`. Task 4 adds the avatar.
    - A section header per group, then one row per tool, with `Key('tool-row-<id>')`.
    - Tapping a row runs `Navigator.of(context).push(appRoute(ToolWorkspaceScreen(initialToolId: id)))`.
  - `class ToolWorkspaceScreen extends StatefulWidget { const ToolWorkspaceScreen({super.key, required this.initialToolId}); final String initialToolId; }`
    - **Top bar:** title column (tool `name`, and `description` at fontSize 11), plus actions.
    - **Actions:** only when the current tool is `graphical`, a `TextButton(key: Key('tool-example'), child: Text('Example'))` that calls `_graphicalKey.currentState?.loadExample()`.
    - **Switcher strip:** a horizontal `ListView` of `ChoiceChip`s, labelled with `shortLabel`, with `Key('tool-chip-<id>')`, selected when the tool is current.
    - **Body:** an `IndexedStack` over the six bodies, in `kTools` order: `PhoriaScreen()`, `VergenceScreen()`, `AccommodationScreen()`, `AnalysisScreen()`, `GraphicalAnalysisBody(key: _graphicalKey)`, `DiagnosisScreen()`.
    - The body is wrapped in `ToolWorkspaceScope`.
  - `class ToolWorkspaceScope extends InheritedWidget { final void Function(String toolId) switchTo; static ToolWorkspaceScope? maybeOf(BuildContext c); }`
  - `class GraphicalAnalysisBody extends StatefulWidget` with public `GraphicalAnalysisBodyState` and a `void loadExample()` method. This is the old `_loadExample`.
    - Its content is the old screen's `body`, with no `Scaffold`/`AppBar`.
    - Delete `GraphicalAnalysisScreen` once `analysis_screen.dart` no longer pushes it.
  - In `analysis_screen.dart`, the "Graphical analysis" card becomes a single `TextButton.icon(key: Key('analysis-zcsbv-link'), icon: Icon(Icons.open_in_full), label: Text('View on ZCSBV plot'))`. It calls `ToolWorkspaceScope.maybeOf(context)?.switchTo('graphical')`.

- [ ] **Step 1: Write the failing tests** in `test/tools_test.dart`. Pump `MaterialApp(theme: buildTheme(Brightness.light), home: const ToolsHubScreen())`.
  - `hub lists six tools`: each `Key('tool-row-<id>')` for the six ids `findsOneWidget`, and the texts 'Measurements', 'Analysis' and 'Diagnosis' are each found.
  - `opening a tool shows workspace with switcher`:
    - tap `Key('tool-row-phoria')`, then `pumpAndSettle`
    - expect `find.text('Phoria & ratios')` and `Key('tool-chip-graphical')`
  - `switching tools keeps typed values`:
    - open phoria
    - `enterText(find.byType(TextField).first, '7')`
    - tap `tool-chip-vergence`, then tap `tool-chip-phoria`
    - expect `find.text('7')` `findsOneWidget`
  - `Example action only on graphical`:
    - open phoria, expect `Key('tool-example')` `findsNothing`
    - tap `tool-chip-graphical`, expect it `findsOneWidget`
    - tap it, `pumpAndSettle`, expect `find.text('Plot & analyse')` still found and no exception
  - `analysis link switches to graphical`:
    - open analysis
    - tap `Key('analysis-zcsbv-link')`
    - expect the top bar title `find.text('Graphical analysis')`
- [ ] **Step 2: Run the tests and check they fail.**
  - Run: `flutter test test/tools_test.dart`
  - Expected: compilation errors, because the screens don't exist yet.
- [ ] **Step 3: Split `graphical_analysis_screen.dart`** into `GraphicalAnalysisBody` and its state, as described above.
- [ ] **Step 4: Create `ToolWorkspaceScope` and `ToolWorkspaceScreen`** in `tool_workspace_screen.dart`.
- [ ] **Step 5: Create `ToolsHubScreen`.**
- [ ] **Step 6: Replace the card in `analysis_screen.dart`** with the link. Remove the `GraphicalAnalysisScreen` import.
- [ ] **Step 7: Run the tests and check they pass.**
  - Run: `flutter test && flutter analyze`
  - Expected: all pass, including `graphical_analysis_test.dart`, and "No issues found!"
- [ ] **Step 8: Commit.**
  - Message: `feat: Tools list and tool screen with switcher strip`

---

### Task 4: Four-tab shell

**Files:**
- Create: `lib/screens/shell/shell_scope.dart`
- Create: `lib/screens/shell/main_shell.dart`. `MainShell` moves here from `lib/main.dart`.
- Create: `lib/widgets/profile_avatar_button.dart`
- Modify: `lib/main.dart`: delete the old `MainShell` (around lines 222–360) and import the new one. `_AuthGate` keeps returning `const MainShell()`.
- Modify: `lib/screens/patients/patient_list_screen.dart`: no back arrow, avatar added, the add-patient button pushes the form with `rootNavigator: true`.
- Modify: `lib/screens/patients/patient_detail_screen.dart:126-128`: Edit pushes `PatientFormScreen` with `rootNavigator: true`.
- Modify: `lib/screens/tools/reference_screen.dart`: wrap in its own `Scaffold` + `AppBar` ("Reference" / "Norms & conditions", avatar, `automaticallyImplyLeading: false`).
- Modify: `lib/screens/tools/tools_hub_screen.dart`: add the avatar to the `AppBar` actions.
- Modify: `lib/screens/home_screen.dart`: minimal changes only. Remove the `onNavigate` parameter, add its own `Scaffold` + `AppBar` ("BV Toolkit" / "Clinical suite", avatar), and change the existing cards to call `ShellScope.of(context).openShortcut(id)`. The full redesign is Task 5.
- Test: `test/navigation_shell_test.dart`, and update `test/widget_test.dart`

**Interfaces:**
- Consumes: `ToolsHubScreen`, `ToolWorkspaceScreen` (Task 3); `toolById` (Task 1).
- Produces:
  - `abstract final class ShellTab { static const home = 0, patients = 1, tools = 2, reference = 3; }`
  - `class ShellScope extends InheritedWidget`, with:
    - `final void Function(int tab) openTab;`
    - `final void Function(String toolId) openTool;`
    - `final void Function(String patientId) openPatient;`
    - `static ShellScope of(BuildContext c)`
    - `void openShortcut(String id)`: calls `openTool` when `toolById(id) != null`, otherwise `openTab(ShellTab.patients)` for `'patients'` or `openTab(ShellTab.reference)` for `'reference'`.
    - `updateShouldNotify` returns false, because the callbacks are stable.
  - `class ProfileAvatarButton extends StatelessWidget`: the initials circle from the old `MainShell`. On tap: `Navigator.of(context, rootNavigator: true).push(appRoute(const ProfileScreen()))`. Tooltip `'Profile'`.
  - `MainShell` behaviour:
    - **Tab stacks:** four `GlobalKey<NavigatorState>`, created in `State`. Each tab is a `Navigator(key: …, onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => root))`, with roots `HomeScreen()`, `PatientListScreen()`, `ToolsHubScreen()`, `ReferenceScreen()`.
    - **Layout:** `IndexedStack` + `NavigationBar` with destinations Home / Patients / Tools / Reference. Icons: `home_outlined`/`home`, `people_outline`/`people`, `handyman_outlined`/`handyman`, `menu_book_outlined`/`menu_book`.
    - **Tapping the current tab:** `popUntil((r) => r.isFirst)` on that tab.
    - **`openTool(id)`:** switch to tools, `popUntil` first, then push `appRoute(ToolWorkspaceScreen(initialToolId: id))` on the tools navigator.
    - **`openPatient(id)`:** switch to patients, `popUntil` first, then push `appRoute(PatientDetailScreen(patientId: id))`.
    - **`PopScope(canPop: false)`**, which handles back:
      1. pop the current tab's navigator if it can
      2. otherwise, if the tab isn't home, switch to home
      3. otherwise, `SystemNavigator.pop()`

- [ ] **Step 1: Write the failing tests** in `test/navigation_shell_test.dart`.
  - Use a helper `pumpShell(tester)` that pumps `MultiProvider` with `AuthService()`, `PatientService()`, `SessionService()`, and `PreferencesService()..load()` after `SharedPreferences.setMockInitialValues({})`, wrapping `MaterialApp(theme: buildTheme(Brightness.light), home: const MainShell())`.
  - Find tab labels with `find.descendant(of: find.byType(NavigationBar), matching: find.text(label))`.
  - Tests:
    - `four tabs`: each of Home / Patients / Tools / Reference is found once inside the `NavigationBar`, and there's no "Phoria" label in it.
    - `highlight follows tab, including Reference`:
      - tap Reference
      - `tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex == 3`
      - and `find.text('Norms & conditions')` is found
    - `tab keeps its place and typed values`:
      - tap Tools, tap `tool-row-phoria`, enter '7' in the first `TextField`
      - tap Home, then tap Tools
      - expect `Key('tool-chip-phoria')` and `find.text('7')`
    - `re-tapping current tab returns to root`:
      - continuing from the previous state, tap Tools again
      - expect `Key('tool-row-phoria')` found and `Key('tool-chip-phoria')` `findsNothing`
    - `back at a non-Home root goes Home`:
      - tap Patients
      - `await tester.binding.handlePopRoute(); await tester.pumpAndSettle();`
      - `selectedIndex == 0`
    - `openTool replaces an open tool and shows the Tools tab` (Review Focus 5):
      - open the vergence workspace via Tools
      - tap Home
      - call `ShellScope.of(tester.element(find.byType(HomeScreen))).openTool('diagnose')`, then `pumpAndSettle`
      - `selectedIndex == 2`, `ChoiceChip.selected == true` for `tool-chip-diagnose`, and `ChoiceChip.selected == false` for `tool-chip-vergence`. Don't use `find.text('Diagnose')` here, because it matches both the title and the chip.
    - `remount starts fresh` (Review Focus 1):
      - open a tool workspace
      - `pumpWidget(const SizedBox())`, then `pumpShell` again
      - Tools tab: `tool-row-phoria` found and no `tool-chip-phoria`
- [ ] **Step 2: Run the tests and check they fail.**
  - Run: `flutter test test/navigation_shell_test.dart`
  - Expected: compilation errors and failures.
- [ ] **Step 3: Create `ShellTab`, `ShellScope` and `ProfileAvatarButton`.**
- [ ] **Step 4: Create `main_shell.dart` and remove the old shell from `main.dart`.**
- [ ] **Step 5: Turn Patients, Reference, Tools and Home into tab first screens**, as listed under Files: each has its own `AppBar` with `ProfileAvatarButton` and no leading back arrow. Make the root-navigator pushes in the patient list and patient detail.
- [ ] **Step 6: Update `test/widget_test.dart`.** It must still `expect(find.text('BV Toolkit'), findsOneWidget)` with the `PreferencesService` provider in place.
- [ ] **Step 7: Run the tests and check they pass.**
  - Run: `flutter test && flutter analyze`
  - Expected: all pass, and "No issues found!"
- [ ] **Step 8: Commit.**
  - Message: `feat: four-tab shell with per-tab navigators`

---

### Task 5: Home redesign, shortcuts picker and Profile row

**Files:**
- Create: `lib/widgets/shortcut_grid.dart`
- Create: `lib/widgets/home_shortcuts_picker.dart`
- Modify: `lib/screens/home_screen.dart`: full layout from spec §4
- Modify: `lib/screens/profile_screen.dart`: add a "Home shortcuts" row under Edit profile
- Test: `test/home_shortcuts_test.dart`

**Interfaces:**
- Consumes:
  - `PreferencesService.homeShortcuts` / `setHomeShortcuts`, `kShortcuts`, `kMinShortcuts` (Task 1)
  - `PatientService.recent` (Task 2)
  - `ShellScope` (Task 4)
- Produces:
  - `class ShortcutGrid extends StatelessWidget { const ShortcutGrid({super.key, required this.selected, required this.onToggle, this.crossAxisCount = 2}); final List<String> selected; final ValueChanged<String> onToggle; final int crossAxisCount; }`
    - One tile per entry in `kShortcuts`, with `Key('shortcut-tile-<id>')`.
    - Selected tiles use the dark fill that onboarding uses today (`0xFF303538`, white text).
    - Task 6 reuses this widget.
  - `Future<List<String>?> showHomeShortcutsPicker(BuildContext context, {required List<String> initial})`
    - Pushes a full-screen dialog route (`fullscreenDialog: true`) on the root navigator.
    - Top bar: title "Home shortcuts", a Cancel action (`Key('picker-cancel')`), returns null, and a Save action (`Key('picker-save')`), disabled while fewer than `kMinShortcuts` are selected, which returns the list.
    - Above the grid, a hint: "Choose at least 3."
    - Selection order: the existing order, with newly toggled-on ids appended.
  - `HomeScreen` layout, top to bottom:
    1. A "Your tools" header with an `Edit` `TextButton(key: Key('home-edit-shortcuts'))`, then a 2-column grid of tiles with `Key('home-shortcut-<id>')`. Tapping a tile runs `ShellScope.of(context).openShortcut(id)`.
    2. "Recent patients", with a `See all` button (`Key('home-see-all')`) that runs `openTab(ShellTab.patients)`. Each patient row runs `openPatient(p.id)`. With no patients, show `FilledButton(key: Key('home-add-first-patient'), child: Text('Add your first patient'))`, which pushes `PatientFormScreen()` on the root navigator.
    3. The existing Morgan's norms card, unchanged.
  - Edit: `final r = await showHomeShortcutsPicker(context, initial: prefs.homeShortcuts); if (r != null) await prefs.setHomeShortcuts(r);`. The Profile row does the same.

- [ ] **Step 1: Write the failing tests** in `test/home_shortcuts_test.dart`.
  - Pump `HomeScreen` inside a `ShellScope` whose callbacks record calls into lists, with providers `AuthService()`, `PatientService()` and `PreferencesService()..load()`.
  - Use `SharedPreferences.setMockInitialValues` to set the stored picks.
  - Tests:
    - `shows saved picks`:
      - stored `['diagnose', 'reference', 'analysis']`
      - `home-shortcut-diagnose`, `home-shortcut-reference` and `home-shortcut-analysis` found; `home-shortcut-phoria` `findsNothing`
    - `defaults when nothing saved`: `home-shortcut-phoria`, `-vergence` and `-graphical` found.
    - `tapping a tool tile opens it`: tap `home-shortcut-graphical`, and `openToolCalls == ['graphical']`.
    - `tapping Reference tile opens tab`: stored `['reference', 'phoria', 'vergence']`; tap `home-shortcut-reference`; `openTabCalls == [ShellTab.reference]`.
    - `editing updates Home`:
      - tap `home-edit-shortcuts`
      - tap `shortcut-tile-phoria`; Save is disabled (`tester.widget<TextButton>(find.byKey(Key('picker-save'))).onPressed == null`)
      - tap `shortcut-tile-diagnose`, then tap `picker-save`
      - `home-shortcut-diagnose` found, `home-shortcut-phoria` `findsNothing`
      - and `PreferencesService.homeShortcuts == ['vergence', 'graphical', 'diagnose']`
    - `cancelling the picker changes nothing` (Review Focus 3):
      - tap Edit, toggle `shortcut-tile-diagnose`, tap `picker-cancel`
      - Home still shows the defaults, and `homeShortcuts == kDefaultShortcuts`
    - `empty patients shows add button`: `home-add-first-patient` found, and `home-see-all` found.
- [ ] **Step 2: Run the tests and check they fail.**
  - Run: `flutter test test/home_shortcuts_test.dart`
  - Expected: FAIL.
- [ ] **Step 3: Create `ShortcutGrid` and `showHomeShortcutsPicker`.**
- [ ] **Step 4: Rebuild `HomeScreen`.**
- [ ] **Step 5: Add the "Home shortcuts" row to Profile.** Use `Icons.dashboard_customize_outlined` and the same chevron row style as "Edit profile".
- [ ] **Step 6: Run the tests and check they pass.**
  - Run: `flutter test && flutter analyze`
  - Expected: all pass, and "No issues found!"
- [ ] **Step 7: Commit.**
  - Message: `feat: personalised Home with shortcuts picker`

---

### Task 6: Two-page onboarding that saves the picks

**Files:**
- Modify: `lib/screens/onboarding_screen.dart`
- Test: `test/onboarding_test.dart`

**Interfaces:**
- Consumes: `ShortcutGrid`, `PreferencesService.setHomeShortcuts`, `kDefaultShortcuts`, `kMinShortcuts`.
- Produces: `OnboardingScreen({required VoidCallback onComplete, required VoidCallback onLogIn})`. The constructor is unchanged.
  - Two pages: Welcome, then "Which tools matter most in your clinic?" with `ShortcutGrid(crossAxisCount: 2)` in a 2×4 layout.
  - Remove `_GoalsPage`, `_goals` and `_selectedGoal`. `_Dots(count: 2)`.
  - Selection starts as `List.of(kDefaultShortcuts)`. Continue is disabled while fewer than `kMinShortcuts` are selected.
  - Continue on page 1 runs `await context.read<PreferencesService>().setHomeShortcuts(_selected)`, then `widget.onComplete()`.
  - "Log In" stays as it is: it calls `onLogIn` without saving.

- [ ] **Step 1: Write the failing tests** in `test/onboarding_test.dart`. Pump `OnboardingScreen` with a `PreferencesService` provider, after `setMockInitialValues({})`.
  - `two pages, no goals page`:
    - tap 'Get Started', `pumpAndSettle`
    - `shortcut-tile-reference` found
    - `find.text('What do you want BV Toolkit to help with?')` `findsNothing`
  - `finishing saves picks`:
    - Get Started
    - tap `shortcut-tile-diagnose`
    - tap 'Continue', `pumpAndSettle`
    - `completeCalls == 1`, and `prefs.homeShortcuts == ['phoria', 'vergence', 'graphical', 'diagnose']`
  - `fewer than three disables Continue`:
    - deselect `shortcut-tile-phoria`
    - Continue `ElevatedButton.onPressed == null`
  - `Log In keeps defaults` (Review Focus 4):
    - tap 'Log In'
    - `logInCalls == 1`, and `prefs.homeShortcuts == kDefaultShortcuts`
    - a new `PreferencesService()..load()` also returns the defaults
- [ ] **Step 2: Run the tests and check they fail.**
  - Run: `flutter test test/onboarding_test.dart`
  - Expected: FAIL.
- [ ] **Step 3: Make the onboarding changes** described above.
- [ ] **Step 4: Run the tests and check they pass.**
  - Run: `flutter test && flutter analyze`
  - Expected: all pass, and "No issues found!"
- [ ] **Step 5: Commit.**
  - Message: `feat: two-page onboarding that saves home shortcuts`

---

### Task 7: Layout fixes

**Files:**
- Modify: `lib/theme.dart:36` (`AppBarTheme`)
- Modify: `lib/screens/patients/patient_form_screen.dart:227-233` (`_genderPicker`)
- Test: `test/layout_fixes_test.dart`

**Interfaces:**
- Status bar: in `AppBarTheme`, set `systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark`. Import `package:flutter/services.dart`.
- Gender row: `_genderPicker` returns `SizedBox(width: double.infinity, child: Column(crossAxisAlignment: CrossAxisAlignment.start, …))`.

- [ ] **Step 1: Write the failing tests.**
  - `status bar style follows brightness`:
    - `expect(buildTheme(Brightness.light).appBarTheme.systemOverlayStyle, SystemUiOverlayStyle.dark)`
    - `expect(buildTheme(Brightness.dark).appBarTheme.systemOverlayStyle, SystemUiOverlayStyle.light)`
  - `gender label aligns with first name`:
    - pump `MaterialApp(theme: buildTheme(Brightness.light), home: ChangeNotifierProvider(create: (_) => PatientService(), child: const PatientFormScreen()))`
    - `expect(tester.getTopLeft(find.text('Gender')).dx, tester.getTopLeft(find.text('First name *')).dx)`
- [ ] **Step 2: Run the tests and check they fail.**
  - Run: `flutter test test/layout_fixes_test.dart`
  - Expected: both FAIL. The `systemOverlayStyle` is null, and the Gender x is offset.
- [ ] **Step 3: Apply the two changes** described above.
- [ ] **Step 4: Run the tests and check they pass.**
  - Run: `flutter test && flutter analyze`
  - Expected: all pass, and "No issues found!"
- [ ] **Step 5: Commit.**
  - Message: `fix: status bar contrast and gender row alignment`

---

### Task 8: Full check in the simulator

**Files:** none, unless a defect is found. In that case, fix it inside the task that owns the file and add a test there.

- [ ] **Step 1: Run the full automated check.**
  - Run: `flutter analyze && flutter test`
  - Expected: "No issues found!" and "All tests passed!"
- [ ] **Step 2: Check disk space.**
  - Run: `df -h /System/Volumes/Data`
  - Expected: at least 5 GB free. If there's less, stop and ask the user. The 2026-11-08 build needed about 5 GB.
- [ ] **Step 3: Build the app and launch it in the simulator.**
  - Run: `flutter build ios --simulator --debug`
  - Then launch `build/ios/iphonesimulator/Runner.app` on the iPhone 17 Pro simulator.
- [ ] **Step 4: Screenshot every screen in light mode.** Wait for each screen to settle, because screenshots can trail taps by one frame. Check:
  - **Onboarding:** two pages, and the picks grid shows 8 tiles.
  - **Create account:** the status-bar clock is visible.
  - **Home:** your tools, recent patients, then Morgan's norms.
  - **Patients:** no back arrow, and New patient opens full screen with the Gender row aligned.
  - **Tools:** the list, plus each of the six tools via the strip.
  - **Reference:** the Reference tab is highlighted.
  - **Profile:** the Home shortcuts row is there.
- [ ] **Step 5: Repeat Step 4 in dark mode.** Use `set_appearance dark`.
- [ ] **Step 6: Report.** List each screen as pass or fail against the spec's success criteria. Include the screenshots that show the three fixes.
