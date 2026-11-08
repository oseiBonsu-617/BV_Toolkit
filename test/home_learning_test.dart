import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bv_toolkit/data/home_feed.dart';
import 'package:bv_toolkit/models/app_user.dart';
import 'package:bv_toolkit/screens/home_screen.dart';
import 'package:bv_toolkit/screens/shell/shell_scope.dart';
import 'package:bv_toolkit/widgets/profile_avatar_button.dart';
import 'package:bv_toolkit/services/auth_service.dart';
import 'package:bv_toolkit/services/patient_service.dart';
import 'package:bv_toolkit/services/preferences_service.dart';
import 'package:bv_toolkit/services/session_service.dart';
import 'package:bv_toolkit/theme.dart';

typedef Summary = ({int sessions, int patients});

/// An AuthService with a signed-in user, without Firebase.
class _SignedInAuth extends AuthService {
  _SignedInAuth(this.name);
  final String name;

  @override
  AppUser? get currentUser =>
      AppUser(id: 'u1', email: 'u1@example.test', displayName: name);

  @override
  bool get isLoggedIn => true;
}

/// Counts weekSummary calls instead of querying sqflite.
class _CountingSessionService extends SessionService {
  int calls = 0;
  Summary next = (sessions: 0, patients: 0);

  @override
  Future<Summary> weekSummary(DateTime since) async {
    calls++;
    return next;
  }

  void changed() => notifyListeners();
}

