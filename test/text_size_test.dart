import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bv_toolkit/config/tools.dart';
import 'package:bv_toolkit/data/home_feed.dart';
import 'package:bv_toolkit/models/test_session.dart';
import 'package:bv_toolkit/screens/home_screen.dart';
import 'package:bv_toolkit/screens/shell/main_shell.dart';
import 'package:bv_toolkit/screens/shell/shell_scope.dart';
import 'package:bv_toolkit/screens/tools/tool_workspace_screen.dart';
import 'package:bv_toolkit/screens/tools/tools_hub_screen.dart';
import 'package:bv_toolkit/services/auth_service.dart';
import 'package:bv_toolkit/services/patient_service.dart';
import 'package:bv_toolkit/services/preferences_service.dart';
import 'package:bv_toolkit/services/session_service.dart';
import 'package:bv_toolkit/theme.dart';

class _NoDbSessionService extends SessionService {
  @override
  Future<List<TestSession>> forPatient(String patientId) async => [];
}

Future<void> pumpApp(
  WidgetTester t,
  Widget home, {
  double scale = 1.0,
  Size physicalSize = const Size(750, 1334),
}) async {
  t.view.physicalSize = physicalSize;
  t.view.devicePixelRatio = 2.0;
  addTearDown(t.view.reset);
  SharedPreferences.setMockInitialValues({});
  await t.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => PatientService()),
        ChangeNotifierProvider<SessionService>(
          create: (_) => _NoDbSessionService(),
        ),
        ChangeNotifierProvider(create: (_) => PreferencesService()..load()),
      ],
      child: MaterialApp(
        theme: buildTheme(Brightness.light),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: home,
      ),
    ),
  );
  await t.pumpAndSettle();
}

/// Home at a fixed time with a fixed week summary, in a do-nothing shell.
Widget fixedHome(DateTime now, {int sessions = 3, int patients = 2}) =>
    ShellScope(
      openTab: (_) {},
      openTabAtRoot: (_) {},
      openTool: (_) {},
      openPatient: (_) {},
      openReference: (_) {},
      child: HomeScreen(
        now: () => now,
        weekSummary: (_) async => (sessions: sessions, patients: patients),
      ),
    );

void main() {
  testWidgets('Home tile label is 16 pt', (t) async {
    await pumpApp(t, const MainShell());
    final tile = find.byKey(const Key('home-shortcut-phoria'));
    expect(tile, findsOneWidget);
    final text = t.widget<Text>(
      find.descendant(of: tile, matching: find.text('Phoria & ratios')),
    );
    expect(text.style?.fontSize, 16);
  });

  for (final scale in [1.0, 1.3]) {
    testWidgets('Home has no overflow at text scale $scale', (t) async {
      await pumpApp(t, const MainShell(), scale: scale);
      expect(t.takeException(), isNull);
    });

    testWidgets('fixed-time Home has no overflow at 375x667, scale $scale', (
      t,
    ) async {
      await pumpApp(
        t,
        fixedHome(DateTime(2026, 11, 8, 9), sessions: 0, patients: 0),
        scale: scale,
      );
      expect(t.takeException(), isNull);
      for (var i = 0; i < 8; i++) {
        await t.drag(find.byType(ListView).first, const Offset(0, -300));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
      }
      expect(find.byKey(const Key('home-norm')), findsOneWidget);
    });

    testWidgets('every pearl, condition and norm fits 375 wide, scale $scale', (
      t,
    ) async {
      // Enough days to show every pearl and norm and every week's condition.
      final days = conditionPool.length * 7;
      for (var i = 0; i < days; i++) {
        await pumpApp(
          t,
          fixedHome(DateTime(2026, 11, 2 + i, 9)),
          scale: scale,
          physicalSize: const Size(750, 6000),
        );
        expect(t.takeException(), isNull, reason: 'day $i');
      }
    });

    testWidgets('Tools hub has no overflow at text scale $scale', (t) async {
      await pumpApp(t, const ToolsHubScreen(), scale: scale);
      expect(t.takeException(), isNull);
    });
  }

  for (final tool in kTools) {
    testWidgets('workspace ${tool.id} has no overflow at 375x667', (t) async {
      await pumpApp(t, ToolWorkspaceScreen(initialToolId: tool.id));
      await t.tap(find.byKey(Key('tool-chip-${tool.id}')));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });
  }
}
