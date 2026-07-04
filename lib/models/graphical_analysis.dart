import 'dart:math' as math;
import '../widgets/result_card.dart' show ResultType;

/// A single point in graph coordinates.
/// [v] = vergence in prism dioptres (BO / convergence positive, BI / divergence
/// negative). [a] = accommodation in dioptres (distance ~0 D, near ~2.5 D).
class GAPoint {
  final double v;
  final double a;
  const GAPoint(this.v, this.a);
}

/// A line drawn between a distance and a near point.
class GALine {
  final GAPoint distance;
  final GAPoint near;
  const GALine(this.distance, this.near);
}

/// A single interpretation finding, rendered as a [ResultCard].
class GAFinding {
  final ResultType type;
  final String label;
  final String value;
  final String? note;
  const GAFinding(this.type, this.label, this.value, this.note);
}

/// Raw clinical inputs for a binocular graphical analysis.
///
/// Phoria values are *signed*: exophoria positive, esophoria negative
/// (matching [PhoriaField.signedValue]). Fusional reserve blur values are
/// optional (distance BI blur in particular is often absent).
class GAInputs {
  final double distPhoria; // signed, exo +, eso -
  final double nearPhoria;
  final double ipdMm;
  final double nearDistCm;

  final double? distBoBlur; // PFV distance
  final double? distBoBreak;
  final double? nearBoBlur; // PFV near
  final double? nearBoBreak;

  final double? distBiBlur; // NFV distance
  final double? distBiBreak;
  final double? nearBiBlur; // NFV near
  final double? nearBiBreak;

  final double? nra; // magnitude of plus-to-blur (D)
  final double? pra; // magnitude of minus-to-blur (D)

  const GAInputs({
    required this.distPhoria,
    required this.nearPhoria,
    required this.ipdMm,
    required this.nearDistCm,
    this.distBoBlur,
    this.distBoBreak,
    this.nearBoBlur,
    this.nearBoBreak,
    this.distBiBlur,
    this.distBiBreak,
    this.nearBiBlur,
    this.nearBiBreak,
    this.nra,
    this.pra,
  });
}

/// Fully computed geometry for the ZCSBV plot, derived from [GAInputs].
class GAGeometry {
  final GAInputs input;

  /// Accommodation level at near (D) — 100 / nearDist(cm).
  final double accNear;

  /// Convergence demand at near (Δ) — IPD(mm) × 10 / nearDist(cm).
  final double nearDemandV;

  /// Phoria vergence position at distance / near.
  final double phoriaDistV;
  final double phoriaNearV;

  final GALine demandLine;
  final GALine phoriaLine;

  final GALine? boBlur;
  final GALine? boBreak;
  final GALine? biBlur;
  final GALine? biBreak;

  /// The four ZCSBV corner points (BI break dist, BO break dist,
  /// BO break near, BI break near) — only present when all four breaks exist.
  final List<GAPoint>? zone;

  /// NRA / PRA vertical: top (relaxed) and bottom (stimulated) accommodation.
  final double? nraA; // accNear - NRA
  final double? praA; // accNear + PRA
  final double nrPraV; // vergence position of the NRA/PRA line

  GAGeometry._({
    required this.input,
    required this.accNear,
    required this.nearDemandV,
    required this.phoriaDistV,
    required this.phoriaNearV,
    required this.demandLine,
    required this.phoriaLine,
    required this.boBlur,
    required this.boBreak,
    required this.biBlur,
    required this.biBreak,
    required this.zone,
    required this.nraA,
    required this.praA,
    required this.nrPraV,
  });

