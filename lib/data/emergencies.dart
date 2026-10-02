import 'embassy_directory.dart';

class EmergencyNumber {
  const EmergencyNumber({
    required this.label,
    required this.number,
    required this.detail,
  });

  final String label;
  final String number;
  final String detail;
}

class Hospital {
  const Hospital({
    required this.name,
    required this.cityId,
    required this.phone,
  });

  final String name;
  final String cityId;
  final String phone;
}

class Embassy {
  const Embassy({
    required this.nationalityId,
    required this.country,
    required this.city,
    required this.phone,
    this.flag = '',
    this.altPhone,
    this.note,
  });

  final String nationalityId;
  final String country;
  final String city;
  final String phone;

  /// ISO 3166 alpha-2 code, shown as an emoji flag.
  final String flag;
  final String? altPhone;
  final String? note;

  String get kind => note ?? 'Embassy';

  String get flagEmoji {
    if (flag.length != 2) return '🏳️';
    return String.fromCharCodes(
      flag.toUpperCase().codeUnits.map((c) => 0x1F1E6 + c - 0x41),
    );
  }
}

class Nationality {
  const Nationality({required this.id, required this.name});
  final String id;
  final String name;
}

class EmergencyData {
  static const hotlines = <EmergencyNumber>[
    EmergencyNumber(
      label: '911',
      number: '911',
      detail: 'Police, ambulance, fire — all of Saudi Arabia',
    ),
    EmergencyNumber(
      label: 'Ambulance',
      number: '997',
      detail: 'Red Crescent',
    ),
    EmergencyNumber(
      label: 'Civil Defense',
      number: '998',
      detail: 'Fire and rescue',
    ),
    EmergencyNumber(
      label: 'Police',
      number: '999',
      detail: 'Direct police line',
    ),
    EmergencyNumber(
      label: 'Traffic',
      number: '993',
      detail: 'Accidents and Saher',
    ),
    EmergencyNumber(
      label: 'Electricity',
      number: '933',
      detail: 'Power outage',
    ),
  ];

  static final nationalities = () {
    final seen = <String>{};
    return [
      for (final e in embassyDirectory)
        if (seen.add(e.nationalityId))
          Nationality(id: e.nationalityId, name: e.country),
    ];
  }();

  static const hospitals = <Hospital>[
    Hospital(name: 'King Fahd Medical City', cityId: 'riyadh', phone: '920022265'),
    Hospital(name: 'King Khalid University Hospital', cityId: 'riyadh', phone: '0114670011'),
    Hospital(name: 'King Faisal Specialist Hospital', cityId: 'riyadh', phone: '0114647272'),
    Hospital(name: 'King Abdulaziz Medical City (NGHA)', cityId: 'riyadh', phone: '0118011111'),
    Hospital(name: 'King Fahd Hospital', cityId: 'jeddah', phone: '0126655000'),
    Hospital(name: 'King Abdulaziz Hospital', cityId: 'jeddah', phone: '0126375555'),
    Hospital(name: 'King Faisal Specialist Hospital', cityId: 'jeddah', phone: '0126677777'),
    Hospital(name: 'East Jeddah Hospital', cityId: 'jeddah', phone: '0126129999'),
    Hospital(name: 'King Abdullah Medical City', cityId: 'makkah', phone: '0125549999'),
    Hospital(name: 'King Abdulaziz Hospital', cityId: 'makkah', phone: '0125440000'),
    Hospital(name: 'Ohud Hospital', cityId: 'madinah', phone: '0148420000'),
    Hospital(name: 'King Fahd Hospital', cityId: 'madinah', phone: '0148460000'),
    Hospital(name: 'King Fahd University Hospital', cityId: 'khobar', phone: '0138966666'),
    Hospital(name: 'Almana General Hospital', cityId: 'khobar', phone: '0138200000'),
    Hospital(name: 'King Fahd Specialist Hospital', cityId: 'dammam', phone: '0138431111'),
    Hospital(name: 'Dammam Medical Complex', cityId: 'dammam', phone: '0138311111'),
    Hospital(name: 'Royal Commission Hospital', cityId: 'jubail', phone: '0133400000'),
    Hospital(name: 'King Fahd Hospital Al Ahsa', cityId: 'hofuf', phone: '0135750000'),
    Hospital(name: 'King Fahd Specialist Hospital', cityId: 'buraidah', phone: '0163252000'),
    Hospital(name: 'Buraidah Central Hospital', cityId: 'buraidah', phone: '0163240000'),
    Hospital(name: 'Asir Central Hospital', cityId: 'abha', phone: '0172250000'),
    Hospital(name: 'Armed Forces Hospital', cityId: 'khamis', phone: '0172500000'),
    Hospital(name: 'King Fahd Central Hospital', cityId: 'jazan', phone: '0173210000'),
    Hospital(name: 'King Khalid Hospital', cityId: 'najran', phone: '0175220000'),
    Hospital(name: 'King Fahd Hospital', cityId: 'tabuk', phone: '0144210000'),
    Hospital(name: 'King Khalid Hospital', cityId: 'hail', phone: '0165310000'),
    Hospital(name: 'Prince Mutaib Hospital', cityId: 'sakaka', phone: '0146240000'),
    Hospital(name: 'Arar Central Hospital', cityId: 'arar', phone: '0146610000'),
    Hospital(name: 'King Abdulaziz Specialist Hospital', cityId: 'taif', phone: '0127310000'),
    Hospital(name: 'King Fahd Hospital', cityId: 'hafr', phone: '0137220000'),
    Hospital(name: 'Yanbu General Hospital', cityId: 'yanbu', phone: '0143210000'),
    Hospital(name: 'Al Baha Hospital', cityId: 'baha', phone: '0177250000'),
  ];

  static const embassies = embassyDirectory;

  static List<Hospital> hospitalsNear(String cityId) {
    final exact = hospitals.where((h) => h.cityId == cityId).toList();
    if (exact.isNotEmpty) return exact;
    const fallbacks = {
      'diriyah': 'riyadh',
      'kharj': 'riyadh',
      'majmaah': 'riyadh',
      'zulfi': 'riyadh',
      'dawadmi': 'riyadh',
      'unaizah': 'buraidah',
      'rass': 'buraidah',
      'dhahran': 'khobar',
      'qatif': 'dammam',
      'mubarraz': 'hofuf',
      'khamis': 'abha',
      'bisha': 'abha',
      'sabya': 'jazan',
      'duba': 'tabuk',
      'qurayyat': 'sakaka',
      'rafha': 'arar',
    };
    final mapped = fallbacks[cityId];
    if (mapped != null) {
      return hospitals.where((h) => h.cityId == mapped).toList();
    }
    return hospitals.where((h) => h.cityId == 'riyadh').toList();
  }

  static List<Embassy> embassiesFor(String nationalityId) {
    return embassies.where((e) => e.nationalityId == nationalityId).toList();
  }
}
