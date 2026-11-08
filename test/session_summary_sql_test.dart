import 'package:flutter_test/flutter_test.dart';
import 'package:bv_toolkit/services/session_service.dart';

// sqflite does not run under flutter test, so this checks the query text.
void main() {
  test("the week count leaves out deleted patients' sessions", () {
    final sql = SessionService.weekSummarySql.replaceAll(RegExp(r'\s+'), ' ');
    expect(
      sql,
      contains('patient_id IN (SELECT id FROM patients WHERE user_id = ?)'),
    );
    expect(sql, contains('user_id = ? AND created_at >= ?'));
    expect('?'.allMatches(sql), hasLength(3));
  });
}
