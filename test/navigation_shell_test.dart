import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bv_toolkit/screens/home_screen.dart';
import 'package:bv_toolkit/screens/patients/patient_form_screen.dart';
import 'package:bv_toolkit/screens/profile_screen.dart';
import 'package:bv_toolkit/screens/shell/main_shell.dart';
import 'package:bv_toolkit/screens/shell/shell_scope.dart';
import 'package:bv_toolkit/services/auth_service.dart';
import 'package:bv_toolkit/services/patient_service.dart';
import 'package:bv_toolkit/services/preferences_service.dart';
import 'package:bv_toolkit/services/session_service.dart';
import 'package:bv_toolkit/theme.dart';

Future<void> pumpShell(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => PatientService()),
        ChangeNotifierProvider(create: (_) => SessionService()),
        ChangeNotifierProvider(create: (_) => PreferencesService()..load()),
      ],
      child: MaterialApp(
        theme: buildTheme(Brightness.light),
        home: const MainShell(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder tabLabel(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

Future<void> tapTab(WidgetTester tester, String label) async {
  await tester.tap(tabLabel(label));
  await tester.pumpAndSettle();
}

Future<void> tapKey(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}

int selectedTab(WidgetTester tester) =>
    tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

bool chipSelected(WidgetTester tester, String id) =>
    tester.widget<ChoiceChip>(find.byKey(Key('tool-chip-$id'))).selected;

/// Opens Phoria from the Tools tab, types 7, goes Home and back to Tools.
Future<void> typeInPhoriaAndSwitchAway(WidgetTester tester) async {
  await tapTab(tester, 'Tools');
  await tapKey(tester, 'tool-row-phoria');
  await tester.enterText(find.byType(TextField).first, '7');
  await tester.pump();
  await tapTab(tester, 'Home');
  await tapTab(tester, 'Tools');
}

void main() {
  testWidgets('four tabs', (tester) async {
    await pumpShell(tester);
    for (final label in ['Home', 'Patients', 'Tools', 'Reference']) {
      expect(tabLabel(label), findsOneWidget);
    }
    expect(tabLabel('Phoria'), findsNothing);
  });

  testWidgets('highlight follows tab, including Reference', (tester) async {
    await pumpShell(tester);
    await tapTab(tester, 'Reference');
    expect(selectedTab(tester), 3);
    expect(find.text('Norms & conditions'), findsOneWidget);
  });

  testWidgets('tab keeps its place and typed values', (tester) async {
    await pumpShell(tester);
    await typeInPhoriaAndSwitchAway(tester);
    expect(find.byKey(const Key('tool-chip-phoria')), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('re-tapping current tab returns to root', (tester) async {
    await pumpShell(tester);
    await typeInPhoriaAndSwitchAway(tester);
    await tapTab(tester, 'Tools');
    expect(find.byKey(const Key('tool-row-phoria')), findsOneWidget);
    expect(find.byKey(const Key('tool-chip-phoria')), findsNothing);
  });

  testWidgets('back at a non-Home root goes Home', (tester) async {
    await pumpShell(tester);
    await tapTab(tester, 'Patients');
    expect(selectedTab(tester), 1);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(selectedTab(tester), 0);
  });

  testWidgets('back inside a tab pops that tab first', (tester) async {
    await pumpShell(tester);
    await tapTab(tester, 'Tools');
    await tapKey(tester, 'tool-row-phoria');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(selectedTab(tester), 2);
    expect(find.byKey(const Key('tool-row-phoria')), findsOneWidget);
    expect(find.byKey(const Key('tool-chip-phoria')), findsNothing);
  });

  testWidgets('openTool replaces an open tool and shows the Tools tab', (
    tester,
  ) async {
    await pumpShell(tester);
    await tapTab(tester, 'Tools');
    await tapKey(tester, 'tool-row-vergence');
    await tapTab(tester, 'Home');
    ShellScope.of(tester.element(find.byType(HomeScreen))).openTool('diagnose');
    await tester.pumpAndSettle();
    expect(selectedTab(tester), 2);
    expect(chipSelected(tester, 'diagnose'), isTrue);
    expect(chipSelected(tester, 'vergence'), isFalse);
  });

  testWidgets('openShortcut routes tools, patients and reference', (
    tester,
  ) async {
    await pumpShell(tester);
    ShellScope scope() =>
        ShellScope.of(tester.element(find.byType(NavigationBar)));
    scope().openShortcut('patients');
    await tester.pumpAndSettle();
    expect(selectedTab(tester), 1);
    scope().openShortcut('reference');
    await tester.pumpAndSettle();
    expect(selectedTab(tester), 3);
    scope().openShortcut('phoria');
    await tester.pumpAndSettle();
    expect(selectedTab(tester), 2);
    expect(chipSelected(tester, 'phoria'), isTrue);
  });

  testWidgets('add-patient form covers the bottom bar', (tester) async {
    await pumpShell(tester);
    await tapTab(tester, 'Patients');
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.byType(PatientFormScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('avatar opens Profile over the bottom bar', (tester) async {
    await pumpShell(tester);
    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('remount starts fresh', (tester) async {
    await pumpShell(tester);
    await tapTab(tester, 'Tools');
    await tapKey(tester, 'tool-row-phoria');
    expect(find.byKey(const Key('tool-chip-phoria')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await pumpShell(tester);
    await tapTab(tester, 'Tools');
    expect(find.byKey(const Key('tool-row-phoria')), findsOneWidget);
    expect(find.byKey(const Key('tool-chip-phoria')), findsNothing);
  });
}
