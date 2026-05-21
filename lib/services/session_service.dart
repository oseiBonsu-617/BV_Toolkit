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
