class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.dateOfBirth = '',
    this.gender = '',
    this.phone = '',
    this.avatar = '',
    this.provider = 'email',
    this.profileComplete = false,
    this.isCommunityMember = false,
    this.communities = const [],
    this.communityIds = const [],
    this.communityNames = const [],
    this.pagesOwnedCount = 0,
    this.hasPlacedAd = false,
    this.adCount = 0,
    this.communityPostCount = 0,
    this.jobCount = 0,
    this.commentCount = 0,
    this.isDummy = false,
  });

  final String id;
  final String name;
  final String email;
  final String dateOfBirth;
  final String gender;
  final String phone;
  final String avatar;
  final String provider;
  final bool isCommunityMember;
  final List<UserCommunityRef> communities;
  final List<String> communityIds;
  final List<String> communityNames;
  final int pagesOwnedCount;
  final bool hasPlacedAd;
  final int adCount;
  final int communityPostCount;
  final int jobCount;
  final int commentCount;
  final bool isDummy;
  final bool profileComplete;

  bool get isGoogle => provider == 'google';

  String get genderLabel {
    if (gender.isEmpty) return 'Add gender';
    return gender[0].toUpperCase() + gender.substring(1);
  }

  String get dateOfBirthLabel =>
      dateOfBirth.isEmpty ? 'Add date of birth' : dateOfBirth;

  String get phoneLabel =>
      phone.isEmpty ? 'Add mobile number' : phone;

  bool get needsDetails =>
      phone.trim().isEmpty || gender.trim().isEmpty || dateOfBirth.trim().isEmpty;

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
    final communitiesRaw = json['communities'];
    final communities = communitiesRaw is List
        ? communitiesRaw
            .whereType<Map>()
            .map((item) => UserCommunityRef.fromJson(Map<String, dynamic>.from(item)))
            .toList()
        : const <UserCommunityRef>[];
    final ids = (json['communityIds'] as List? ?? [])
        .map((item) => item.toString())
        .where((item) => item.isNotEmpty)
        .toList();
    final names = (json['communityNames'] as List? ?? [])
        .map((item) => item.toString())
        .where((item) => item.isNotEmpty)
        .toList();
    return AppUser(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      dateOfBirth: json['dateOfBirth'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      avatar: json['avatar'] as String? ?? '',
      profileComplete: json['profileComplete'] == true,
      provider: json['provider'] as String? ?? 'email',
      isCommunityMember: json['isCommunityMember'] == true,
      communities: communities,
      communityIds: ids,
      communityNames: names,
      pagesOwnedCount: (json['pagesOwnedCount'] as num?)?.toInt() ?? 0,
      hasPlacedAd: json['hasPlacedAd'] == true,
      adCount: (json['adCount'] as num?)?.toInt() ?? 0,
      communityPostCount: (json['communityPostCount'] as num?)?.toInt() ?? 0,
      jobCount: (json['jobCount'] as num?)?.toInt() ?? 0,
      commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
      isDummy: json['isDummy'] == true,
    );
  }
}

class UserCommunityRef {
  const UserCommunityRef({required this.id, required this.name});

  final String id;
  final String name;

  factory UserCommunityRef.fromJson(Map<String, dynamic> json) {
    return UserCommunityRef(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
    );
  }
}
