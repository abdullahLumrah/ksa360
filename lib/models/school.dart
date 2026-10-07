class SchoolFeeGrade {
  const SchoolFeeGrade({required this.grade, this.annualFeeSar});

  final String grade;
  final double? annualFeeSar;

  factory SchoolFeeGrade.fromJson(Map<String, dynamic> json) {
    return SchoolFeeGrade(
      grade: '${json['grade'] ?? ''}',
      annualFeeSar: (json['annual_fee_sar'] as num?)?.toDouble(),
    );
  }
}

class SchoolOneTimeFee {
  const SchoolOneTimeFee({required this.name, this.amountSar, this.note = ''});

  final String name;
  final double? amountSar;
  final String note;

  factory SchoolOneTimeFee.fromJson(Map<String, dynamic> json) {
    return SchoolOneTimeFee(
      name: '${json['name'] ?? ''}',
      amountSar: (json['amount_sar'] as num?)?.toDouble(),
      note: '${json['note'] ?? ''}',
    );
  }
}

class SchoolFees {
  const SchoolFees({
    this.currency = 'SAR',
    this.academicYear = '',
    this.vatNote = '',
    this.byGrade = const [],
    this.oneTimeFees = const [],
    this.discounts = const [],
    this.notes = '',
    this.sourceType = '',
    this.sourceName = '',
    this.sourceUrl = '',
    this.isRangeOnly = false,
    this.minAnnualSar,
    this.maxAnnualSar,
    this.published = false,
    this.needsVerification = false,
  });

  final String currency;
  final String academicYear;
  final String vatNote;
  final List<SchoolFeeGrade> byGrade;
  final List<SchoolOneTimeFee> oneTimeFees;
  final List<String> discounts;
  final String notes;
  final String sourceType;
  final String sourceName;
  final String sourceUrl;
  final bool isRangeOnly;
  final double? minAnnualSar;
  final double? maxAnnualSar;
  final bool published;
  final bool needsVerification;

  bool get fromSchoolWebsite => sourceType == 'official_website';

  factory SchoolFees.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SchoolFees();
    final source = json['source'] as Map<String, dynamic>? ?? const {};
    return SchoolFees(
      currency: '${json['currency'] ?? 'SAR'}',
      academicYear: '${json['academicYear'] ?? json['academic_year'] ?? ''}',
      vatNote: '${json['vatNote'] ?? json['vat_note'] ?? ''}',
      byGrade: [
        for (final item in json['byGrade'] as List<dynamic>? ??
            json['by_grade'] as List<dynamic>? ??
            const [])
          if (item is Map<String, dynamic>) SchoolFeeGrade.fromJson(item),
      ],
      oneTimeFees: [
        for (final item in json['oneTimeFees'] as List<dynamic>? ??
            json['one_time_fees'] as List<dynamic>? ??
            const [])
          if (item is Map<String, dynamic>) SchoolOneTimeFee.fromJson(item),
      ],
      discounts: [
        for (final item in json['discounts'] as List<dynamic>? ?? const [])
          '$item',
      ],
      notes: '${json['notes'] ?? ''}',
      sourceType: '${source['type'] ?? json['feeSourceType'] ?? ''}',
      sourceName: '${source['name'] ?? json['feeSourceName'] ?? ''}',
      sourceUrl: '${source['url'] ?? json['feeSourceUrl'] ?? ''}',
      isRangeOnly: json['isRangeOnly'] == true || json['is_range_only'] == true,
      minAnnualSar: (json['minAnnualSar'] as num?)?.toDouble() ??
          (json['min_annual_sar'] as num?)?.toDouble(),
      maxAnnualSar: (json['maxAnnualSar'] as num?)?.toDouble() ??
          (json['max_annual_sar'] as num?)?.toDouble(),
      published: json['published'] == true,
      needsVerification: json['needsVerification'] == true ||
          json['needs_verification'] == true,
    );
  }
}

class SchoolAdmission {
  const SchoolAdmission({
    this.steps = const [],
    this.documentsRequired = const [],
    this.schoolSpecific = false,
    this.notes = '',
    this.source = '',
  });

  final List<String> steps;
  final List<String> documentsRequired;
  final bool schoolSpecific;
  final String notes;
  final String source;

