import 'dart:convert';

class TestSession {
  final String id;
  final String patientId;
  final String userId;
  final DateTime date;
  final String? visitNote;
  final Map<String, dynamic> data;
  final DateTime createdAt;

  const TestSession({
    required this.id,
    required this.patientId,
    required this.userId,
    required this.date,
    this.visitNote,
    required this.data,
    required this.createdAt,
  });

  factory TestSession.fromMap(Map<String, dynamic> m) => TestSession(
        id: m['id'] as String,
        patientId: m['patient_id'] as String,
        userId: m['user_id'] as String,
        date: DateTime.parse(m['date'] as String),
        visitNote: m['visit_note'] as String?,
        data: Map<String, dynamic>.from(
            jsonDecode(m['data'] as String) as Map),
        createdAt: DateTime.parse(m['created_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'patient_id': patientId,
        'user_id': userId,
        'date': date.toIso8601String(),
        'visit_note': visitNote,
        'data': jsonEncode(data),
        'created_at': createdAt.toIso8601String(),
      };

  // True when any test inputs are present in this section of data.
  bool hasSection(String prefix) =>
      data.entries.any((e) => e.key.startsWith(prefix) && e.value != null);

  double? numVal(String key) {
    final v = data[key];
    if (v == null) return null;
    return (v as num).toDouble();
  }

  String? str(String key) => data[key] as String?;
}
