/// Park's three-step test: narrows a single paretic cyclovertical muscle
/// from three yes/no cover-test findings.
enum Side { right, left }

enum ParksMuscle { rso, rsr, rir, rio, lso, lsr, lir, lio }

extension ParksMuscleX on ParksMuscle {
  /// Display name, e.g. 'Right superior oblique'. (Shadows [Enum.name] for
  /// this type; use `(m as Enum).name` for the identifier.)
  String get name => switch (this) {
    ParksMuscle.rso => 'Right superior oblique',
    ParksMuscle.rsr => 'Right superior rectus',
    ParksMuscle.rir => 'Right inferior rectus',
    ParksMuscle.rio => 'Right inferior oblique',
    ParksMuscle.lso => 'Left superior oblique',
    ParksMuscle.lsr => 'Left superior rectus',
    ParksMuscle.lir => 'Left inferior rectus',
    ParksMuscle.lio => 'Left inferior oblique',
  };

  String get nerve =>
      (this == ParksMuscle.rso || this == ParksMuscle.lso) ? 'CN IV' : 'CN III';
}

class ParksAnalysis {
  const ParksAnalysis({this.hyper, this.gaze, this.tilt});

  /// Step 1: which eye is higher in primary gaze.
  final Side? hyper;

  /// Step 2: the hypertropia is greater on gaze to the ...
  final Side? gaze;

  /// Step 3: the hypertropia is greater on head tilt to the ...
  final Side? tilt;

  static const _step1 = {
    Side.right: [
      ParksMuscle.rso,
      ParksMuscle.rir,
      ParksMuscle.lsr,
      ParksMuscle.lio,
    ],
    Side.left: [
      ParksMuscle.lso,
      ParksMuscle.lir,
      ParksMuscle.rsr,
      ParksMuscle.rio,
    ],
  };

  // Keyed by (hyper, gaze).
  static const _step2 = {
    (Side.right, Side.left): [ParksMuscle.rso, ParksMuscle.lsr],
    (Side.right, Side.right): [ParksMuscle.rir, ParksMuscle.lio],
    (Side.left, Side.right): [ParksMuscle.lso, ParksMuscle.rsr],
    (Side.left, Side.left): [ParksMuscle.lir, ParksMuscle.rio],
  };

  // Keyed by (hyper, gaze, tilt).
  static const _step3 = {
    (Side.right, Side.left, Side.right): ParksMuscle.rso,
    (Side.right, Side.left, Side.left): ParksMuscle.lsr,
    (Side.right, Side.right, Side.right): ParksMuscle.lio,
    (Side.right, Side.right, Side.left): ParksMuscle.rir,
    (Side.left, Side.right, Side.left): ParksMuscle.lso,
    (Side.left, Side.right, Side.right): ParksMuscle.rsr,
    (Side.left, Side.left, Side.left): ParksMuscle.rio,
    (Side.left, Side.left, Side.right): ParksMuscle.lir,
  };

  /// Candidates still consistent with the answers so far (8 before step 1,
  /// 4 after step 1, 2 after step 2, 1 after step 3). A later answer is
  /// ignored while an earlier step is unanswered.
  List<ParksMuscle> get candidates {
    final h = hyper;
    if (h == null) return ParksMuscle.values;
    final g = gaze;
    if (g == null) return _step1[h]!;
    final t = tilt;
    if (t == null) return _step2[(h, g)]!;
    return [_step3[(h, g, t)]!];
  }

  /// Non-null only when all three steps are answered.
  ParksMuscle? get result {
    final h = hyper, g = gaze, t = tilt;
    if (h == null || g == null || t == null) return null;
    return _step3[(h, g, t)];
  }
}
