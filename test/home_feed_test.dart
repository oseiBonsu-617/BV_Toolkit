import 'package:flutter_test/flutter_test.dart';
import 'package:bv_toolkit/data/clinical_pearls.dart';
import 'package:bv_toolkit/data/home_feed.dart';
import 'package:bv_toolkit/data/reference_data.dart';

void main() {
  group('clinical pearls', () {
    test('there are exactly 30', () {
      expect(kClinicalPearls, hasLength(30));
    });

    test('every pearl links to a Reference entry', () {
      for (final p in kClinicalPearls) {
        expect(
          referenceEntryByTitle(p.refTitle),
          isNotNull,
          reason: 'No Reference entry titled "${p.refTitle}"',
        );
      }
    });

    test('no two pearls say the same thing', () {
      final texts = kClinicalPearls.map((p) => p.text).toSet();
      expect(texts, hasLength(kClinicalPearls.length));
    });

    test('first and last are in the agreed order', () {
      expect(kClinicalPearls.first.refTitle, "Sheard's Criterion");
      expect(kClinicalPearls.last.refTitle, 'Amblyopia');
    });
  });

  group('pools', () {
    test('conditions are the anomaly and strabismus entries in order', () {
      const cats = {
        'Vergence anomalies',
        'Accommodative anomalies',
        'Strabismus',
      };
      expect(conditionPool, [
        for (final e in kReferenceEntries)
          if (cats.contains(e.cat)) e,
      ]);
      expect(conditionPool.first.title, 'Convergence Insufficiency');
    });

    test("norms leave out the three Morgan's entries", () {
      expect(normPool, isNotEmpty);
      expect(normPool.every((e) => e.cat == 'Norms'), isTrue);
      expect(normPool.any((e) => e.title.startsWith("Morgan's")), isFalse);
      expect(
        normPool.length,
        kReferenceEntries.where((e) => e.cat == 'Norms').length - 3,
      );
      expect(normPool.first.title, 'NPC Norms');
    });
  });

  group('greetingFor', () {
    String at(int h, int m) => greetingFor(DateTime(2026, 11, 8, h, m));

    test('switches at 5:00, 12:00 and 17:00', () {
      expect(at(4, 59), 'Good evening');
      expect(at(5, 0), 'Good morning');
      expect(at(11, 59), 'Good morning');
      expect(at(12, 0), 'Good afternoon');
      expect(at(16, 59), 'Good afternoon');
      expect(at(17, 0), 'Good evening');
      expect(at(0, 0), 'Good evening');
    });
  });

  group('firstNameOf', () {
    test('takes the first word, trimmed', () {
      expect(firstNameOf('Osei Smith'), 'Osei');
      expect(firstNameOf('  Ama   Owusu  '), 'Ama');
      expect(firstNameOf('Kofi'), 'Kofi');
      expect(firstNameOf(''), '');
      expect(firstNameOf('   '), '');
    });
  });

  group('dayIndex', () {
    test('counts local calendar days from 1970-01-01', () {
      expect(dayIndex(DateTime(1970, 1, 1)), 0);
      expect(dayIndex(DateTime(1970, 1, 2, 23, 59)), 1);
    });

    test('is the same all day', () {
      expect(
        dayIndex(DateTime(2026, 11, 8, 0, 0)),
        dayIndex(DateTime(2026, 11, 8, 23, 59, 59)),
      );
    });

    test('does not skip or repeat a day over a DST change', () {
      for (final (a, b) in [
        (DateTime(2026, 3, 28, 12), DateTime(2026, 3, 29, 12)),
        (DateTime(2026, 3, 29, 12), DateTime(2026, 3, 30, 12)),
        (DateTime(2026, 3, 8, 12), DateTime(2026, 3, 9, 12)),
        (DateTime(2026, 10, 25, 12), DateTime(2026, 10, 26, 12)),
        (DateTime(2026, 11, 1, 12), DateTime(2026, 11, 2, 12)),
      ]) {
        expect(dayIndex(b) - dayIndex(a), 1, reason: '$a → $b');
      }
    });
  });

  group('pearlFor', () {
    test('consecutive days give consecutive pearls and wrap after 30', () {
      final start = DateTime(2026, 11, 8, 9);
      final first = kClinicalPearls.indexOf(pearlFor(start));
      for (var i = 0; i < 61; i++) {
        final day = DateTime(start.year, start.month, start.day + i, 9);
        expect(pearlFor(day), kClinicalPearls[(first + i) % 30]);
      }
      final day30 = DateTime(start.year, start.month, start.day + 30, 9);
      expect(pearlFor(day30), pearlFor(start));
    });

    test('is the same pearl all day', () {
      expect(
        pearlFor(DateTime(2026, 11, 8, 0, 0)),
        pearlFor(DateTime(2026, 11, 8, 23, 59)),
      );
    });

    test('uses dayIndex mod 30', () {
      final now = DateTime(2026, 11, 8, 10);
      expect(pearlFor(now), kClinicalPearls[dayIndex(now) % 30]);
    });
  });

  group('normFor', () {
    test('rotates daily through the norm pool', () {
      final now = DateTime(2026, 11, 8, 10);
      expect(normFor(now), normPool[dayIndex(now) % normPool.length]);
      final next = DateTime(2026, 11, 9, 10);
      expect(normFor(next), normPool[(dayIndex(now) + 1) % normPool.length]);
    });
  });

  group('weekIndex and conditionFor', () {
    test('weeks start on Monday 1970-01-05', () {
      expect(weekIndex(DateTime(1970, 1, 5)), 0);
      expect(weekIndex(DateTime(1970, 1, 11, 23)), 0);
      expect(weekIndex(DateTime(1970, 1, 12)), 1);
    });

    test('condition holds Monday to Sunday and changes next Monday', () {
      // 2026-11-02 is a Monday.
      final monday = DateTime(2026, 11, 2, 0, 1);
      expect(monday.weekday, DateTime.monday);
      final c = conditionFor(monday);
      for (var d = 0; d < 7; d++) {
        expect(conditionFor(DateTime(2026, 11, 2 + d, 23, 59)), c);
      }
      final nextMonday = DateTime(2026, 11, 9, 0, 1);
      expect(conditionFor(nextMonday), isNot(c));
      expect(
        conditionFor(nextMonday),
        conditionPool[(weekIndex(monday) + 1) % conditionPool.length],
      );
    });
  });

  group('weekStart', () {
    test('is local Monday 00:00 of the same week', () {
      expect(weekStart(DateTime(2026, 11, 8, 20, 30)), DateTime(2026, 11, 2));
      expect(weekStart(DateTime(2026, 11, 2, 0, 0)), DateTime(2026, 11, 2));
      expect(weekStart(DateTime(2026, 11, 9, 8)), DateTime(2026, 11, 9));
    });
  });

  group('weekSummaryText', () {
    test('no sessions invites the user', () {
      expect(
        weekSummaryText(sessions: 0, patients: 0),
        'No sessions yet this week — ready when you are.',
      );
    });

    test('singular and plural', () {
      expect(
        weekSummaryText(sessions: 1, patients: 1),
        '1 session this week · 1 patient',
      );
      expect(
        weekSummaryText(sessions: 3, patients: 2),
        '3 sessions this week · 2 patients',
      );
    });
  });
}
