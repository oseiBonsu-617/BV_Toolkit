import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/tools.dart';

class PreferencesService extends ChangeNotifier {
  PreferencesService({Future<SharedPreferences> Function()? prefs})
      : _prefs = prefs ?? SharedPreferences.getInstance;

  static const homeShortcutsKey = 'home_shortcuts';

  final Future<SharedPreferences> Function() _prefs;
  List<String> _homeShortcuts = List.of(kDefaultShortcuts);

  List<String> get homeShortcuts => List.unmodifiable(_homeShortcuts);

  static List<String> _clean(Iterable<String> ids) {
    final valid = kShortcuts.map((s) => s.id).toSet();
    final seen = <String>{};
    final out = <String>[];
    for (final id in ids) {
      if (valid.contains(id) && seen.add(id)) out.add(id);
    }
    return out.isEmpty ? List.of(kDefaultShortcuts) : out;
  }

  Future<void> load() async {
    try {
      final p = await _prefs();
      final saved = p.getStringList(homeShortcutsKey);
      if (saved != null) _homeShortcuts = _clean(saved);
    } catch (_) {
      // Keep defaults on any storage error.
    }
    notifyListeners();
  }

  Future<void> setHomeShortcuts(List<String> ids) async {
    _homeShortcuts = _clean(ids);
    notifyListeners();
    try {
      final p = await _prefs();
      await p.setStringList(homeShortcutsKey, _homeShortcuts);
    } catch (_) {
      // Write failure is non-fatal; in-memory value stays.
    }
  }
}