  factory GAGeometry.from(GAInputs i) {
    final accNear = i.nearDistCm > 0 ? 100 / i.nearDistCm : 2.5;
    final nearDemandV = i.nearDistCm > 0 ? i.ipdMm * 10 / i.nearDistCm : 0.0;

    final phoriaDistV = 0 - i.distPhoria;
    final phoriaNearV = nearDemandV - i.nearPhoria;

    GALine? lineFrom(double? d, double? n, {required bool positive}) {
      if (d == null || n == null) return null;
      final sign = positive ? 1 : -1;
      return GALine(
        GAPoint(phoriaDistV + sign * d, 0),
        GAPoint(phoriaNearV + sign * n, accNear),
      );
    }

    final boBlur = lineFrom(i.distBoBlur, i.nearBoBlur, positive: true);
    final boBreak = lineFrom(i.distBoBreak, i.nearBoBreak, positive: true);
    final biBlur = lineFrom(i.distBiBlur, i.nearBiBlur, positive: false);
    final biBreak = lineFrom(i.distBiBreak, i.nearBiBreak, positive: false);

    List<GAPoint>? zone;
    if (biBreak != null && boBreak != null) {
      zone = [
        biBreak.distance,
        boBreak.distance,
        boBreak.near,
        biBreak.near,
      ];
    }

    return GAGeometry._(
      input: i,
      accNear: accNear,
      nearDemandV: nearDemandV,
      phoriaDistV: phoriaDistV,
      phoriaNearV: phoriaNearV,
      demandLine: GALine(const GAPoint(0, 0), GAPoint(nearDemandV, accNear)),
      phoriaLine: GALine(
        GAPoint(phoriaDistV, 0),
        GAPoint(phoriaNearV, accNear),
      ),
      boBlur: boBlur,
      boBreak: boBreak,
      biBlur: biBlur,
      biBreak: biBreak,
      zone: zone,
      nraA: i.nra != null ? accNear - i.nra! : null,
      praA: i.pra != null ? accNear + i.pra! : null,
      nrPraV: nearDemandV,
    );
  }

  /// Builds the ordered list of interpretation findings.
  List<GAFinding> interpret() => GAInterpreter(this).build();
}

/// Turns computed [GAGeometry] into a ranked list of clinical findings.
class GAInterpreter {
  final GAGeometry g;
  GAInterpreter(this.g);

  static String _phoriaDesc(double signed) {
    final mag = signed.abs().toStringAsFixed(1);
    if (signed == 0) return 'ortho';
    return signed > 0 ? '$mag$_delta exo' : '$mag$_delta eso';
  }

  static const _delta = 'Δ';

  List<GAFinding> build() {
    final out = <GAFinding>[];
    out.add(_demandPositionNear());
    final sheards = _sheardsNear();
    if (sheards != null) out.add(sheards);
    final percival = _percivalNear();
    if (percival != null) out.add(percival);
    out.add(_zoneSize());
    out.add(_phoriaPattern());
    final nrpra = _nraPra();
    if (nrpra != null) out.add(nrpra);
    out.add(_overallPattern());
    return out;
  }

  // 1. Where the near demand sits within the near ZCSBV width.
  GAFinding _demandPositionNear() {
    final bi = g.biBreak?.near.v;
    final bo = g.boBreak?.near.v;
    if (bi == null || bo == null || bo <= bi) {
      return const GAFinding(
        ResultType.info,
        'Demand within zone',
        'Insufficient data',
        'Enter BO and BI break at near to locate the demand line in the zone.',
      );
    }
    final frac = (g.nearDemandV - bi) / (bo - bi);
    if (frac < 0 || frac > 1) {
      return const GAFinding(
        ResultType.bad,
        'Demand within zone (near)',
        'Outside the zone',
        'The near demand falls beyond the fusional break — single binocular vision is not sustainable at near without correction.',
      );
    }
    if (frac >= 1 / 3 && frac <= 2 / 3) {
      return GAFinding(
        ResultType.ok,
        'Demand within zone (near)',
        'Middle third (${(frac * 100).round()}%)',
        'Demand sits in the central third of the zone — balanced fusional load (Percival satisfied).',
      );
    }
    final side = frac < 0.5 ? 'BI (divergence) side' : 'BO (convergence) side';
    return GAFinding(
      ResultType.warn,
      'Demand within zone (near)',
      'Outer third — $side',
      'Demand is eccentric toward the $side; the patient is under vergence stress and may be symptomatic.',
    );
  }

