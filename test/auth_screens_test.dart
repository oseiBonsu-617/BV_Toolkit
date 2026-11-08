import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bv_toolkit/main.dart';
import 'package:bv_toolkit/screens/auth/welcome_screen.dart';
import 'package:bv_toolkit/services/auth_service.dart';
import 'package:bv_toolkit/services/patient_service.dart';
import 'package:bv_toolkit/services/preferences_service.dart';
import 'package:bv_toolkit/services/session_service.dart';
import 'package:bv_toolkit/theme.dart';

const _tagline = 'Binocular vision assessment, made simple';

void _phoneView(WidgetTester tester, {Size physical = const Size(1170, 2532), double dpr = 3.0}) {
  tester.view.physicalSize = physical;
  tester.view.devicePixelRatio = dpr;
  addTearDown(tester.view.reset);
}

Future<void> _pumpWelcome(
  WidgetTester tester, {
  bool openSignInOnStart = false,
  Brightness brightness = Brightness.light,
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthService())],
      child: MaterialApp(
        theme: buildTheme(brightness),
        home: WelcomeScreen(openSignInOnStart: openSignInOnStart),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => PatientService()),
        ChangeNotifierProvider(create: (_) => SessionService()),
        ChangeNotifierProvider(create: (_) => PreferencesService()..load()),
      ],
      child: const BVToolkitApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('auth gate', () {
    testWidgets('signed out after onboarding shows Welcome', (tester) async {
      _phoneView(tester);
      SharedPreferences.setMockInitialValues({'onboarding_complete': true});
      await _pumpApp(tester);
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.text(_tagline), findsOneWidget);
    });

    testWidgets('onboarding Log In lands on Sign In above Welcome', (tester) async {
      _phoneView(tester);
      SharedPreferences.setMockInitialValues({});
      await _pumpApp(tester);
      await tester.tap(find.textContaining('Log In', findRichText: true));
      await tester.pumpAndSettle();
      expect(find.text('Welcome back'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pumpAndSettle();
      expect(find.text(_tagline), findsOneWidget);
    });

    testWidgets('onboarding Continue lands on Welcome', (tester) async {
      _phoneView(tester);
      SharedPreferences.setMockInitialValues({});
      await _pumpApp(tester);
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.text('Welcome back'), findsNothing);
    });
  });

  group('WelcomeScreen', () {
    testWidgets('shows wordmark, tagline and both buttons', (tester) async {
      _phoneView(tester);
      await _pumpWelcome(tester);
      expect(find.text('BV Toolkit'), findsOneWidget);
      expect(find.text(_tagline), findsOneWidget);
      expect(find.byKey(const Key('welcome-sign-in')), findsOneWidget);
      expect(find.byKey(const Key('welcome-create-account')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Sign In opens the Sign In screen', (tester) async {
      _phoneView(tester);
      await _pumpWelcome(tester);
      await tester.tap(find.byKey(const Key('welcome-sign-in')));
      await tester.pumpAndSettle();
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Sign in to your account'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Create account opens the Create account screen', (tester) async {
      _phoneView(tester);
      await _pumpWelcome(tester);
      await tester.tap(find.byKey(const Key('welcome-create-account')));
      await tester.pumpAndSettle();
      expect(find.text("Let's get started!"), findsOneWidget);
      expect(find.text('Create your new account'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('openSignInOnStart lands on Sign In, back returns to Welcome', (
      tester,
    ) async {
      _phoneView(tester);
      await _pumpWelcome(tester, openSignInOnStart: true);
      expect(find.text('Welcome back'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pumpAndSettle();
      expect(find.text('Welcome back'), findsNothing);
      expect(find.text(_tagline), findsOneWidget);
    });

    testWidgets('fits a 375x667 phone without overflow', (tester) async {
      _phoneView(tester, physical: const Size(750, 1334), dpr: 2.0);
      await _pumpWelcome(tester);
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('welcome-sign-in')).hitTestable(), findsOneWidget);
      expect(find.byKey(const Key('welcome-create-account')).hitTestable(), findsOneWidget);
    });

    testWidgets('fits a 375x667 phone in dark mode without overflow', (tester) async {
      _phoneView(tester, physical: const Size(750, 1334), dpr: 2.0);
      await _pumpWelcome(tester, brightness: Brightness.dark);
      expect(tester.takeException(), isNull);
    });
  });

  group('auth footers', () {
    testWidgets('Sign In "Create one" replaces with Create account; back returns to Welcome', (
      tester,
    ) async {
      _phoneView(tester);
      await _pumpWelcome(tester);
      await tester.tap(find.byKey(const Key('welcome-sign-in')));
      await tester.pumpAndSettle();
      final createOne = find.byKey(const Key('auth-footer-link'));
      await tester.ensureVisible(createOne);
      await tester.tap(createOne);
      await tester.pumpAndSettle();
      expect(find.text("Let's get started!"), findsOneWidget);
      expect(find.text('Welcome back'), findsNothing);

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pumpAndSettle();
      expect(find.text(_tagline), findsOneWidget);
      expect(find.text('Welcome back'), findsNothing);
      expect(find.text("Let's get started!"), findsNothing);
    });

    testWidgets('Create account "Sign in" replaces with Sign In', (tester) async {
      _phoneView(tester);
      await _pumpWelcome(tester);
      await tester.tap(find.byKey(const Key('welcome-create-account')));
      await tester.pumpAndSettle();
      final signIn = find.byKey(const Key('auth-footer-link'));
      await tester.ensureVisible(signIn);
      await tester.tap(signIn);
      await tester.pumpAndSettle();
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text("Let's get started!"), findsNothing);

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pumpAndSettle();
      expect(find.text(_tagline), findsOneWidget);
    });

    testWidgets('Create account keeps all title options', (tester) async {
      _phoneView(tester);
      await _pumpWelcome(tester);
      await tester.tap(find.byKey(const Key('welcome-create-account')));
      await tester.pumpAndSettle();
      for (final t in [
        'OD',
        'Optometrist',
        'Ophthalmologist',
        'Resident',
        'Student',
        'Orthoptist',
        'Other',
      ]) {
        expect(find.text(t), findsOneWidget);
      }
    });
  });

  group('small phone, both themes', () {
    for (final brightness in Brightness.values) {
      testWidgets('Sign In and Create account render without overflow (${brightness.name})', (
        tester,
      ) async {
        _phoneView(tester, physical: const Size(750, 1334), dpr: 2.0);
        await _pumpWelcome(tester, brightness: brightness);
        await tester.tap(find.byKey(const Key('welcome-sign-in')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('welcome-create-account')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Optometrist'));
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('brand colours', () {
    test('kPrimary is clinical blue', () {
      expect(kPrimary, const Color(0xFF1F5FAF));
      expect(kPrimaryDark, const Color(0xFF174A8A));
      expect(kPrimaryOnDark, const Color(0xFF5B8FD6));
    });

    test('theme primary is exactly the brand blue', () {
      expect(
        buildTheme(Brightness.light).colorScheme.primary,
        const Color(0xFF1F5FAF),
      );
      expect(
        buildTheme(Brightness.dark).colorScheme.primary,
        const Color(0xFF5B8FD6),
      );
      expect(buildTheme(Brightness.light).colorScheme.onPrimary, Colors.white);
    });
  });
}
