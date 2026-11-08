import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bv_toolkit/config/tools.dart';
import 'package:bv_toolkit/screens/onboarding_screen.dart';
import 'package:bv_toolkit/services/preferences_service.dart';

void main() {
  late PreferencesService prefs;
  var completeCalls = 0;
  var logInCalls = 0;

  Future<void> pumpOnboarding(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    completeCalls = 0;
    logInCalls = 0;
    SharedPreferences.setMockInitialValues({});
    prefs = PreferencesService();
    await prefs.load();
    await tester.pumpWidget(
      ChangeNotifierProvider<PreferencesService>.value(
        value: prefs,
        child: MaterialApp(
          home: OnboardingScreen(
            onComplete: () => completeCalls++,
            onLogIn: () => logInCalls++,
          ),
        ),
      ),
    );
  }

  Future<void> toTools(WidgetTester tester) async {
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
  }

  testWidgets('two pages, no goals page', (tester) async {
    await pumpOnboarding(tester);
    await toTools(tester);
    expect(find.byKey(const Key('shortcut-tile-reference')), findsOneWidget);
    expect(
      find.text('What do you want BV Toolkit to help with?'),
      findsNothing,
    );
  });

  testWidgets('finishing saves picks', (tester) async {
    await pumpOnboarding(tester);
    await toTools(tester);
    await tester.tap(find.byKey(const Key('shortcut-tile-diagnose')));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(completeCalls, 1);
    expect(prefs.homeShortcuts, [
      'phoria',
      'vergence',
      'graphical',
      'diagnose',
    ]);
  });

  testWidgets('fewer than three disables Continue', (tester) async {
    await pumpOnboarding(tester);
    await toTools(tester);
    await tester.tap(find.byKey(const Key('shortcut-tile-phoria')));
    await tester.pump();
    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('Log In keeps defaults', (tester) async {
    await pumpOnboarding(tester);
    await tester.tap(find.textContaining('Log In', findRichText: true));
    await tester.pumpAndSettle();
    expect(logInCalls, 1);
    expect(prefs.homeShortcuts, kDefaultShortcuts);
    final fresh = PreferencesService();
    await fresh.load();
    expect(fresh.homeShortcuts, kDefaultShortcuts);
  });
}
