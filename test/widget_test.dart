import 'package:flutter_test/flutter_test.dart';
import 'package:bv_toolkit/main.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const BVToolkitApp());
    expect(find.text('BV Toolkit'), findsOneWidget);
  });
}
