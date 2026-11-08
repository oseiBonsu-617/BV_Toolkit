// What Home shows today: the greeting, this week's summary line, and the
// daily pearl and norm and weekly condition. Pure functions of the time.

import 'clinical_pearls.dart';
import 'reference_data.dart';

const _conditionCats = {
  'Vergence anomalies',
  'Accommodative anomalies',
  'Strabismus',
};

/// Entries Home can show as the condition of the week, in Reference order.
final List<ReferenceEntry> conditionPool = [
  for (final e in kReferenceEntries)
    if (_conditionCats.contains(e.cat)) e,
];

/// Entries Home can show as the norm spotlight, in Reference order. The
/// Morgan's norms entries are left out: "See all norms" shows that table.
final List<ReferenceEntry> normPool = [
  for (final e in kReferenceEntries)
    if (e.cat == 'Norms' && !e.title.startsWith("Morgan's Norms")) e,
];

/// Days from 1970-01-01 to [now]'s local calendar date. Counted on UTC
/// dates, so a daylight-saving change can't skip or repeat a day.
int dayIndex(DateTime now) => DateTime.utc(
  now.year,
  now.month,
  now.day,
).difference(DateTime.utc(1970, 1, 1)).inDays;

/// Whole weeks from Monday 1970-01-05 to the Monday of [now]'s local week.
int weekIndex(DateTime now) {
  final monday = dayIndex(now) - (now.weekday - DateTime.monday);
  return ((monday - 4) / 7).floor();
}

/// Local Monday 00:00 of [now]'s week.
DateTime weekStart(DateTime now) =>
    DateTime(now.year, now.month, now.day - (now.weekday - DateTime.monday));

/// Today's pearl: the same all day, the next one tomorrow.
ClinicalPearl pearlFor(DateTime now) =>
    kClinicalPearls[dayIndex(now) % kClinicalPearls.length];

/// Today's norm spotlight.
ReferenceEntry normFor(DateTime now) =>
    normPool[dayIndex(now) % normPool.length];

/// This week's condition: the same Monday to Sunday.
ReferenceEntry conditionFor(DateTime now) =>
    conditionPool[weekIndex(now) % conditionPool.length];

/// "Good morning" from 05:00, "Good afternoon" from 12:00, "Good evening"
/// from 17:00 until 04:59.
String greetingFor(DateTime now) {
  final h = now.hour;
  if (h >= 5 && h < 12) return 'Good morning';
  if (h >= 12 && h < 17) return 'Good afternoon';
  return 'Good evening';
}

/// The first word of [displayName], or '' if it has none.
String firstNameOf(String displayName) {
  final words = displayName.trim().split(RegExp(r'\s+'));
  return words.first;
}

/// The line under the greeting about this week's sessions.
String weekSummaryText({required int sessions, required int patients}) {
  if (sessions == 0) return 'No sessions yet this week — ready when you are.';
  final s = sessions == 1 ? '' : 's';
  final p = patients == 1 ? '' : 's';
  return '$sessions session$s this week · $patients patient$p';
}
