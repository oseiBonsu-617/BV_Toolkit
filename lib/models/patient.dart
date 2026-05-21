class Patient {
  final String id;
  final String userId;
  final String firstName;
  final String lastName;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? mrn;
  final String? phone;
  final String? email;
  final String? chiefComplaint;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Patient({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.dateOfBirth,
    this.gender,
    this.mrn,
    this.phone,
    this.email,
    this.chiefComplaint,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final l = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$f$l'.isNotEmpty ? '$f$l' : '?';
  }

  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  Patient copyWith({
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    bool clearDob = false,
    String? gender,
    String? mrn,
    String? phone,
    String? email,
    String? chiefComplaint,
    String? notes,
  }) =>
      Patient(
        id: id,
        userId: userId,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        dateOfBirth: clearDob ? null : (dateOfBirth ?? this.dateOfBirth),
        gender: gender ?? this.gender,
        mrn: mrn ?? this.mrn,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        chiefComplaint: chiefComplaint ?? this.chiefComplaint,
        notes: notes ?? this.notes,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );

  factory Patient.fromMap(Map<String, dynamic> m) => Patient(
        id: m['id'] as String,
        userId: m['user_id'] as String,
        firstName: m['first_name'] as String,
        lastName: m['last_name'] as String,
        dateOfBirth: m['dob'] != null ? DateTime.parse(m['dob'] as String) : null,
        gender: m['gender'] as String?,
        mrn: m['mrn'] as String?,
        phone: m['phone'] as String?,
        email: m['email'] as String?,
        chiefComplaint: m['chief_complaint'] as String?,
        notes: m['notes'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String),
        updatedAt: DateTime.parse(m['updated_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'first_name': firstName,
        'last_name': lastName,
        'dob': dateOfBirth?.toIso8601String(),
        'gender': gender,
        'mrn': mrn,
        'phone': phone,
        'email': email,
        'chief_complaint': chiefComplaint,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}