  factory SchoolAdmission.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SchoolAdmission();
    return SchoolAdmission(
      steps: [
        for (final item in json['steps'] as List<dynamic>? ?? const []) '$item',
      ],
      documentsRequired: [
        for (final item in json['documentsRequired'] as List<dynamic>? ??
            json['documents_required'] as List<dynamic>? ??
            const [])
          '$item',
      ],
      schoolSpecific: json['schoolSpecific'] == true ||
          json['school_specific'] == true,
      notes: '${json['notes'] ?? ''}',
      source: '${json['source'] ?? ''}',
    );
  }
}

class School {
  const School({
    required this.id,
    required this.name,
    this.city = '',
    this.district = '',
    this.address = '',
    this.lat = 0,
    this.lng = 0,
    this.precision = '',
    this.gender = '',
    this.genderDetail = '',
    this.grades = '',
    this.ageRange = '',
    this.established,
    this.phone = '',
    this.email = '',
    this.website = '',
    this.image = '',
    this.googlePlaceId = '',
    this.curriculum = const [],
    this.curriculumTags = const [],
    this.stages = const [],
    this.accreditations = const [],
    this.minAnnualSar,
    this.maxAnnualSar,
    this.feeYear = '',
    this.feeSourceType = '',
    this.feeSourceName = '',
    this.feeSourceUrl = '',
    this.feesPublished = false,
    this.vatNote = '',
    this.km = 0,
    this.fees = const SchoolFees(),
    this.admission = const SchoolAdmission(),
    this.sources = const [],
    this.disclaimer = '',
  });

  final String id;
  final String name;
  final String city;
  final String district;
  final String address;
  final double lat;
  final double lng;
  final String precision;
  final String gender;
  final String genderDetail;
  final String grades;
  final String ageRange;
  final int? established;
  final String phone;
  final String email;
  final String website;
  final String image;
  final String googlePlaceId;
  final List<String> curriculum;
  final List<String> curriculumTags;
  final List<String> stages;
  final List<String> accreditations;
  final double? minAnnualSar;
  final double? maxAnnualSar;
  final String feeYear;
  final String feeSourceType;
  final String feeSourceName;
  final String feeSourceUrl;
  final bool feesPublished;
  final String vatNote;
  final double km;
  final SchoolFees fees;
  final SchoolAdmission admission;
  final List<Map<String, dynamic>> sources;
  final String disclaimer;

  bool get hasPin => lat != 0 && lng != 0;

  School copyWith({
    String? image,
    String? googlePlaceId,
    double? km,
    SchoolFees? fees,
    SchoolAdmission? admission,
    List<Map<String, dynamic>>? sources,
    String? disclaimer,
  }) {
    return School(
      id: id,
      name: name,
      city: city,
      district: district,
      address: address,
      lat: lat,
      lng: lng,
      precision: precision,
      gender: gender,
      genderDetail: genderDetail,
      grades: grades,
      ageRange: ageRange,
      established: established,
      phone: phone,
      email: email,
      website: website,
      image: image ?? this.image,
      googlePlaceId: googlePlaceId ?? this.googlePlaceId,
      curriculum: curriculum,
      curriculumTags: curriculumTags,
      stages: stages,
      accreditations: accreditations,
      minAnnualSar: minAnnualSar,
      maxAnnualSar: maxAnnualSar,
      feeYear: feeYear,
      feeSourceType: feeSourceType,
      feeSourceName: feeSourceName,
      feeSourceUrl: feeSourceUrl,
      feesPublished: feesPublished,
      vatNote: vatNote,
      km: km ?? this.km,
      fees: fees ?? this.fees,
      admission: admission ?? this.admission,
      sources: sources ?? this.sources,
      disclaimer: disclaimer ?? this.disclaimer,
    );
  }

  School withDistance(double value) => copyWith(km: value);