void main() {
  final references = <String>[];
  var searchOpens = 0;
  final sinces = <DateTime>[];
  // Sunday 8 November 2026.
  final sunday9am = DateTime(2026, 11, 8, 9);

  Future<void> pumpHome(
    WidgetTester tester, {
    DateTime? now,
    DateTime Function()? clock,
    Summary summary = (sessions: 0, patients: 0),
    Future<Summary> Function(DateTime since)? weekSummary,
    String displayName = 'Osei Smith',
    SessionService? sessions,
  }) async {
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    references.clear();
    searchOpens = 0;
    sinces.clear();
    SharedPreferences.setMockInitialValues({});
    final prefs = PreferencesService();
    await prefs.load();
    final at = now ?? sunday9am;
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>(
            create: (_) => _SignedInAuth(displayName),
          ),
          ChangeNotifierProvider(create: (_) => PatientService()),
          ChangeNotifierProvider.value(value: prefs),
          if (sessions != null)
            ChangeNotifierProvider<SessionService>.value(value: sessions),
        ],
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          home: ShellScope(
            openTab: (_) {},
            openTabAtRoot: (_) {},
            openTool: (_) {},
            openPatient: (_) {},
            openReference: references.add,
            openReferenceSearch: () => searchOpens++,
            child: HomeScreen(
              now: clock ?? () => at,
              weekSummary: sessions != null
                  ? null
                  : weekSummary ??
                        (since) async {
                          sinces.add(since);
                          return summary;
                        },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder inKey(String key, Finder f) =>
      find.descendant(of: find.byKey(Key(key)), matching: f);

  String summaryText(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('home-week-summary'))).data!;

  String greetingText(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('home-greeting'))).data!;

  Future<void> tapKey(WidgetTester tester, String key) async {
    await tester.ensureVisible(find.byKey(Key(key)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();
  }

  group('greeting', () {
    for (final (hour, greeting) in [
      (9, 'Good morning'),
      (14, 'Good afternoon'),
      (20, 'Good evening'),
    ]) {
      testWidgets('$hour:00 says $greeting with the first name', (
        tester,
      ) async {
        await pumpHome(tester, now: DateTime(2026, 11, 8, hour));
        expect(greetingText(tester), '$greeting, Osei');
      });
    }

    testWidgets('no name means no comma', (tester) async {
      await pumpHome(tester, displayName: '');
      expect(greetingText(tester), 'Good morning');
    });

    testWidgets('shows the date', (tester) async {
      await pumpHome(tester);
      expect(summaryText(tester), startsWith('Sunday, 8 November'));
    });

    testWidgets('the app name is no longer the title', (tester) async {
      await pumpHome(tester);
      expect(find.text('BV Toolkit'), findsNothing);
      expect(find.text('Clinical suite'), findsNothing);
    });
  });

  group('header', () {
    testWidgets('avatar, one-line greeting, search and add-patient', (
      tester,
    ) async {
      await pumpHome(tester, now: DateTime(2026, 11, 8, 9));
      expect(find.byType(ProfileAvatarButton), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
      expect(greetingText(tester), 'Good morning, Osei');
      expect(find.byKey(const Key('home-search')), findsOneWidget);
      expect(find.byKey(const Key('home-add-patient')), findsOneWidget);
      expect(find.byTooltip('Search Reference'), findsOneWidget);
      expect(find.byTooltip('Add patient'), findsOneWidget);
    });

    testWidgets('search opens Reference search once', (tester) async {
      await pumpHome(tester);
      await tester.tap(find.byKey(const Key('home-search')));
      await tester.pumpAndSettle();
      expect(searchOpens, 1);
    });

    testWidgets('add patient pushes the form on the root navigator', (
      tester,
    ) async {
      await pumpHome(tester);
      await tester.tap(find.byKey(const Key('home-add-patient')));
      await tester.pumpAndSettle();
      expect(find.text('First name *'), findsOneWidget);
    });

    testWidgets('a combined date and summary line', (tester) async {
      await pumpHome(tester, summary: (sessions: 3, patients: 2));
      expect(
        summaryText(tester),
        'Sunday, 8 November · 3 sessions this week · 2 patients',
      );
    });

    for (final scale in [1.0, 1.3]) {
      testWidgets('a long name stays on one line at text scale $scale', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(375, 667);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        SharedPreferences.setMockInitialValues({});
        final prefs = PreferencesService();
        await prefs.load();
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthService>(
                create: (_) => _SignedInAuth('Bartholomew-Alexander Smith'),
              ),
              ChangeNotifierProvider(create: (_) => PatientService()),
              ChangeNotifierProvider.value(value: prefs),
            ],
            child: MaterialApp(
              theme: buildTheme(Brightness.light),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: ShellScope(
                openTab: (_) {},
                openTabAtRoot: (_) {},
                openTool: (_) {},
                openPatient: (_) {},
                openReference: (_) {},
                openReferenceSearch: () {},
                child: HomeScreen(
                  now: () => DateTime(2026, 11, 8, 20),
                  weekSummary: (_) async => (sessions: 3, patients: 2),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(greetingText(tester), 'Good evening, Bartholomew-Alexander');
        expect(tester.takeException(), isNull);
        final height = tester
            .getSize(find.byKey(const Key('home-greeting')))
            .height;
        // One line of 24 pt text is about 29 pt; two would be about 58.
        expect(height, lessThan(24 * 1.5 * scale + 1));
      });
    }
  });

  group('week summary', () {
    testWidgets('no sessions', (tester) async {
      await pumpHome(tester);
      expect(
        summaryText(tester),
        'Sunday, 8 November · No sessions yet this week',
      );
    });

    testWidgets('one session, one patient', (tester) async {
      await pumpHome(tester, summary: (sessions: 1, patients: 1));
      expect(
        summaryText(tester),
        'Sunday, 8 November · 1 session this week · 1 patient',
      );
    });

    testWidgets('several sessions and patients', (tester) async {
      await pumpHome(tester, summary: (sessions: 3, patients: 2));
      expect(
        summaryText(tester),
        'Sunday, 8 November · 3 sessions this week · 2 patients',
      );
    });

    testWidgets('counts from Monday 00:00 of this week', (tester) async {
      await pumpHome(tester);
      expect(sinces, [DateTime(2026, 11, 2)]);
    });

    testWidgets('shows just the date while loading', (tester) async {
      final pending = Completer<Summary>();
      await pumpHome(tester, weekSummary: (_) => pending.future);
      expect(summaryText(tester), 'Sunday, 8 November');
      final loadingHeight = tester
          .getSize(find.byKey(const Key('home-week-summary')))
          .height;
      expect(loadingHeight, greaterThan(0));
      pending.complete((sessions: 2, patients: 2));
      await tester.pumpAndSettle();
      expect(
        summaryText(tester),
        'Sunday, 8 November · 2 sessions this week · 2 patients',
      );
      // The test font is wide, so the full line may wrap; two lines at most.
      final loadedHeight = tester
          .getSize(find.byKey(const Key('home-week-summary')))
          .height;
      expect(loadedHeight, greaterThanOrEqualTo(loadingHeight));
      expect(loadedHeight, lessThanOrEqualTo(2 * loadingHeight));
    });

    testWidgets('a failed count shows just the date', (tester) async {
      await pumpHome(
        tester,
        weekSummary: (_) => Future<Summary>.error(StateError('no db')),
      );
      expect(summaryText(tester), 'Sunday, 8 November');
      expect(tester.takeException(), isNull);
    });

    testWidgets('uses SessionService and refreshes when it changes', (
      tester,
    ) async {
      final sessions = _CountingSessionService();
      await pumpHome(tester, sessions: sessions);
      expect(sessions.calls, 1);
      expect(
        summaryText(tester),
        'Sunday, 8 November · No sessions yet this week',
      );
      sessions.next = (sessions: 1, patients: 1);
      sessions.changed();
      await tester.pumpAndSettle();
      expect(sessions.calls, 2);
      expect(
        summaryText(tester),
        'Sunday, 8 November · 1 session this week · 1 patient',
      );
    });
  });

  group('clinical pearl', () {
    testWidgets("shows today's pearl", (tester) async {
      await pumpHome(tester);
      final pearl = pearlFor(sunday9am);
      expect(inKey('home-pearl', find.text(pearl.text)), findsOneWidget);
      expect(
        inKey('home-pearl', find.text('Clinical pearl of the day')),
        findsOneWidget,
      );
    });

    testWidgets('a different day shows a different pearl', (tester) async {
      final monday = DateTime(2026, 11, 9, 9);
      await pumpHome(tester, now: monday);
      expect(
        inKey('home-pearl', find.text(pearlFor(monday).text)),
        findsOneWidget,
      );
      expect(pearlFor(monday), isNot(pearlFor(sunday9am)));
    });

    testWidgets('Learn more opens its Reference entry', (tester) async {
      await pumpHome(tester);
      await tapKey(tester, 'home-pearl-learn-more');
      expect(references, [pearlFor(sunday9am).refTitle]);
    });
  });

  group('condition of the week', () {
    testWidgets("shows this week's condition", (tester) async {
      await pumpHome(tester);
      final c = conditionFor(sunday9am);
      expect(inKey('home-condition', find.text(c.title)), findsOneWidget);
      expect(
        inKey('home-condition', find.text('Condition of the week')),
        findsOneWidget,
      );
      expect(
        inKey('home-condition', find.text(c.bullets!.first)),
        findsOneWidget,
      );
      if (c.management != null) {
        expect(
          inKey('home-condition', find.text('First-line management')),
          findsOneWidget,
        );
      }
    });

    testWidgets('Read more opens its Reference entry', (tester) async {
      await pumpHome(tester);
      await tapKey(tester, 'home-condition-read-more');
      expect(references, [conditionFor(sunday9am).title]);
    });
  });

  group('norm spotlight', () {
    testWidgets("shows today's norm with its headline value", (tester) async {
      await pumpHome(tester);
      final n = normFor(sunday9am);
      expect(inKey('home-norm', find.text('Norm spotlight')), findsOneWidget);
      expect(inKey('home-norm', find.text(n.title)), findsOneWidget);
      expect(inKey('home-norm', find.text(n.bullets!.first)), findsOneWidget);
    });

    testWidgets("See all norms opens Morgan's norms", (tester) async {
      await pumpHome(tester);
      expect(find.text("Morgan's norms"), findsNothing);
      await tapKey(tester, 'home-see-all-norms');
      expect(find.text("Morgan's norms"), findsOneWidget);
      expect(find.text('Phoria'), findsOneWidget);
      expect(find.text('1Δ exo'), findsOneWidget);
      expect(find.text('3Δ exo'), findsOneWidget);
    });
  });

  group('app resume', () {
    Future<void> resume(WidgetTester tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
    }

    testWidgets('updates the greeting for the new time of day', (tester) async {
      var t = DateTime(2026, 11, 8, 9);
      await pumpHome(tester, clock: () => t);
      expect(greetingText(tester), 'Good morning, Osei');
      t = DateTime(2026, 11, 8, 14);
      await resume(tester);
      expect(greetingText(tester), 'Good afternoon, Osei');
    });

    testWidgets('a new day brings a new pearl and a new week a new count', (
      tester,
    ) async {
      var t = DateTime(2026, 11, 8, 20); // Sunday evening
      await pumpHome(tester, clock: () => t);
      expect(sinces, [DateTime(2026, 11, 2)]);
      t = DateTime(2026, 11, 9, 8); // Monday morning
      await resume(tester);
      expect(sinces.last, DateTime(2026, 11, 9));
      expect(inKey('home-pearl', find.text(pearlFor(t).text)), findsOneWidget);
      expect(
        inKey('home-condition', find.text(conditionFor(t).title)),
        findsOneWidget,
      );
      expect(summaryText(tester), startsWith('Monday, 9 November'));
    });
  });
}
