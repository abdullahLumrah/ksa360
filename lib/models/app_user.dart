class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.dateOfBirth = '',
    this.gender = '',
    this.avatar = '',
    this.provider = 'email',
  });

  final String id;
  final String name;
  final String email;
  final String dateOfBirth;
  final String gender;
  final String avatar;
  final String provider;

  bool get isGoogle => provider == 'google';

  String get genderLabel {
    if (gender.isEmpty) return 'Add gender';
    return gender[0].toUpperCase() + gender.substring(1);
  }

  String get dateOfBirthLabel =>
      dateOfBirth.isEmpty ? 'Add date of birth' : dateOfBirth;

  bool get needsDetails => dateOfBirth.isEmpty || gender.isEmpty;

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'K';
    final first = parts.first.substring(0, 1);
    final last = parts.length > 1 ? parts.last.substring(0, 1) : '';
    return '$first$last'.toUpperCase();
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      dateOfBirth: json['dateOfBirth'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      avatar: json['avatar'] as String? ?? '',
      provider: json['provider'] as String? ?? 'email',
    );
  }
}
