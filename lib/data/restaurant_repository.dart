import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import '../models/restaurant.dart';
import 'app_api.dart';
import 'app_api_config.dart';
import 'life_settings.dart';
import 'saudi_cities.dart';

class RestaurantRepository extends ChangeNotifier {
  RestaurantRepository._();
  static final RestaurantRepository instance = RestaurantRepository._();

  List<Restaurant> places = const [];
  Map<String, int> kindCounts = const {};
  bool loaded = false;
  bool refreshing = false;
  String? refreshError;
  ({double lat, double lng})? _queued;
  final _fetchedCells = <String>{};

  Future<void> load() async {
    if (loaded) return;
    final settings = LifeSettings.instance;
    await refreshAround(settings.prayerLat, settings.prayerLng);
    loaded = true;
    notifyListeners();
  }

  void _recount() {
    final counts = <String, int>{};
    for (final p in places) {
      counts[p.kind] = (counts[p.kind] ?? 0) + 1;
    }
    kindCounts = counts;
  }

  static double km(double lat1, double lng1, double lat2, double lng2) {
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

  List<Restaurant> nearby({
    required double lat,
    required double lng,
    String kind = 'nearby',
    String query = '',
    int limit = 8000,
    String? preferCity,
  }) {
    final q = query.trim().toLowerCase();
    final tokens = q
        .split(RegExp(r'\s+'))
        .where((t) => t.length >= 2)
        .toList();
    final scored = <Restaurant>[];
    for (final place in places) {
      if (kind != 'nearby' && q.isEmpty && place.kind != kind) continue;
      if (q.isNotEmpty) {
        final blob =
            '${place.name} ${place.city} ${place.cuisine} ${place.kind}'.toLowerCase();
        final named = place.name.toLowerCase();
        final ok = named.contains(q) ||
            blob.contains(q) ||
            (tokens.length >= 2 && tokens.every(blob.contains));
        if (!ok) continue;
      }
      scored.add(place.withDistance(km(lat, lng, place.lat, place.lng)));
    }
    scored.sort((a, b) {
      if (q.isNotEmpty) {
        final rank = _nameRank(a.name, q).compareTo(_nameRank(b.name, q));
        if (rank != 0) return rank;
      }
      final city = _cityFirst(a, b, preferCity);
      if (city != 0) return city;
      return a.km.compareTo(b.km);
    });
    if (scored.length <= limit) return scored;
    return scored.sublist(0, limit);
  }

  static int _nameRank(String name, String q) {
    final n = name.toLowerCase();
    if (n == q) return 0;
    if (n.startsWith(q)) return 1;
    if (n.contains(q)) return 2;
    final tokens = q.split(RegExp(r'\s+')).where((t) => t.length >= 2);
    if (tokens.isNotEmpty && tokens.every(n.contains)) return 3;
    return 4;
  }

  static int _cityFirst(Restaurant a, Restaurant b, String? prefer) {
    if (prefer == null || prefer.trim().isEmpty) return 0;
    final ap = _inCity(a, prefer);
    final bp = _inCity(b, prefer);
    if (ap == bp) return 0;
    return ap ? -1 : 1;
  }

  static bool _inCity(Restaurant place, String prefer) {
    final labeled = _canonicalCity(place.city);
    if (labeled != null && labeled.toLowerCase() == prefer.toLowerCase()) {
      return true;
    }
    return SaudiCities.nearest(place.lat, place.lng).name.toLowerCase() ==
        prefer.toLowerCase();
  }

  static String? _canonicalCity(String raw) {
    final key = raw.trim().toLowerCase();
    if (key.isEmpty) return null;
    final alias = _cityAliases[key];
    if (alias != null) return alias;
    for (final city in SaudiCities.all) {
      if (city.name.toLowerCase() == key) return city.name;
    }
    return null;
  }

  Future<void> refreshAround(double lat, double lng) async {
    _queued = (lat: lat, lng: lng);
    if (refreshing) return;
    refreshing = true;
    refreshError = null;
    notifyListeners();
    try {
      while (_queued != null) {
        final next = _queued!;
        _queued = null;
        final incoming = await _fetchNearby(
          lat: next.lat,
          lng: next.lng,
        );
        if (incoming.isEmpty) continue;
        if (_merge(incoming) > 0) notifyListeners();
      }
    } catch (e) {
      refreshError = e.toString();
    } finally {
      refreshing = false;
      notifyListeners();
    }
  }

  Future<void> searchRemote(String query, double lat, double lng) async {
    final q = query.trim();
    if (q.length < 2) return;
    try {
      final found = await _fetchNearby(lat: lat, lng: lng, query: q);
      if (found.isEmpty) return;
      if (_merge(found) > 0) notifyListeners();
    } catch (_) {}
  }

  Future<List<Restaurant>> _fetchNearby({
    required double lat,
    required double lng,
    String query = '',
    String kind = 'nearby',
    int limit = 400,
    double radiusKm = 80,
  }) async {
    final cell = '${(lat * 20).round()}_${(lng * 20).round()}_$kind';
    if (query.isEmpty && _fetchedCells.contains(cell) && places.isNotEmpty) {
      return const [];
    }
    final uri = Uri.parse('${AppApiConfig.baseUrl}/restaurants/nearby').replace(
      queryParameters: {
        'lat': lat.toString(),
        'lng': lng.toString(),
        'kind': kind,
        'limit': '$limit',
        'radiusKm': '$radiusKm',
        if (query.trim().isNotEmpty) 'q': query.trim(),
        if (LifeSettings.instance.city.name.isNotEmpty)
          'city': LifeSettings.instance.city.name,
      },
    );
    final res = await AppApi.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Restaurants API ${res.statusCode}');
    }
    if (query.isEmpty) _fetchedCells.add(cell);
    return _parseNearby(res.body);
  }

