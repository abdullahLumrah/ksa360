class SaudiCity {
  const SaudiCity({
    required this.id,
    required this.name,
    required this.region,
    required this.lat,
    required this.lng,
  });

  final String id;
  final String name;
  final String region;
  final double lat;
  final double lng;
}

class SaudiCities {
  static const riyadh = SaudiCity(
    id: 'riyadh',
    name: 'Riyadh',
    region: 'Riyadh',
    lat: 24.7136,
    lng: 46.6753,
  );

  static const all = <SaudiCity>[
    riyadh,
    SaudiCity(id: 'diriyah', name: 'Diriyah', region: 'Riyadh', lat: 24.7333, lng: 46.5728),
    SaudiCity(id: 'kharj', name: 'Al Kharj', region: 'Riyadh', lat: 24.1556, lng: 47.3120),
    SaudiCity(id: 'majmaah', name: 'Al Majmaah', region: 'Riyadh', lat: 25.9039, lng: 45.3456),
    SaudiCity(id: 'zulfi', name: 'Al Zulfi', region: 'Riyadh', lat: 26.2995, lng: 44.8151),
    SaudiCity(id: 'dawadmi', name: 'Dawadmi', region: 'Riyadh', lat: 24.5077, lng: 44.3924),
    SaudiCity(id: 'shaqra', name: 'Shaqra', region: 'Riyadh', lat: 25.2465, lng: 45.2506),
    SaudiCity(id: 'wadi-dawasir', name: 'Wadi ad-Dawasir', region: 'Riyadh', lat: 20.4671, lng: 44.7825),
    SaudiCity(id: 'aflaj', name: 'Al Aflaj', region: 'Riyadh', lat: 22.3065, lng: 46.7318),
    SaudiCity(id: 'jeddah', name: 'Jeddah', region: 'Makkah', lat: 21.5433, lng: 39.1728),
    SaudiCity(id: 'makkah', name: 'Makkah', region: 'Makkah', lat: 21.3891, lng: 39.8579),
    SaudiCity(id: 'taif', name: 'Taif', region: 'Makkah', lat: 21.2703, lng: 40.4158),
    SaudiCity(id: 'rabigh', name: 'Rabigh', region: 'Makkah', lat: 22.7986, lng: 39.0349),
    SaudiCity(id: 'lith', name: 'Al Lith', region: 'Makkah', lat: 20.2649, lng: 40.2720),
    SaudiCity(id: 'qunfudhah', name: 'Al Qunfudhah', region: 'Makkah', lat: 19.1264, lng: 41.0789),
    SaudiCity(id: 'khulais', name: 'Khulais', region: 'Makkah', lat: 22.1446, lng: 39.3371),
    SaudiCity(id: 'madinah', name: 'Madinah', region: 'Madinah', lat: 24.5247, lng: 39.5692),
    SaudiCity(id: 'yanbu', name: 'Yanbu', region: 'Madinah', lat: 24.0896, lng: 38.0618),
    SaudiCity(id: 'ula', name: 'Al Ula', region: 'Madinah', lat: 26.6083, lng: 37.9236),
    SaudiCity(id: 'badr', name: 'Badr', region: 'Madinah', lat: 23.7793, lng: 38.7905),
    SaudiCity(id: 'khaybar', name: 'Khaybar', region: 'Madinah', lat: 25.6989, lng: 39.2925),
    SaudiCity(id: 'dammam', name: 'Dammam', region: 'Eastern Province', lat: 26.4207, lng: 50.0888),
    SaudiCity(id: 'khobar', name: 'Khobar', region: 'Eastern Province', lat: 26.2172, lng: 50.1971),
    SaudiCity(id: 'dhahran', name: 'Dhahran', region: 'Eastern Province', lat: 26.2361, lng: 50.0650),
    SaudiCity(id: 'jubail', name: 'Jubail', region: 'Eastern Province', lat: 27.0046, lng: 49.6225),
    SaudiCity(id: 'qatif', name: 'Qatif', region: 'Eastern Province', lat: 26.5650, lng: 49.9960),
    SaudiCity(id: 'hofuf', name: 'Hofuf (Al Ahsa)', region: 'Eastern Province', lat: 25.3647, lng: 49.5856),
    SaudiCity(id: 'mubarraz', name: 'Mubarraz', region: 'Eastern Province', lat: 25.4077, lng: 49.5818),
    SaudiCity(id: 'hafr', name: 'Hafr Al-Batin', region: 'Eastern Province', lat: 28.4337, lng: 45.9601),
    SaudiCity(id: 'khafji', name: 'Khafji', region: 'Eastern Province', lat: 28.4391, lng: 48.4913),
    SaudiCity(id: 'ras-tanura', name: 'Ras Tanura', region: 'Eastern Province', lat: 26.6430, lng: 50.1590),
    SaudiCity(id: 'abqaiq', name: 'Abqaiq', region: 'Eastern Province', lat: 25.9339, lng: 49.6689),
    SaudiCity(id: 'nairyah', name: 'Nairyah', region: 'Eastern Province', lat: 27.4744, lng: 48.4846),
    SaudiCity(id: 'buraidah', name: 'Buraidah', region: 'Qassim', lat: 26.3260, lng: 43.9750),
    SaudiCity(id: 'unaizah', name: 'Unaizah', region: 'Qassim', lat: 26.0840, lng: 43.9930),
    SaudiCity(id: 'rass', name: 'Ar Rass', region: 'Qassim', lat: 25.8694, lng: 43.4973),
    SaudiCity(id: 'bukayriyah', name: 'Al Bukayriyah', region: 'Qassim', lat: 26.1412, lng: 43.6593),
    SaudiCity(id: 'abha', name: 'Abha', region: 'Asir', lat: 18.2164, lng: 42.5053),
    SaudiCity(id: 'khamis', name: 'Khamis Mushait', region: 'Asir', lat: 18.3064, lng: 42.7297),
    SaudiCity(id: 'bisha', name: 'Bisha', region: 'Asir', lat: 20.0005, lng: 42.6053),
    SaudiCity(id: 'muhayil', name: 'Muhayil', region: 'Asir', lat: 18.5444, lng: 42.0447),
    SaudiCity(id: 'ahad-rafidah', name: 'Ahad Rafidah', region: 'Asir', lat: 18.1886, lng: 42.8353),
    SaudiCity(id: 'jazan', name: 'Jazan', region: 'Jazan', lat: 16.8892, lng: 42.5511),
    SaudiCity(id: 'sabya', name: 'Sabya', region: 'Jazan', lat: 17.1495, lng: 42.6254),
    SaudiCity(id: 'abu-arish', name: 'Abu Arish', region: 'Jazan', lat: 16.9689, lng: 42.8325),
    SaudiCity(id: 'samtah', name: 'Samtah', region: 'Jazan', lat: 16.5972, lng: 42.9444),
    SaudiCity(id: 'najran', name: 'Najran', region: 'Najran', lat: 17.4924, lng: 44.1277),
    SaudiCity(id: 'sharurah', name: 'Sharurah', region: 'Najran', lat: 17.4809, lng: 47.1189),
    SaudiCity(id: 'baha', name: 'Al Baha', region: 'Al Baha', lat: 20.0129, lng: 41.4677),
    SaudiCity(id: 'baljurashi', name: 'Baljurashi', region: 'Al Baha', lat: 19.8595, lng: 41.5570),
    SaudiCity(id: 'tabuk', name: 'Tabuk', region: 'Tabuk', lat: 28.3838, lng: 36.5550),
    SaudiCity(id: 'duba', name: 'Duba', region: 'Tabuk', lat: 27.3493, lng: 35.6987),
    SaudiCity(id: 'wajh', name: 'Al Wajh', region: 'Tabuk', lat: 26.2455, lng: 36.4525),
    SaudiCity(id: 'umluj', name: 'Umluj', region: 'Tabuk', lat: 25.0432, lng: 37.2651),
    SaudiCity(id: 'haql', name: 'Haql', region: 'Tabuk', lat: 29.2987, lng: 34.9431),
    SaudiCity(id: 'tayma', name: 'Tayma', region: 'Tabuk', lat: 27.6299, lng: 38.5439),
    SaudiCity(id: 'hail', name: 'Hail', region: 'Hail', lat: 27.5114, lng: 41.7208),
    SaudiCity(id: 'sakaka', name: 'Sakaka', region: 'Al Jouf', lat: 29.9697, lng: 40.2064),
    SaudiCity(id: 'qurayyat', name: 'Qurayyat', region: 'Al Jouf', lat: 31.3315, lng: 37.3428),
    SaudiCity(id: 'dumat', name: 'Dumat Al-Jandal', region: 'Al Jouf', lat: 29.8114, lng: 39.8664),
    SaudiCity(id: 'tabarjal', name: 'Tabarjal', region: 'Al Jouf', lat: 30.5000, lng: 38.2167),
    SaudiCity(id: 'arar', name: 'Arar', region: 'Northern Borders', lat: 30.9753, lng: 41.0381),
    SaudiCity(id: 'rafha', name: 'Rafha', region: 'Northern Borders', lat: 29.6264, lng: 43.5026),
    SaudiCity(id: 'turaif', name: 'Turaif', region: 'Northern Borders', lat: 31.6726, lng: 38.6637),
  ];

  static const regions = [
    'Riyadh',
    'Makkah',
    'Madinah',
    'Eastern Province',
    'Qassim',
    'Asir',
    'Jazan',
    'Najran',
    'Al Baha',
    'Tabuk',
    'Hail',
    'Al Jouf',
    'Northern Borders',
  ];

  static SaudiCity byId(String id) {
    return all.firstWhere((c) => c.id == id, orElse: () => riyadh);
  }

  static SaudiCity nearest(double lat, double lng) {
    SaudiCity best = riyadh;
    var bestD = double.infinity;
    for (final city in all) {
      final dlat = city.lat - lat;
      final dlng = city.lng - lng;
      final d = dlat * dlat + dlng * dlng;
      if (d < bestD) {
        bestD = d;
        best = city;
      }
    }
    return best;
  }

  static bool insideKingdom(double lat, double lng) {
    return lat >= 16.0 && lat <= 32.6 && lng >= 34.4 && lng <= 55.8;
  }

  static Map<String, List<SaudiCity>> get grouped {
    final map = <String, List<SaudiCity>>{};
    for (final city in all) {
      map.putIfAbsent(city.region, () => []).add(city);
    }
    return map;
  }
}
