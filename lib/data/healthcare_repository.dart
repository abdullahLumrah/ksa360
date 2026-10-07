import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../models/health_facility.dart';
import 'app_api.dart';
import 'app_api_config.dart';
import 'life_settings.dart';

class HealthcareRepository extends ChangeNotifier {
  HealthcareRepository._();
  static final HealthcareRepository instance = HealthcareRepository._();

  List<HealthFacility> places = const [];
  List<HealthHotline> hotlines = const [];
  List<HealthStep> steps = const [];
  Map<String, int> kindCounts = const {};
  bool loaded = false;
  bool refreshing = false;
  String? refreshError;
  ({double lat, double lng})? _queued;
  final _fetchedCells = <String>{};

  Future<void> load() async {
    if (loaded) return;
    await Future.wait([
      refreshEmergency(),
      refreshAround(
        LifeSettings.instance.prayerLat,
        LifeSettings.instance.prayerLng,
      ),
    ]);
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

  List<HealthFacility> nearby({
    required double lat,
    required double lng,
    String kind = 'nearby',
    String query = '',
    int limit = 8000,
    bool emergencyOnly = false,
  }) {
    final q = query.trim().toLowerCase();
    final scored = <HealthFacility>[];
    for (final place in places) {
      if (emergencyOnly && !place.emergency) continue;
      if (kind != 'nearby' && q.isEmpty && place.kind != kind) continue;
      if (q.isNotEmpty) {
        final blob =
            '${place.name} ${place.city} ${place.kind} ${place.services.join(' ')}'
                .toLowerCase();
        if (!place.name.toLowerCase().contains(q) && !blob.contains(q)) {
          continue;
        }
      }
      scored.add(place.withDistance(km(lat, lng, place.lat, place.lng)));
    }
    scored.sort((a, b) {
      if (q.isNotEmpty) {
        final aName = a.name.toLowerCase();
        final bName = b.name.toLowerCase();
        final aHit = aName.startsWith(q) ? 0 : aName.contains(q) ? 1 : 2;
        final bHit = bName.startsWith(q) ? 0 : bName.contains(q) ? 1 : 2;
        if (aHit != bHit) return aHit.compareTo(bHit);
      }
      if (emergencyOnly && a.emergency != b.emergency) {
        return a.emergency ? -1 : 1;
      }
      return a.km.compareTo(b.km);
    });
    if (scored.length <= limit) return scored;
    return scored.sublist(0, limit);
  }

  Future<void> refreshEmergency() async {
    try {
      final uri = Uri.parse('${AppApiConfig.baseUrl}/healthcare/emergency');
      final res = await AppApi.get(uri);
      if (res.statusCode != 200) return;
      final map = jsonDecode(res.body) as Map<String, dynamic>;
      hotlines = [
        for (final item in map['hotlines'] as List<dynamic>? ?? const [])
          HealthHotline.fromJson(item as Map<String, dynamic>),
      ];
      steps = [
        for (final item in map['steps'] as List<dynamic>? ?? const [])
          HealthStep.fromJson(item as Map<String, dynamic>),
      ];
      notifyListeners();
    } catch (_) {}
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
        final incoming = await _fetchNearby(lat: next.lat, lng: next.lng);
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

  Future<List<HealthFacility>> _fetchNearby({
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
    final uri = Uri.parse('${AppApiConfig.baseUrl}/healthcare/nearby').replace(
      queryParameters: {
        'lat': lat.toString(),
        'lng': lng.toString(),
        'kind': kind,
        'limit': '$limit',
        'radiusKm': '$radiusKm',
        if (query.trim().isNotEmpty) 'q': query.trim(),
      },
    );
    final res = await AppApi.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Healthcare API ${res.statusCode}');
    }
    if (query.isEmpty) _fetchedCells.add(cell);
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    final list = map['items'] as List<dynamic>? ?? const [];
    return [
      for (final item in list)
        HealthFacility.fromJson(item as Map<String, dynamic>),
    ];
  }

  int _merge(List<HealthFacility> incoming) {
    if (incoming.isEmpty) return 0;
    final byId = {for (final p in places) p.id: p};
    var added = 0;
    for (final place in incoming) {
      if (byId.containsKey(place.id)) {
        final current = byId[place.id]!;
        if (place.phone.isNotEmpty && current.phone.isEmpty) {
          byId[place.id] = place;
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
}
