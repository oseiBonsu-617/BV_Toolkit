import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/test_session.dart';
import 'database_helper.dart';

class SessionService extends ChangeNotifier {
  String? _userId;
  // patientId → sessions (newest first)
  final Map<String, List<TestSession>> _cache = {};

  Future<void> setUserId(String? userId) async {
    if (_userId == userId) return;
    _userId = userId;
    _cache.clear();
    notifyListeners();
  }

  Future<List<TestSession>> forPatient(String patientId) async {
    if (_cache.containsKey(patientId)) return _cache[patientId]!;
    final db = await DatabaseHelper.get();
    final rows = await db.query(
      'test_sessions',
      where: 'patient_id = ? AND user_id = ?',
      whereArgs: [patientId, _userId],
      orderBy: 'date DESC',
    );
    _cache[patientId] = rows.map(TestSession.fromMap).toList();
    return _cache[patientId]!;
  }

  /// Counts this user's sessions since a time, and their patients. Only
  /// sessions of patients still on file count. Arguments: user id, since,
  /// user id.
  @visibleForTesting
  static const weekSummarySql =
      'SELECT COUNT(*) AS sessions, COUNT(DISTINCT patient_id) AS patients '
      'FROM test_sessions WHERE user_id = ? AND created_at >= ? '
      'AND patient_id IN (SELECT id FROM patients WHERE user_id = ?)';

  /// How many sessions this user saved since [since], and for how many
  /// different patients. `created_at` is stored as a local ISO-8601 string,
  /// so comparing it with [since] as a string orders by time.
  Future<({int sessions, int patients})> weekSummary(DateTime since) async {
    if (_userId == null) return (sessions: 0, patients: 0);
    final db = await DatabaseHelper.get();
    final rows = await db.rawQuery(weekSummarySql, [
      _userId,
      since.toIso8601String(),
      _userId,
    ]);
    final row = rows.isEmpty ? const <String, Object?>{} : rows.first;
    return (
      sessions: (row['sessions'] as num?)?.toInt() ?? 0,
      patients: (row['patients'] as num?)?.toInt() ?? 0,
    );
  }

  Future<TestSession> save({
    required String patientId,
    required DateTime date,
    String? visitNote,
    required Map<String, dynamic> data,
  }) async {
    if (_userId == null) throw StateError('No user logged in.');
    final session = TestSession(
      id: const Uuid().v4(),
      patientId: patientId,
      userId: _userId!,
      date: date,
      visitNote: visitNote?.trim().isEmpty == true ? null : visitNote?.trim(),
      data: data,
      createdAt: DateTime.now(),
    );
    final db = await DatabaseHelper.get();
    await db.insert('test_sessions', session.toMap());
    _cache.remove(patientId); // invalidate cache
    notifyListeners();
    return session;
  }

  Future<void> delete(TestSession session) async {
    final db = await DatabaseHelper.get();
    await db.delete('test_sessions', where: 'id = ?', whereArgs: [session.id]);
    _cache.remove(session.patientId);
    notifyListeners();
  }
}
