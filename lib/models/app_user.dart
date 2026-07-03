class AppUser {
  final String id;
  final String email;
  final String displayName;
  final String? title;
  final String? clinic;

  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.title,
    this.clinic,
  });

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] as String,
        email: j['email'] as String,
        displayName: j['displayName'] as String,
        title: j['title'] as String?,
        clinic: j['clinic'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'title': title,
        'clinic': clinic,
      };

  AppUser copyWith({String? displayName, String? title, String? clinic}) =>
      AppUser(
        id: id,
        email: email,
        displayName: displayName ?? this.displayName,
        title: title ?? this.title,
        clinic: clinic ?? this.clinic,
      );

  String get initials {
    final parts = displayName
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  String get credential {
    if (title != null && title!.isNotEmpty) return '$displayName, $title';
    return displayName;
  }
}