  factory School.fromJson(Map<String, dynamic> json) {
    return School(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? ''}',
      city: '${json['city'] ?? ''}',
      district: '${json['district'] ?? ''}',
      address: '${json['address'] ?? ''}',
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0,
      precision: '${json['precision'] ?? ''}',
      gender: '${json['gender'] ?? ''}',
      genderDetail: '${json['genderDetail'] ?? json['gender_detail'] ?? ''}',
      grades: '${json['grades'] ?? ''}',
      ageRange: '${json['ageRange'] ?? json['age_range'] ?? ''}',
      established: (json['established'] as num?)?.toInt(),
      phone: '${json['phone'] ?? ''}',
      email: '${json['email'] ?? ''}',
      website: '${json['website'] ?? ''}',
      image: '${json['image'] ?? ''}',
      googlePlaceId: '${json['googlePlaceId'] ?? json['google_place_id'] ?? ''}',
      curriculum: [
        for (final item in json['curriculum'] as List<dynamic>? ?? const [])
          '$item',
      ],
      curriculumTags: [
        for (final item in json['curriculumTags'] as List<dynamic>? ??
            json['curriculum_tags'] as List<dynamic>? ??
            const [])
          '$item',
      ],
      stages: [
        for (final item in json['stages'] as List<dynamic>? ?? const []) '$item',
      ],
      accreditations: [
        for (final item in json['accreditations'] as List<dynamic>? ?? const [])
          '$item',
      ],
      minAnnualSar: (json['minAnnualSar'] as num?)?.toDouble(),
      maxAnnualSar: (json['maxAnnualSar'] as num?)?.toDouble(),
      feeYear: '${json['feeYear'] ?? ''}',
      feeSourceType: '${json['feeSourceType'] ?? ''}',
      feeSourceName: '${json['feeSourceName'] ?? ''}',
      feeSourceUrl: '${json['feeSourceUrl'] ?? ''}',
      feesPublished: json['feesPublished'] == true,
      vatNote: '${json['vatNote'] ?? ''}',
      km: (json['km'] as num?)?.toDouble() ?? 0,
      fees: SchoolFees.fromJson(json['fees'] as Map<String, dynamic>?),
      admission:
          SchoolAdmission.fromJson(json['admission'] as Map<String, dynamic>?),
      sources: [
        for (final item in json['sources'] as List<dynamic>? ?? const [])
          if (item is Map)
            Map<String, dynamic>.from(item),
      ],
      disclaimer: '${json['disclaimer'] ?? ''}',
    );
  }
}

class SchoolFilter {
  const SchoolFilter({required this.id, required this.count});
  final String id;
  final int count;
}

String formatSar(num? value) {
  if (value == null) return '';
  final digits = value.round().abs().toString();
  final buf = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    final fromEnd = digits.length - i;
    if (i > 0 && fromEnd % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return 'SAR $buf';
}

String schoolFeeLabel(School school) {
  if (!school.feesPublished ||
      (school.minAnnualSar == null && school.maxAnnualSar == null)) {
    return 'Fees on request';
  }
  final min = school.minAnnualSar;
  final max = school.maxAnnualSar;
  if (min != null && max != null && min != max) {
    return '${formatSar(min)}–${formatSar(max).replaceFirst('SAR ', '')} / yr';
  }
  return '${formatSar(min ?? max)} / yr';
}

String schoolGenderLabel(School school) {
  final gender = school.gender.toLowerCase().trim();
  final detail = school.genderDetail.trim();
  if (_schoolHasMixedStages(detail)) return detail;
  switch (gender) {
    case 'boys':
    case 'male':
      return 'Boys';
    case 'girls':
    case 'female':
      return 'Girls';
    case 'separate-sections':
      return 'Separate sections';
    default:
      return '';
  }
}

bool _schoolHasMixedStages(String detail) {
  final text = detail.toLowerCase();
  if (text.isEmpty) return false;
  final mixed = text.contains('co-ed') ||
      text.contains('coed') ||
      text.contains('co-educational');
  final split = text.contains('segregat') ||
      text.contains('separate') ||
      text.contains('single-gender') ||
      text.contains('single gender') ||
      text.contains('girls-only') ||
      text.contains('girls only') ||
      text.contains('boys-only') ||
      text.contains('boys only') ||
      text.contains('from grade') ||
      text.contains('from age');
  return mixed && split;
}

String schoolCurriculumLabel(String raw) {
  if (raw.isEmpty) return raw;
  if (raw.toLowerCase() == 'ib') return 'IB';
  if (raw.toLowerCase() == 'sabis') return 'SABIS';
  return raw[0].toUpperCase() + raw.substring(1).replaceAll('_', ' ');
}
