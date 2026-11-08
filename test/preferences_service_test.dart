import 'package:bv_toolkit/config/tools.dart';
import 'package:bv_toolkit/services/preferences_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('defaults when nothing saved', () async {
    SharedPreferences.setMockInitialValues({});
    final s = PreferencesService(); await s.load();
    expect(s.homeShortcuts, ['phoria', 'vergence', 'graphical']);
  });
  test('reads saved list in order', () async {
    SharedPreferences.setMockInitialValues({'home_shortcuts': ['diagnose', 'reference', 'analysis']});
    final s = PreferencesService(); await s.load();
    expect(s.homeShortcuts, ['diagnose', 'reference', 'analysis']);
  });
  test('drops unknown ids and duplicates', () async {
    SharedPreferences.setMockInitialValues({'home_shortcuts': ['plans', 'diagnose', 'diagnose', 'sessions', 'patients']});
    final s = PreferencesService(); await s.load();
    expect(s.homeShortcuts, ['diagnose', 'patients']);
  });
  test('only unknown ids falls back to defaults', () async {
    SharedPreferences.setMockInitialValues({'home_shortcuts': ['plans', 'sessions']});
    final s = PreferencesService(); await s.load();
    expect(s.homeShortcuts, kDefaultShortcuts);
  });
  test('setHomeShortcuts persists and notifies', () async {
    SharedPreferences.setMockInitialValues({});
    final s = PreferencesService(); await s.load();
    var notified = 0; s.addListener(() => notified++);
    await s.setHomeShortcuts(['graphical', 'patients', 'diagnose']);
    expect(s.homeShortcuts, ['graphical', 'patients', 'diagnose']);
    expect(notified, 1);
    final again = PreferencesService(); await again.load();
    expect(again.homeShortcuts, ['graphical', 'patients', 'diagnose']);
  });
  test('storage failure keeps in-memory value and never throws', () async {
    SharedPreferences.setMockInitialValues({});
    final s = PreferencesService(prefs: () async => throw Exception('disk'));
    await s.load();
    expect(s.homeShortcuts, kDefaultShortcuts);
    await s.setHomeShortcuts(['diagnose', 'reference', 'analysis']);
    expect(s.homeShortcuts, ['diagnose', 'reference', 'analysis']);
  });
  test('kTools and kShortcuts shape', () {
    expect(kTools.map((t) => t.id), ['phoria', 'vergence', 'accommodation', 'analysis', 'graphical', 'diagnose', 'parks']);
    expect(kShortcuts.length, 9);
    expect(kShortcuts.map((s) => s.id).skip(7), ['patients', 'reference']);
  });
}
