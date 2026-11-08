import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bv_toolkit/screens/patients/session_record_screen.dart';
import 'package:bv_toolkit/services/patient_service.dart';
import 'package:bv_toolkit/services/session_service.dart';
import 'package:bv_toolkit/theme.dart';

/// Pumps a start page and opens [SessionRecordScreen] on top of it.
Future<void> openSessionForm(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PatientService()),
        ChangeNotifierProvider(create: (_) => SessionService()),
      ],
      child: MaterialApp(
        theme: buildTheme(Brightness.light),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                appRoute(const SessionRecordScreen(patientId: 'p1')),
              ),
              child: const Text('start page'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('start page'));
  await tester.pumpAndSettle();
  expect(find.byType(SessionRecordScreen), findsOneWidget);
}

Future<void> pressBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

Future<void> typeVisitNote(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField).first, 'Follow-up');
  await tester.pump();
}

void main() {
  testWidgets('back with no input pops without asking', (tester) async {
    await openSessionForm(tester);
    await pressBack(tester);
    expect(find.text('Discard this session?'), findsNothing);
    expect(find.byType(SessionRecordScreen), findsNothing);
    expect(find.text('start page'), findsOneWidget);
  });

  testWidgets('back with input asks; Keep editing stays', (tester) async {
    await openSessionForm(tester);
    await typeVisitNote(tester);
    await pressBack(tester);
    expect(find.text('Discard this session?'), findsOneWidget);
    expect(
      find.text("The findings you entered haven't been saved."),
      findsOneWidget,
    );
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.text('Discard this session?'), findsNothing);
    expect(find.byType(SessionRecordScreen), findsOneWidget);
    expect(find.text('Follow-up'), findsOneWidget);
  });

  testWidgets('close button with input asks; Discard pops', (tester) async {
    await openSessionForm(tester);
    await typeVisitNote(tester);
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    expect(find.text('Discard this session?'), findsOneWidget);
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.byType(SessionRecordScreen), findsNothing);
    expect(find.text('start page'), findsOneWidget);
  });

  testWidgets('a measurement entered also counts as unsaved input', (
    tester,
  ) async {
    await openSessionForm(tester);
    await tester.tap(find.text('NPC'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(1), '6');
    await tester.pump();
    await pressBack(tester);
    expect(find.text('Discard this session?'), findsOneWidget);
  });
}
