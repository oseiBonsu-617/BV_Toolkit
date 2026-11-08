import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bv_toolkit/config/tools.dart';
import 'package:bv_toolkit/screens/tools/tools_hub_screen.dart';
import 'package:bv_toolkit/theme.dart';

Future<void> pumpHub(WidgetTester t) async {
  t.view.physicalSize = const Size(800, 4000);
  t.view.devicePixelRatio = 1.0;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      theme: buildTheme(Brightness.light),
      home: const ToolsHubScreen(),
    ),
  );
}

Future<void> openTool(WidgetTester t, String id) async {
  await t.tap(find.byKey(Key('tool-row-$id')));
  await t.pumpAndSettle();
}

void main() {
  testWidgets('hub lists six tools', (t) async {
    await pumpHub(t);
    for (final tool in kTools) {
      expect(find.byKey(Key('tool-row-${tool.id}')), findsOneWidget);
    }
    expect(find.text('Measurements'), findsOneWidget);
    expect(find.text('Analysis'), findsOneWidget);
    expect(find.text('Diagnosis'), findsOneWidget);
  });

  testWidgets('opening a tool shows workspace with switcher', (t) async {
    await pumpHub(t);
    await openTool(t, 'phoria');
    expect(find.text('Phoria & ratios'), findsOneWidget);
    expect(find.byKey(const Key('tool-chip-graphical')), findsOneWidget);
  });

  testWidgets('switching tools keeps typed values', (t) async {
    await pumpHub(t);
    await openTool(t, 'phoria');
    await t.enterText(find.byType(TextField).first, '7');
    await t.tap(find.byKey(const Key('tool-chip-vergence')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('tool-chip-phoria')));
    await t.pumpAndSettle();
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('Example action only on graphical', (t) async {
    await pumpHub(t);
    await openTool(t, 'phoria');
    expect(find.byKey(const Key('tool-example')), findsNothing);
    await t.tap(find.byKey(const Key('tool-chip-graphical')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('tool-example')), findsOneWidget);
    await t.tap(find.byKey(const Key('tool-example')));
    await t.pumpAndSettle();
    expect(find.text('Plot & analyse'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('analysis link switches to graphical', (t) async {
    await pumpHub(t);
    await openTool(t, 'analysis');
    final link = find.byKey(const Key('analysis-zcsbv-link'));
    await t.ensureVisible(link);
    await t.tap(link);
    await t.pumpAndSettle();
    expect(find.text('Graphical analysis'), findsOneWidget);
  });
}
