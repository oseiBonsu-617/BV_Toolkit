import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:bv_toolkit/screens/tools/tools_hub_screen.dart';
import 'package:bv_toolkit/services/auth_service.dart';
import 'package:bv_toolkit/theme.dart';

void main() {
  testWidgets('tool row icons use the lighter blue in dark mode', (t) async {
    t.view.physicalSize = const Size(800, 4000);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthService(),
        child: MaterialApp(
          theme: buildTheme(Brightness.dark),
          home: const ToolsHubScreen(),
        ),
      ),
    );
    final icon = t.widget<Icon>(
      find
          .descendant(
            of: find.byKey(const Key('tool-row-phoria')),
            matching: find.byType(Icon),
          )
          .first,
    );
    expect(icon.color, kPrimaryOnDark);
  });

  test('selected NavigationBar icon and label use the lighter blue in dark mode', () {
    final nav = buildTheme(Brightness.dark).navigationBarTheme;
    const selected = {WidgetState.selected};
    expect(nav.iconTheme!.resolve(selected)!.color, kPrimaryOnDark);
    expect(nav.labelTextStyle!.resolve(selected)!.color, kPrimaryOnDark);
    final light = buildTheme(Brightness.light).navigationBarTheme;
    expect(light.iconTheme!.resolve(selected)!.color, kPrimary);
  });
}
