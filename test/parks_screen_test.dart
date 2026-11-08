import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:bv_toolkit/screens/tools/tools_hub_screen.dart';
import 'package:bv_toolkit/services/auth_service.dart';
import 'package:bv_toolkit/theme.dart';

Future<void> openParks(WidgetTester t) async {
  t.view.physicalSize = const Size(800, 4000);
  t.view.devicePixelRatio = 1.0;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => AuthService(),
      child: MaterialApp(
        theme: buildTheme(Brightness.light),
        home: const ToolsHubScreen(),
      ),
    ),
  );
  await t.tap(find.byKey(const Key('tool-row-parks')));
  await t.pumpAndSettle();
}

Future<void> pick(WidgetTester t, int step, String label) async {
  await t.tap(find.descendant(
    of: find.byKey(Key('parks-step-$step')),
    matching: find.text(label),
  ), warnIfMissed: false); // disabled steps ignore taps
  await t.pumpAndSettle();
}

bool struck(WidgetTester t, String id) {
  final texts = find.descendant(
    of: find.byKey(Key('parks-candidate-$id')),
    matching: find.byType(Text),
  );
  return t
      .widgetList<Text>(texts)
      .any((w) => w.style?.decoration == TextDecoration.lineThrough);
}

void main() {
  testWidgets('hub lists Park\'s under Diagnosis', (t) async {
    await openParks(t);
    expect(find.text("Park's three-step test"), findsWidgets);
  });

  testWidgets('hub row exists under Diagnosis group', (t) async {
    t.view.physicalSize = const Size(800, 4000);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthService(),
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          home: const ToolsHubScreen(),
        ),
      ),
    );
    double y(String s) => t.getTopLeft(find.text(s)).dy;
    expect(t.getTopLeft(find.byKey(const Key('tool-row-parks'))).dy,
        greaterThan(y('Diagnosis')));
    expect(t.getTopLeft(find.byKey(const Key('tool-row-parks'))).dy,
        greaterThan(t.getTopLeft(find.byKey(const Key('tool-row-diagnose'))).dy));
  });

  testWidgets('full path gives right superior oblique, CN IV', (t) async {
    await openParks(t);
    expect(find.byKey(const Key('parks-result')), findsNothing);
    await pick(t, 1, 'Right hyper');
    await pick(t, 2, 'Left');
    await pick(t, 3, 'Right');
    final result = find.byKey(const Key('parks-result'));
    expect(result, findsOneWidget);
    expect(find.descendant(of: result, matching: find.text('Right superior oblique')),
        findsOneWidget);
    expect(find.descendant(of: result, matching: find.text('CN IV')),
        findsOneWidget);
    expect(struck(t, 'rso'), isFalse);
    expect(struck(t, 'lsr'), isTrue);
  });

  testWidgets('step 2 is disabled before step 1', (t) async {
    await openParks(t);
    await pick(t, 2, 'Left');
    expect(find.byKey(const Key('parks-result')), findsNothing);
    // Still no candidates narrowed: all eight shown, none struck.
    for (final id in ['rso', 'rsr', 'rir', 'rio', 'lso', 'lsr', 'lir', 'lio']) {
      expect(find.byKey(Key('parks-candidate-$id')), findsOneWidget);
      expect(struck(t, id), isFalse);
    }
    await pick(t, 1, 'Right hyper');
    // The earlier tap was ignored: step 3 stays disabled.
    await pick(t, 3, 'Left');
    expect(find.byKey(const Key('parks-result')), findsNothing);
  });

  testWidgets('changing step 1 clears later steps', (t) async {
    await openParks(t);
    await pick(t, 1, 'Right hyper');
    await pick(t, 2, 'Left');
    await pick(t, 3, 'Right');
    expect(find.byKey(const Key('parks-result')), findsOneWidget);
    await pick(t, 1, 'Left hyper');
    expect(find.byKey(const Key('parks-result')), findsNothing);
    // Step 3 is disabled again (step 2 cleared), so this tap is ignored.
    await pick(t, 3, 'Left');
    expect(find.byKey(const Key('parks-result')), findsNothing);
  });

  testWidgets('reset clears everything', (t) async {
    await openParks(t);
    await pick(t, 1, 'Right hyper');
    await pick(t, 2, 'Left');
    await pick(t, 3, 'Right');
    await t.tap(find.byKey(const Key('parks-reset')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('parks-result')), findsNothing);
    expect(struck(t, 'lsr'), isFalse);
  });

  testWidgets('answers survive switching tools', (t) async {
    await openParks(t);
    await pick(t, 1, 'Right hyper');
    await pick(t, 2, 'Left');
    await pick(t, 3, 'Right');
    await t.ensureVisible(find.byKey(const Key('tool-chip-phoria')));
    await t.tap(find.byKey(const Key('tool-chip-phoria')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('parks-result')), findsNothing); // hidden
    await t.ensureVisible(find.byKey(const Key('tool-chip-parks')));
    await t.tap(find.byKey(const Key('tool-chip-parks')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('parks-result')), findsOneWidget);
  });

  testWidgets('caution text is always visible', (t) async {
    await openParks(t);
    expect(find.textContaining('Assumes a single paretic'), findsOneWidget);
  });
}