  static List<Restaurant> _parseNearby(String body) {
    final map = jsonDecode(body) as Map<String, dynamic>;
    final list = map['items'] as List<dynamic>? ?? const [];
    return [
      for (final item in list)
        Restaurant.fromJson(item as Map<String, dynamic>),
    ];
  }

  int _merge(List<Restaurant> incoming) {
    if (incoming.isEmpty) return 0;
    final byId = {for (final p in places) p.id: p};
    var added = 0;
    for (final place in incoming) {
      final existingId = _duplicateId(place, byId.values);
      if (existingId != null) {
        final current = byId[existingId]!;
        final richerImage = place.image.isNotEmpty && current.image.isEmpty;
        final richerVideo = place.video.isNotEmpty && current.video.isEmpty;
        if (richerImage || richerVideo) {
          byId[existingId] = Restaurant(
            id: current.id,
            name: current.name,
            lat: current.lat,
            lng: current.lng,
            kind: current.kind,
            cuisine: current.cuisine,
            city: current.city,
            phone: current.phone,
            hours: current.hours,
            web: current.web,
            amenity: current.amenity,
            image: richerImage ? place.image : current.image,
            rating: current.rating,
            ratings: current.ratings,
            video: richerVideo ? place.video : current.video,
            km: current.km,
          );
        }
        continue;
      }
      byId[place.id] = place;
      added++;
    }
    if (added == 0 && places.isNotEmpty) return 0;
    places = byId.values.toList();
    _recount();
    return added == 0 ? places.length : added;
  }

  String? _duplicateId(Restaurant place, Iterable<Restaurant> existing) {
    final needle = _norm(place.name);
    for (final other in existing) {
      if (other.id == place.id) return other.id;
      if (needle.length < 4) continue;
      if (km(place.lat, place.lng, other.lat, other.lng) > 0.09) continue;
      if (_norm(other.name) == needle) return other.id;
    }
    return null;
  }

  static String _norm(String name) {
    final buf = StringBuffer();
    for (final rune in name.toLowerCase().runes) {
      final az = rune >= 97 && rune <= 122;
      final digit = rune >= 48 && rune <= 57;
      final ar = rune >= 0x0600 && rune <= 0x06FF;
      if (az || digit || ar) buf.writeCharCode(rune);
    }
    return buf.toString();
  }
}

const _cityAliases = <String, String>{
  'الرياض': 'Riyadh',
  'riyadh': 'Riyadh',
  'جدة': 'Jeddah',
  'jeddah': 'Jeddah',
  'مكة': 'Makkah',
  'مكة المكرمة': 'Makkah',
  'makkah': 'Makkah',
  'mecca': 'Makkah',
  'المدينة': 'Madinah',
  'المدينة المنورة': 'Madinah',
  'madinah': 'Madinah',
  'medina': 'Madinah',
  'الدمام': 'Dammam',
  'dammam': 'Dammam',
  'الخبر': 'Khobar',
  'khobar': 'Khobar',
  'al khobar': 'Khobar',
  'الظهران': 'Dhahran',
  'dhahran': 'Dhahran',
  'الدرعية': 'Diriyah',
  'diriyah': 'Diriyah',
  'الجبيل': 'Jubail',
  'jubail': 'Jubail',
  'ينبع': 'Yanbu',
  'yanbu': 'Yanbu',
  'الأحساء': 'Hofuf (Al Ahsa)',
  'الاحساء': 'Hofuf (Al Ahsa)',
  'الهفوف': 'Hofuf (Al Ahsa)',
  'hofuf': 'Hofuf (Al Ahsa)',
  'الطائف': 'Taif',
  'taif': 'Taif',
  'نجران': 'Najran',
  'najran': 'Najran',
  'أبها': 'Abha',
  'ابها': 'Abha',
  'abha': 'Abha',
  'تبوك': 'Tabuk',
  'tabuk': 'Tabuk',
  'بريدة': 'Buraidah',
  'buraidah': 'Buraidah',
  'خميس مشيط': 'Khamis Mushait',
  'جازان': 'Jazan',
  'جيزان': 'Jazan',
  'jazan': 'Jazan',
  'القطيف': 'Qatif',
  'حائل': 'Hail',
  'hail': 'Hail',
};
