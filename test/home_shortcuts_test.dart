import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bv_toolkit/config/tools.dart';
import 'package:bv_toolkit/screens/home_screen.dart';
import 'package:bv_toolkit/screens/shell/shell_scope.dart';
import 'package:bv_toolkit/services/auth_service.dart';
import 'package:bv_toolkit/services/patient_service.dart';
import 'package:bv_toolkit/services/preferences_service.dart';

void main() {
  final tabs = <int>[];
  final rootTabs = <int>[];
  final tools = <String>[];
  final patients = <String>[];
  final references = <String>[];
  late PreferencesService prefs;

  Future<void> pumpHome(
    WidgetTester tester, {
    Map<String, Object> stored = const {},
  }) async {
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    tabs.clear();
    rootTabs.clear();
    tools.clear();
    patients.clear();
    references.clear();
    SharedPreferences.setMockInitialValues(stored);
    prefs = PreferencesService();
    await prefs.load();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthService()),
          ChangeNotifierProvider(create: (_) => PatientService()),
          ChangeNotifierProvider.value(value: prefs),
        ],
        child: MaterialApp(
          home: ShellScope(
            openTab: tabs.add,
            openTabAtRoot: rootTabs.add,
            openTool: tools.add,
            openPatient: patients.add,
            openReference: references.add,
            child: const HomeScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder tile(String id) => find.byKey(Key('home-shortcut-$id'));

  testWidgets('shows saved picks', (tester) async {
    await pumpHome(tester, stored: {
      'home_shortcuts': ['diagnose', 'reference', 'analysis'],
    });
    expect(tile('diagnose'), findsOneWidget);
    expect(tile('reference'), findsOneWidget);
    expect(tile('analysis'), findsOneWidget);
    expect(tile('phoria'), findsNothing);
  });

  testWidgets('defaults when nothing saved', (tester) async {
    await pumpHome(tester);
    expect(tile('phoria'), findsOneWidget);
    expect(tile('vergence'), findsOneWidget);
    expect(tile('graphical'), findsOneWidget);
  });

  testWidgets('tapping a tool tile opens it', (tester) async {
    await pumpHome(tester);
    await tester.tap(tile('graphical'));
    expect(tools, ['graphical']);
  });

  testWidgets('tapping Reference tile opens tab', (tester) async {
    await pumpHome(tester, stored: {
      'home_shortcuts': ['reference', 'phoria', 'vergence'],
    });
    await tester.tap(tile('reference'));
    expect(tabs, [ShellTab.reference]);
  });

  testWidgets('editing updates Home', (tester) async {
    await pumpHome(tester);
    await tester.tap(find.byKey(const Key('home-edit-shortcuts')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shortcut-tile-phoria')));
    await tester.pump();
    expect(
      tester.widget<TextButton>(find.byKey(const Key('picker-save'))).onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const Key('shortcut-tile-diagnose')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('picker-save')));
    await tester.pumpAndSettle();
    expect(tile('diagnose'), findsOneWidget);
    expect(tile('phoria'), findsNothing);
    expect(prefs.homeShortcuts, ['vergence', 'graphical', 'diagnose']);
  });

  testWidgets('cancelling the picker changes nothing', (tester) async {
    await pumpHome(tester);
    await tester.tap(find.byKey(const Key('home-edit-shortcuts')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shortcut-tile-diagnose')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('picker-cancel')));
    await tester.pumpAndSettle();
    expect(tile('phoria'), findsOneWidget);
    expect(tile('vergence'), findsOneWidget);
    expect(tile('graphical'), findsOneWidget);
    expect(tile('diagnose'), findsNothing);
    expect(prefs.homeShortcuts, kDefaultShortcuts);
  });

  testWidgets('empty patients shows add button', (tester) async {
    await pumpHome(tester);
    expect(find.byKey(const Key('home-add-first-patient')), findsOneWidget);
    expect(find.byKey(const Key('home-see-all')), findsOneWidget);
  });

  testWidgets('See all opens the Patients tab at its root', (tester) async {
    await pumpHome(tester);
    await tester.tap(find.byKey(const Key('home-see-all')));
    expect(rootTabs, [ShellTab.patients]);
    expect(tabs, isEmpty);
  });
}
