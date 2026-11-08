import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:bv_toolkit/screens/patients/patient_form_screen.dart';
import 'package:bv_toolkit/services/patient_service.dart';
import 'package:bv_toolkit/theme.dart';

void main() {
  test('status bar style follows brightness', () {
    expect(
      buildTheme(Brightness.light).appBarTheme.systemOverlayStyle,
      SystemUiOverlayStyle.dark,
    );
    expect(
      buildTheme(Brightness.dark).appBarTheme.systemOverlayStyle,
      SystemUiOverlayStyle.light,
    );
  });

  testWidgets('gender label aligns with first name', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: ChangeNotifierProvider(
          create: (_) => PatientService(),
          child: const PatientFormScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('Gender')).dx,
      tester.getTopLeft(find.text('First name *')).dx,
    );
  });
}
