import 'package:flutter_test/flutter_test.dart';
import 'package:bv_toolkit/models/graphical_analysis.dart';
import 'package:bv_toolkit/widgets/result_card.dart';

void main() {
  group('ZCSBV geometry', () {
    test('reproduces the reference example', () {
      final g = GAGeometry.from(const GAInputs(
        distPhoria: 1, nearPhoria: 3, ipdMm: 65, nearDistCm: 40,
        distBoBlur: 7, distBoBreak: 15, nearBoBlur: 17, nearBoBreak: 21,
        distBiBlur: 7, distBiBreak: 15, nearBiBlur: 13, nearBiBreak: 21,
        nra: 2.0, pra: 2.5,
      ));
      expect(g.accNear, 2.5);
      expect(g.nearDemandV, 16.25);
      expect(g.phoriaDistV, -1);
      expect(g.phoriaNearV, 13.25);
      expect(g.boBreak!.distance.v, 14);
      expect(g.boBreak!.near.v, 34.25);
      expect(g.boBlur!.distance.v, 6);
      expect(g.boBlur!.near.v, 30.25);
      expect(g.biBreak!.distance.v, -16);
      expect(g.biBreak!.near.v, -7.75);
      expect(g.biBlur!.near.v, 0.25);
      expect(g.nraA, 0.5);
      expect(g.praA, 5.0);
    });

    test('leaves reserve lines null when values are missing', () {
      final g = GAGeometry.from(const GAInputs(
        distPhoria: 0, nearPhoria: 0, ipdMm: 64, nearDistCm: 40,
      ));
      expect(g.boBreak, isNull);
      expect(g.biBlur, isNull);
      expect(g.zone, isNull);
      expect(g.nraA, isNull);
    });
  });

  group('interpretation', () {
    test('reads the reference example as compensated / passing', () {
      final f = GAGeometry.from(const GAInputs(
        distPhoria: 1, nearPhoria: 3, ipdMm: 65, nearDistCm: 40,
        distBoBlur: 7, distBoBreak: 15, nearBoBlur: 17, nearBoBreak: 21,
        distBiBlur: 7, distBiBreak: 15, nearBiBlur: 13, nearBiBreak: 21,
        nra: 2.0, pra: 2.5,
      )).interpret();
      final sheards = f.firstWhere((x) => x.label.startsWith("Sheard's"));
      expect(sheards.type, ResultType.ok);
      expect(f.any((x) => x.label == 'Overall impression'), isTrue);
    });

    test('flags a convergence insufficiency pattern', () {
      final f = GAGeometry.from(const GAInputs(
        distPhoria: 1, nearPhoria: 10, ipdMm: 64, nearDistCm: 40,
        distBoBlur: 5, distBoBreak: 10, nearBoBlur: 6, nearBoBreak: 12,
        distBiBlur: 8, distBiBreak: 16, nearBiBlur: 12, nearBiBreak: 20,
        nra: 2.0, pra: 2.5,
      )).interpret();
      final pattern = f.firstWhere((x) => x.label == 'Phoria line pattern');
      expect(pattern.note, contains('Convergence insufficiency'));
      final sheards = f.firstWhere((x) => x.label.startsWith("Sheard's"));
      expect(sheards.type, ResultType.bad);
    });
  });
}
