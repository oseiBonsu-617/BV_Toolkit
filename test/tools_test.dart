import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:bv_toolkit/config/tools.dart';
import 'package:bv_toolkit/screens/tools/accommodation_screen.dart';
import 'package:bv_toolkit/screens/tools/analysis_screen.dart';
import 'package:bv_toolkit/screens/tools/diagnosis_screen.dart';
import 'package:bv_toolkit/screens/tools/graphical_analysis_screen.dart';
import 'package:bv_toolkit/screens/tools/parks_screen.dart';
import 'package:bv_toolkit/screens/tools/phoria_screen.dart';
import 'package:bv_toolkit/screens/tools/tool_workspace_screen.dart';
import 'package:bv_toolkit/screens/tools/tools_hub_screen.dart';
import 'package:bv_toolkit/screens/tools/vergence_screen.dart';
import 'package:bv_toolkit/services/auth_service.dart';
import 'package:bv_toolkit/theme.dart';

Future<void> pumpHub(WidgetTester t, {double width = 800}) async {
  t.view.physicalSize = Size(width, 4000);
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
}

Future<void> openTool(WidgetTester t, String id) async {
  await t.tap(find.byKey(Key('tool-row-$id')));
  await t.pumpAndSettle();
}

void main() {
  testWidgets('hub lists every tool', (t) async {
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

  testWidgets('each chip shows its own tool body', (t) async {
    const bodies = <String, Type>{
      'phoria': PhoriaScreen,
      'vergence': VergenceScreen,
      'accommodation': AccommodationScreen,
      'analysis': AnalysisScreen,
      'graphical': GraphicalAnalysisBody,
      'diagnose': DiagnosisScreen,
      'parks': ParksScreen,
    };
    expect(bodies.keys, unorderedEquals(kTools.map((tool) => tool.id)));
    await pumpHub(t);
    await openTool(t, kTools.first.id);
    for (final tool in kTools) {
      final chip = find.byKey(Key('tool-chip-${tool.id}'));
      await t.ensureVisible(chip);
      await t.tap(chip);
      await t.pumpAndSettle();
      for (final MapEntry(key: id, value: type) in bodies.entries) {
        // Only the selected body is painted and hit-testable.
        expect(
          find.byType(type).hitTestable(),
          id == tool.id ? findsOneWidget : findsNothing,
          reason: 'chip ${tool.id}, body for $id',
        );
      }
    }
  });

  testWidgets('switching tools scrolls the selected chip into view', (t) async {
    await pumpHub(t, width: 360);
    await openTool(t, 'phoria');
    final chip = find.byKey(const Key('tool-chip-diagnose'));
    expect(chip.hitTestable(), findsNothing, reason: 'starts off-screen');
    ToolWorkspaceScope.maybeOf(
      t.element(find.byType(PhoriaScreen)),
    )!.switchTo('diagnose');
    await t.pumpAndSettle();
    final rect = t.getRect(chip);
    expect(rect.left, greaterThanOrEqualTo(0));
    expect(rect.right, lessThanOrEqualTo(360));
  });
}
