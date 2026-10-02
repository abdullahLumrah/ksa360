import 'dart:math' as math;

class KsaActivity {
  const KsaActivity({
    required this.id,
    required this.name,
    required this.kind,
    required this.city,
    required this.lat,
    required this.lng,
    required this.priceFrom,
    required this.priceTo,
    required this.unit,
    required this.image,
    required this.about,
    this.hours = 'Check the venue for today’s hours',
    this.phone = '',
    this.web = '',
    this.area = '',
    this.also = const [],
    this.featured = false,
    this.family = true,
    this.indoor = true,
    this.video = '',
    this.km = 0,
  });

  final String id;
  final String name;
  final String kind;
  final String city;
  final double lat;
  final double lng;
  final int priceFrom;
  final int priceTo;
  final String unit;
  final String image;
  final String about;
  final String hours;
  final String phone;
  final String web;
  final String area;
  final List<String> also;
  final bool featured;
  final bool family;
  final bool indoor;
  final String video;
  final double km;

  String get priceLabel {
    if (priceFrom == priceTo) return '$priceFrom SAR / $unit';
    return '$priceFrom–$priceTo SAR / $unit';
  }

  String get fromLabel => 'from $priceFrom SAR';

  KsaActivity withDistance(double value) => KsaActivity(
        id: id,
        name: name,
        kind: kind,
        city: city,
        lat: lat,
        lng: lng,
        priceFrom: priceFrom,
        priceTo: priceTo,
        unit: unit,
        image: image,
        about: about,
        hours: hours,
        phone: phone,
        web: web,
        area: area,
        also: also,
        featured: featured,
        family: family,
        indoor: indoor,
        video: video,
        km: value,
      );

  factory KsaActivity.fromJson(Map<String, dynamic> json) {
    return KsaActivity(
      id: json['id'] as String,
      name: json['name'] as String,
      kind: json['kind'] as String,
      city: json['city'] as String? ?? '',
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      priceFrom: (json['priceFrom'] as num?)?.toInt() ?? 0,
      priceTo: (json['priceTo'] as num?)?.toInt() ?? 0,
      unit: json['unit'] as String? ?? 'ticket',
      image: json['image'] as String? ?? '',
      about: json['about'] as String? ?? '',
      hours: json['hours'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      web: json['web'] as String? ?? '',
      area: json['area'] as String? ?? '',
      also: [
        for (final item in json['also'] as List<dynamic>? ?? const [])
          item.toString(),
      ],
      featured: json['featured'] as bool? ?? false,
      family: json['family'] as bool? ?? true,
      indoor: json['indoor'] as bool? ?? true,
      video: json['video'] as String? ?? '',
      km: (json['km'] as num?)?.toDouble() ?? 0,
    );
  }

  static double kmBetween(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const r = 6371.0;
    final p = math.pi / 180;
    final a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) *
            math.cos(lat2 * p) *
            (1 - math.cos((lng2 - lng1) * p)) /
            2;
    return 2 * r * math.asin(math.sqrt(a));
  }
}

class ActivityKind {
  const ActivityKind(this.id, this.title, this.icon, this.color);

  final String id;
  final String title;
  final String icon;
  final int color;
}

const activityKinds = <ActivityKind>[
  ActivityKind('cinema', 'Movies', '🎬', 0xFF9A5568),
  ActivityKind('bowl', 'Bowling', '🎳', 0xFF6E5688),
  ActivityKind('mall', 'Malls', '🛍️', 0xFF8A5E2E),
  ActivityKind('speed', 'Karting', '🏎️', 0xFFB33A2B),
  ActivityKind('desert', 'Dunes', '🏜️', 0xFF9A6234),
  ActivityKind('snow', 'Snow', '🎿', 0xFF3D6A94),
  ActivityKind('theme', 'Theme parks', '🎢', 0xFF1E7A4C),
  ActivityKind('water', 'Water', '🌊', 0xFF2A6F99),
  ActivityKind('kids', 'Kids', '🧒', 0xFF8A5E2E),
  ActivityKind('arcade', 'Arcades', '🕹️', 0xFF8A5E2E),
  ActivityKind('trampoline', 'Trampoline', '🤸', 0xFF2C7A68),
  ActivityKind('ice', 'Ice skating', '⛸️', 0xFF3D6A94),
  ActivityKind('vr', 'VR', '🥽', 0xFF3D6A94),
  ActivityKind('escape', 'Escape rooms', '🔐', 0xFF9A6234),
  ActivityKind('combat', 'Paintball', '🎯', 0xFFB33A2B),
  ActivityKind('sport', 'Sports', '🏓', 0xFF1E7A4C),
  ActivityKind('outdoor', 'Outdoors', '⛰️', 0xFF2C7A68),
  ActivityKind('night', 'Night out', '🌙', 0xFF6E4B24),
];

ActivityKind kindMeta(String id) {
  return activityKinds.firstWhere(
    (item) => item.id == id,
    orElse: () => activityKinds.first,
  );
}
