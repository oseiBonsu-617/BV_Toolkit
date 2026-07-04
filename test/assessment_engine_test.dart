import 'package:flutter_test/flutter_test.dart';
import 'package:bv_toolkit/models/test_session.dart';
import 'package:bv_toolkit/services/assessment_engine.dart';

TestSession _session(Map<String, dynamic> data) => TestSession(
  id: '',
  patientId: 'p',
  userId: 'u',
  date: DateTime(2026, 1, 1),
  data: data,
  createdAt: DateTime(2026, 1, 1),
);

void main() {
  final engine = AssessmentEngine();

  test('plan derives from phoria + NPC section keys', () {
    final plan = engine.planFromSession(
      _session({'ph_near': 8.0, 'npc_brk': 12.0}),
    );
    expect(plan, isNotNull);
    expect(plan!.name, contains('Convergence Insufficiency'));
  });

  test('plan falls back to dx_* diagnosis-input keys', () {
    // Only the Diagnosis inputs section filled — used to return null.
    final plan = engine.planFromSession(
      _session({'dx_pn': 8.0, 'dx_nb': 12.0}),
    );
    expect(plan, isNotNull);
    expect(plan!.name, contains('Convergence Insufficiency'));
  });

  test('returns null when no phoria is recorded anywhere', () {
    expect(engine.planFromSession(_session({'npc_brk': 12.0})), isNull);
  });
}
