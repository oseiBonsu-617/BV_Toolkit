import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/patient.dart';
import 'database_helper.dart';

class PatientService extends ChangeNotifier {
  String? _userId;
  List<Patient> _patients = [];
  String _query = '';

  List<Patient> get patients {
    if (_query.isEmpty) return List.unmodifiable(_patients);
    final q = _query.toLowerCase();
    return _patients.where((p) =>
      p.fullName.toLowerCase().contains(q) ||
      (p.mrn?.toLowerCase().contains(q) ?? false),
    ).toList();
  }

  bool get hasPatients => _patients.isNotEmpty;

  void search(String query) {
    _query = query;
    notifyListeners();
  }

  Future<void> setUserId(String? userId) async {
    if (_userId == userId) return;
    _userId = userId;
    _patients = [];
    _query = '';
    if (userId != null) await _load();
    notifyListeners();
  }

  Future<void> _load() async {
    if (_userId == null) return;
    final db = await DatabaseHelper.get();
    final rows = await db.query(
      'patients',
      where: 'user_id = ?',
      whereArgs: [_userId],
      orderBy: 'last_name ASC, first_name ASC',
    );
    _patients = rows.map(Patient.fromMap).toList();
  }

  Future<Patient> add({
    required String firstName,
    required String lastName,
    DateTime? dateOfBirth,
    String? gender,
    String? mrn,
    String? phone,
    String? email,
    String? chiefComplaint,
    String? notes,
  }) async {
    if (_userId == null) throw StateError('No user logged in.');
    final now = DateTime.now();
    final patient = Patient(
      id: const Uuid().v4(),
      userId: _userId!,
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      dateOfBirth: dateOfBirth,
      gender: gender,
      mrn: _clean(mrn),
      phone: _clean(phone),
      email: _clean(email),
      chiefComplaint: _clean(chiefComplaint),
      notes: _clean(notes),
      createdAt: now,
      updatedAt: now,
    );
    final db = await DatabaseHelper.get();
    await db.insert('patients', patient.toMap());
    _patients.add(patient);
    _sort();
    notifyListeners();
    return patient;
  }

  Future<void> update(Patient updated) async {
    final db = await DatabaseHelper.get();
    final p = updated.copyWith();
    await db.update('patients', p.toMap(), where: 'id = ?', whereArgs: [p.id]);
    final idx = _patients.indexWhere((x) => x.id == p.id);
    if (idx >= 0) { _patients[idx] = p; _sort(); }
    notifyListeners();
  }

  Future<void> delete(String id) async {
    final db = await DatabaseHelper.get();
    await db.delete('patients', where: 'id = ?', whereArgs: [id]);
    _patients.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  Patient? getById(String id) {
    try { return _patients.firstWhere((p) => p.id == id); }
    catch (_) { return null; }
  }

  void _sort() => _patients.sort((a, b) {
    final c = a.lastName.compareTo(b.lastName);
    return c != 0 ? c : a.firstName.compareTo(b.firstName);
  });

  String? _clean(String? s) => s?.trim().isEmpty == true ? null : s?.trim();
}
