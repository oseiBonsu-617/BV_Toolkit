import 'package:flutter_test/flutter_test.dart';
import 'package:bv_toolkit/main.dart';
import 'package:bv_toolkit/services/auth_service.dart';
import 'package:bv_toolkit/services/patient_service.dart';
import 'package:bv_toolkit/services/preferences_service.dart';
import 'package:bv_toolkit/services/session_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
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

    expect(find.text('BV Toolkit'), findsOneWidget);
  });
}
