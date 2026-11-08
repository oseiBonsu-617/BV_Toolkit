import 'package:flutter_test/flutter_test.dart';
import 'package:bv_toolkit/models/patient.dart';
import 'package:bv_toolkit/services/patient_service.dart';

Patient _p(String id, DateTime updated) => Patient(
      id: id,
      userId: 'u',
      firstName: 'F$id',
      lastName: 'L$id',
      createdAt: DateTime(2025, 1, 1),
      updatedAt: updated,
    );

void main() {
  test('recentOf returns newest updatedAt first, capped at limit', () {
    final list = [
      _p('a', DateTime(2026, 1, 1)),
      _p('b', DateTime(2026, 3, 1)),
      _p('c', DateTime(2026, 2, 1)),
      _p('d', DateTime(2026, 4, 1)),
    ];
    expect(PatientService.recentOf(list).map((p) => p.id), ['d', 'b', 'c']);
  });

  test('recentOf of empty list is empty', () {
    expect(PatientService.recentOf([]), isEmpty);
  });
}
