class HealthHotline {
  const HealthHotline({
    required this.id,
    required this.label,
    required this.number,
    this.detail = '',
  });

  final String id;
  final String label;
  final String number;
  final String detail;

  factory HealthHotline.fromJson(Map<String, dynamic> json) {
    return HealthHotline(
      id: json['id'] as String? ?? json['number'] as String? ?? '',
      label: json['label'] as String? ?? '',
      number: json['number'] as String? ?? '',
      detail: json['detail'] as String? ?? '',
    );
  }
}

class HealthStep {
  const HealthStep({
    required this.id,
    required this.title,
    this.detail = '',
  });

  final String id;
  final String title;
  final String detail;

  factory HealthStep.fromJson(Map<String, dynamic> json) {
    return HealthStep(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      detail: json['detail'] as String? ?? '',
    );
  }
}

class HealthKind {
  const HealthKind({
    required this.id,
    required this.title,
    required this.icon,
  });

  final String id;
  final String title;
  final String icon;
}

const healthKinds = <HealthKind>[
  HealthKind(id: 'nearby', title: 'Nearby', icon: '📍'),
  HealthKind(id: 'hospital', title: 'Hospitals', icon: '🏥'),
  HealthKind(id: 'clinic', title: 'Clinics', icon: '🩺'),
  HealthKind(id: 'health_centre', title: 'Health centres', icon: '🏨'),
  HealthKind(id: 'doctors', title: 'Doctors', icon: '👨‍⚕️'),
  HealthKind(id: 'pharmacy', title: 'Pharmacy', icon: '💊'),
];

class HealthFacility {
  const HealthFacility({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.kind,
    this.city = '',
    this.phone = '',
    this.hours = '',
    this.web = '',
    this.amenity = 'clinic',
    this.emergency = false,
    this.services = const [],
    this.km = 0,
  });

  final String id;
  final String name;
  final double lat;
  final double lng;
  final String kind;
  final String city;
  final String phone;
  final String hours;
  final String web;
  final String amenity;
  final bool emergency;
  final List<String> services;
  final double km;

  HealthFacility withDistance(double value) => HealthFacility(
        id: id,
        name: name,
        lat: lat,
        lng: lng,
        kind: kind,
        city: city,
        phone: phone,
        hours: hours,
        web: web,
        amenity: amenity,
        emergency: emergency,
        services: services,
        km: value,
      );

  factory HealthFacility.fromJson(Map<String, dynamic> json) {
    return HealthFacility(
      id: json['id'] as String,
      name: json['name'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      kind: json['kind'] as String? ?? 'clinic',
      city: json['city'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      hours: json['hours'] as String? ?? '',
      web: json['web'] as String? ?? '',
      amenity: json['amenity'] as String? ?? 'clinic',
      emergency: json['emergency'] == true,
      services: [
        for (final item in json['services'] as List<dynamic>? ?? const [])
          item.toString(),
      ],
      km: (json['km'] as num?)?.toDouble() ?? 0,
    );
  }
}

String healthKindTitle(String kind) {
  for (final item in healthKinds) {
    if (item.id == kind) return item.title;
  }
  return kind.replaceAll('_', ' ');
}