  // 3. Sheard's criterion at near, applied to the compensating reserve.
  GAFinding? _sheardsNear() {
    final phoria = g.input.nearPhoria;
    final mag = phoria.abs();
    if (mag == 0) return null;
    final exo = phoria > 0;
    // Compensating reserve opposes the phoria: exo → PFV(BO), eso → NFV(BI).
    final reserve = exo
        ? (g.input.nearBoBlur ?? g.input.nearBoBreak)
        : (g.input.nearBiBlur ?? g.input.nearBiBreak);
    if (reserve == null) return null;
    final pass = reserve >= 2 * mag;
    final prism = ((2 * mag - reserve) / 3).clamp(0.0, double.infinity);
    final dir = exo ? 'BI' : 'BO';
    return pass
        ? GAFinding(
            ResultType.ok,
            "Sheard's criterion (near)",
            'Passes',
            'Compensating reserve ${reserve.toStringAsFixed(0)}$_delta ≥ 2 × phoria (${mag.toStringAsFixed(1)}$_delta).',
          )
        : GAFinding(
            ResultType.bad,
            "Sheard's criterion (near)",
            'Fails',
            'Reserve ${reserve.toStringAsFixed(0)}$_delta below twice the ${mag.toStringAsFixed(1)}$_delta phoria — consider ${prism.toStringAsFixed(2)}$_delta $dir or vergence therapy.',
          );
  }

  // 4. Percival's criterion at near (greater / lesser of the total breaks).
  GAFinding? _percivalNear() {
    final bo = g.input.nearBoBreak;
    final bi = g.input.nearBiBreak;
    if (bo == null || bi == null) return null;
    final greater = math.max(bo, bi);
    final lesser = math.min(bo, bi);
    final pass = lesser >= greater / 2;
    final prism = (greater / 3 - 2 * lesser / 3).clamp(0.0, double.infinity);
    final dir = bo < bi ? 'BI' : 'BO';
    return pass
        ? GAFinding(
            ResultType.ok,
            "Percival's criterion (near)",
            'Passes',
            'Lesser reserve ${lesser.toStringAsFixed(0)}$_delta ≥ half of greater ${greater.toStringAsFixed(0)}$_delta.',
          )
        : GAFinding(
            ResultType.bad,
            "Percival's criterion (near)",
            'Fails',
            'Zone unbalanced — consider ${prism.toStringAsFixed(2)}$_delta $dir to re-centre the demand.',
          );
  }

  // 2. Zone size (horizontal fusional width + vertical accommodative height).
  GAFinding _zoneSize() {
    final parts = <String>[];
    ResultType worst = ResultType.ok;

    void note(String s, ResultType t) {
      parts.add(s);
      if (t == ResultType.bad) worst = ResultType.bad;
      if (t == ResultType.warn && worst != ResultType.bad) worst = ResultType.warn;
    }

    final biN = g.biBreak?.near.v, boN = g.boBreak?.near.v;
    if (biN != null && boN != null) {
      final width = boN - biN;
      final t = width < 20
          ? ResultType.warn
          : ResultType.ok;
      note('Near width ${width.toStringAsFixed(0)}$_delta', t);
    }
    final biD = g.biBreak?.distance.v, boD = g.boBreak?.distance.v;
    if (biD != null && boD != null) {
      final width = boD - biD;
      note('Distance width ${width.toStringAsFixed(0)}$_delta', ResultType.info == worst ? ResultType.ok : ResultType.ok);
    }
    if (g.input.nra != null && g.input.pra != null) {
      final height = g.input.nra! + g.input.pra!;
      final t = height < 3 ? ResultType.warn : ResultType.ok;
      note('Vertical ${height.toStringAsFixed(2)} D (NRA+PRA)', t);
    }

    if (parts.isEmpty) {
      return const GAFinding(
        ResultType.info,
        'Zone size',
        'Insufficient data',
        'Enter break values and NRA/PRA to size the zone.',
      );
    }
    return GAFinding(
      worst,
      'Zone size',
      parts.join('  ·  '),
      worst == ResultType.ok
          ? 'A wide zone indicates good fusional and accommodative flexibility.'
          : 'A compressed zone is the hallmark of binocular vision dysfunction.',
    );
  }

