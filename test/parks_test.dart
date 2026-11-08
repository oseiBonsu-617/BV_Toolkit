import 'package:flutter_test/flutter_test.dart';
import 'package:bv_toolkit/models/parks_test.dart';

void main() {
  const R = Side.right, L = Side.left;
  final rows = <(Side, Side, Side, ParksMuscle)>[
    (R, L, R, ParksMuscle.rso),
    (R, L, L, ParksMuscle.lsr),
    (R, R, R, ParksMuscle.lio),
    (R, R, L, ParksMuscle.rir),
    (L, R, L, ParksMuscle.lso),
    (L, R, R, ParksMuscle.rsr),
    (L, L, L, ParksMuscle.rio),
    (L, L, R, ParksMuscle.lir),
  ];

  for (final (h, g, t, m) in rows) {
    test('hyper $h gaze $g tilt $t -> $m', () {
      final a = ParksAnalysis(hyper: h, gaze: g, tilt: t);
      expect(a.result, m);
      expect(a.candidates, [m]);
    });
  }

  test('nothing answered: all 8', () {
    const a = ParksAnalysis();
    expect(a.candidates.toSet(), ParksMuscle.values.toSet());
    expect(a.candidates.length, 8);
    expect(a.result, isNull);
  });

  test('after step 1', () {
    expect(const ParksAnalysis(hyper: R).candidates.toSet(),
        {ParksMuscle.rso, ParksMuscle.rir, ParksMuscle.lsr, ParksMuscle.lio});
    expect(const ParksAnalysis(hyper: L).candidates.toSet(),
        {ParksMuscle.lso, ParksMuscle.lir, ParksMuscle.rsr, ParksMuscle.rio});
    expect(const ParksAnalysis(hyper: R).result, isNull);
  });

  test('after step 2', () {
    expect(const ParksAnalysis(hyper: R, gaze: L).candidates.toSet(),
        {ParksMuscle.rso, ParksMuscle.lsr});
    expect(const ParksAnalysis(hyper: R, gaze: R).candidates.toSet(),
        {ParksMuscle.rir, ParksMuscle.lio});
    expect(const ParksAnalysis(hyper: L, gaze: R).candidates.toSet(),
        {ParksMuscle.lso, ParksMuscle.rsr});
    expect(const ParksAnalysis(hyper: L, gaze: L).candidates.toSet(),
        {ParksMuscle.lir, ParksMuscle.rio});
    expect(const ParksAnalysis(hyper: L, gaze: L).result, isNull);
  });

  test('later answers ignored without earlier ones', () {
    for (final a in [
      const ParksAnalysis(gaze: R),
      const ParksAnalysis(tilt: L),
      const ParksAnalysis(gaze: L, tilt: R),
    ]) {
      expect(a.candidates.length, 8);
      expect(a.result, isNull);
    }
    final b = const ParksAnalysis(hyper: R, tilt: L);
    expect(b.candidates.length, 4);
    expect(b.result, isNull);
  });

  test('nerves and names', () {
    expect(ParksMuscle.rso.nerve, 'CN IV');
    expect(ParksMuscle.lso.nerve, 'CN IV');
    for (final m in ParksMuscle.values.where(
        (m) => m != ParksMuscle.rso && m != ParksMuscle.lso)) {
      expect(m.nerve, 'CN III');
    }
    expect(ParksMuscle.rso.name, 'Right superior oblique');
    expect(ParksMuscle.lio.name, 'Left inferior oblique');
    expect(ParksMuscle.rsr.name, 'Right superior rectus');
    expect(ParksMuscle.lir.name, 'Left inferior rectus');
  });
}
