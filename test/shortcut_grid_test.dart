import 'dart:ui' show Tristate;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bv_toolkit/theme.dart';
import 'package:bv_toolkit/widgets/shortcut_grid.dart';

Future<void> _pump(WidgetTester tester, Brightness b) async {
  tester.view.physicalSize = const Size(800, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(b),
      home: Scaffold(
        body: SingleChildScrollView(
          child: ShortcutGrid(selected: const ['phoria'], onToggle: (_) {}),
        ),
      ),
    ),
  );
}

BoxDecoration _decoration(WidgetTester tester, String id) {
  final box = tester.widget<DecoratedBox>(
    find
        .descendant(
          of: find.byKey(Key('shortcut-tile-$id')),
          matching: find.byType(DecoratedBox),
        )
        .first,
  );
  return box.decoration as BoxDecoration;
}

void main() {
  for (final b in [Brightness.light, Brightness.dark]) {
    testWidgets('check badge only on selected tile ($b)', (tester) async {
      await _pump(tester, b);
      expect(find.byKey(const Key('shortcut-check-phoria')), findsOneWidget);
      expect(find.byKey(const Key('shortcut-check-vergence')), findsNothing);
    });
  }

  testWidgets('dark selected tile has kPrimary border and tinted fill', (
    tester,
  ) async {
    await _pump(tester, Brightness.dark);
    final sel = _decoration(tester, 'phoria');
    final unsel = _decoration(tester, 'vergence');
    final selFill = tester
        .widget<Material>(find.byKey(const Key('shortcut-tile-phoria')))
        .color;
    final unselFill = tester
        .widget<Material>(find.byKey(const Key('shortcut-tile-vergence')))
        .color;
    final border = sel.border as Border;
    expect(border.top.color, kPrimary);
    expect(border.top.width, 1.5);
    expect(selFill, isNot(unselFill));
    expect(unsel.border, isNot(sel.border));
  });

  testWidgets('selected state is exposed to semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, Brightness.dark);
    final sel = tester.getSemantics(
      find.byKey(const Key('shortcut-tile-phoria')),
    );
    final unsel = tester.getSemantics(
      find.byKey(const Key('shortcut-tile-vergence')),
    );
    expect(sel.flagsCollection.isSelected, Tristate.isTrue);
    expect(unsel.flagsCollection.isSelected, Tristate.isFalse);
    handle.dispose();
  });
}