  // 5. Phoria line pattern (distance vs near).
  GAFinding _phoriaPattern() {
    final d = g.input.distPhoria;
    final n = g.input.nearPhoria;
    final diff = n - d; // positive → more exo at near
    final descr = 'Distance ${_phoriaDesc(d)}, near ${_phoriaDesc(n)}';

    String pattern;
    ResultType type;
    if (diff > 3 && n > 2) {
      pattern = 'Convergence insufficiency pattern — near diverges further (low AC/A).';
      type = ResultType.warn;
    } else if (diff < -3 && n < -2) {
      pattern = 'Convergence excess pattern — near more eso (high AC/A).';
      type = ResultType.warn;
    } else if (d > 6 && diff < -2) {
      pattern = 'Divergence excess pattern — high distance exophoria.';
      type = ResultType.warn;
    } else if (d < -3 && diff > 2) {
      pattern = 'Divergence insufficiency pattern — distance esophoria.';
      type = ResultType.warn;
    } else if (d > 2 && n > 2) {
      pattern = 'Basic exophoria — consistent exo at distance and near.';
      type = ResultType.info;
    } else if (d < -2 && n < -2) {
      pattern = 'Basic esophoria — consistent eso at distance and near.';
      type = ResultType.info;
    } else {
      pattern = 'Phoria within normal range at both distances.';
      type = ResultType.ok;
    }
    return GAFinding(type, 'Phoria line pattern', descr, pattern);
  }

  // 6. NRA / PRA balance.
  GAFinding? _nraPra() {
    final nra = g.input.nra;
    final pra = g.input.pra;
    if (nra == null || pra == null) return null;
    final balancedAdd = (nra - pra) / 2; // + → net plus add indicated
    final diff = nra - pra;

    ResultType type;
    String note;
    if (diff.abs() <= 0.5) {
      type = ResultType.ok;
      note = 'NRA and PRA are balanced and centred on the near demand.';
    } else if (diff > 0.5) {
      type = ResultType.warn;
      note = 'NRA exceeds PRA — possible over-minus or accommodative excess; a +${balancedAdd.toStringAsFixed(2)} D add would re-centre.';
    } else {
      type = ResultType.warn;
      note = 'PRA exceeds NRA — reduced ability to relax accommodation; a ${balancedAdd.toStringAsFixed(2)} D change would re-centre.';
    }
    if (pra < 1.5) {
      type = ResultType.warn;
      note = 'Low PRA (${pra.toStringAsFixed(2)} D) — accommodative insufficiency, difficulty sustaining near effort. $note';
    } else if (nra < 1.5) {
      type = ResultType.warn;
      note = 'Low NRA (${nra.toStringAsFixed(2)} D) — accommodative excess / infacility. $note';
    }
    return GAFinding(
      type,
      'NRA / PRA',
      '+${nra.toStringAsFixed(2)} D / −${pra.toStringAsFixed(2)} D',
      note,
    );
  }

  // 7. Overall pattern recognition.
  GAFinding _overallPattern() {
    final n = g.input.nearPhoria;
    final biN = g.biBreak?.near.v, boN = g.boBreak?.near.v;
    final width = (biN != null && boN != null) ? boN - biN : null;
    final narrow = width != null && width < 20;

    String dx;
    ResultType type;
    if (width == null) {
      dx = 'Enter distance and near breaks for full pattern recognition.';
      type = ResultType.info;
    } else if (narrow && n > 2) {
      dx = 'Small zone with the phoria line left of demand and reduced PFV — consistent with Convergence Insufficiency. Consider base-in prism or vergence therapy.';
      type = ResultType.warn;
    } else if (narrow && n < -2) {
      dx = 'Small zone with the phoria line right of demand and reduced NFV — consistent with Convergence Excess. Consider a plus add at near.';
      type = ResultType.warn;
    } else if (!narrow) {
      dx = 'Zone is adequate. If the demand line is eccentric, treat as a compensated heterophoria — prescribe prism or vision therapy as symptoms dictate.';
      type = ResultType.ok;
    } else {
      dx = 'Compressed zone — evaluate for accommodative or vergence dysfunction.';
      type = ResultType.warn;
    }
    return GAFinding(type, 'Overall impression', 'Pattern summary', dx);
  }
}
