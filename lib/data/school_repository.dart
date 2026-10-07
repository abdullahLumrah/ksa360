import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../models/school.dart';
import 'app_api.dart';
import 'google_places.dart';
import 'life_settings.dart';

class SchoolRepository extends ChangeNotifier {
  SchoolRepository._();
  static final SchoolRepository instance = SchoolRepository._();

  List<School> places = const [];
  List<SchoolFilter> curriculums = const [];
  List<SchoolFilter> cities = const [];
  bool loaded = false;
  bool refreshing = false;
  String? refreshError;
  String disclaimer = '';
  ({double lat, double lng})? _queued;
  final _fetchedCells = <String>{};
  final _photoCells = <String>{};
  bool _photosBusy = false;

  Future<void> load() async {
    if (loaded) return;
    await Future.wait([
      refreshFilters(),
      refreshAround(
        LifeSettings.instance.prayerLat,
        LifeSettings.instance.prayerLng,
      ),
      refreshCatalog(),
    ]);
    loaded = true;
    notifyListeners();
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
    return 2 * r * math.asin(math.sqrt(a.clamp(0, 1)));
  }

  List<School> nearby({
    required double lat,
    required double lng,
    String query = '',
    String curriculum = '',
    int limit = 400,
  }) {
    final q = query.trim().toLowerCase();
    final tag = curriculum.trim().toLowerCase();
    final scored = <School>[];
    for (final school in places) {
      if (tag.isNotEmpty &&
          tag != 'nearby' &&
          !school.curriculumTags.contains(tag)) {
        continue;
      }
      if (q.isNotEmpty) {
        final blob =
            '${school.name} ${school.city} ${school.district} ${school.curriculum.join(' ')}'
                .toLowerCase();
        if (!school.name.toLowerCase().contains(q) && !blob.contains(q)) {
          continue;
        }
      }
      scored.add(
        school.hasPin
            ? school.withDistance(km(lat, lng, school.lat, school.lng))
            : school,
      );
    }
    scored.sort((a, b) {
      if (q.isNotEmpty) {
        final aName = a.name.toLowerCase();
        final bName = b.name.toLowerCase();
        final aHit = aName.startsWith(q)
            ? 0
            : aName.contains(q)
                ? 1
                : 2;
        final bHit = bName.startsWith(q)
            ? 0
            : bName.contains(q)
                ? 1
                : 2;
        if (aHit != bHit) return aHit.compareTo(bHit);
      }
      if (a.hasPin && b.hasPin) return a.km.compareTo(b.km);
      if (a.hasPin != b.hasPin) return a.hasPin ? -1 : 1;
      return a.name.compareTo(b.name);
    });
    if (scored.length <= limit) return scored;
    return scored.sublist(0, limit);
  }

  Future<void> refreshFilters() async {
    try {
      final res = await AppApi.get(AppApi.uri('/schools/filters'));
      if (res.statusCode != 200) return;
      final map = jsonDecode(res.body) as Map<String, dynamic>;
      disclaimer = '${map['disclaimer'] ?? ''}';
      curriculums = [
        for (final item in map['curriculums'] as List<dynamic>? ?? const [])
          SchoolFilter(
            id: '${(item as Map)['id']}',
            count: (item['count'] as num?)?.toInt() ?? 0,
          ),
      ];
      cities = [
        for (final item in map['cities'] as List<dynamic>? ?? const [])
          SchoolFilter(
            id: '${(item as Map)['id']}',
            count: (item['count'] as num?)?.toInt() ?? 0,
          ),
      ];
      notifyListeners();
    } catch (e) {
      debugPrint('schools filters skipped: $e');
    }
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
        final incoming = await _fetch(
          lat: next.lat,
          lng: next.lng,
        );
        if (incoming.isEmpty) continue;
        if (_merge(incoming) > 0) notifyListeners();
        _enrichPhotos(next.lat, next.lng);
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
      final found = await _fetch(lat: lat, lng: lng, query: q, radiusKm: 250);
      if (found.isEmpty) return;
      if (_merge(found) > 0) notifyListeners();
    } catch (_) {}
  }

  Future<void> refreshCatalog({String city = '', String query = ''}) async {
    try {
      final res = await AppApi.get(
        AppApi.uri('/schools', {
          'limit': '600',
          if (city.trim().isNotEmpty) 'city': city.trim(),
          if (query.trim().isNotEmpty) 'q': query.trim(),
        }),
      );
      if (res.statusCode != 200) return;
      final map = jsonDecode(res.body) as Map<String, dynamic>;
      if ('${map['disclaimer'] ?? ''}'.isNotEmpty) {
        disclaimer = '${map['disclaimer']}';
      }
      final incoming = [
        for (final item in map['items'] as List<dynamic>? ?? const [])
          School.fromJson(item as Map<String, dynamic>),
      ];
      if (_merge(incoming) > 0) notifyListeners();
    } catch (e) {
      debugPrint('schools catalog skipped: $e');
    }
  }

  Future<School?> byId(String id) async {
    try {
      final settings = LifeSettings.instance;
      final res = await AppApi.get(
        AppApi.uri('/schools/$id', {
          'lat': '${settings.prayerLat}',
          'lng': '${settings.prayerLng}',
        }),
      );
      if (res.statusCode != 200) return null;
      var school = School.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
      _merge([school]);
      if (school.image.isEmpty && school.hasPin) {
        await _photoFor(school);
        school = places.firstWhere((item) => item.id == school.id, orElse: () => school);
      }
      notifyListeners();
      return school;
    } catch (e) {
      debugPrint('school detail skipped: $e');
      return null;
    }
  }

  Future<List<School>> _fetch({
    required double lat,
    required double lng,
    String query = '',
    String curriculum = '',
    int limit = 400,
    double radiusKm = 80,
  }) async {
    final cell =
        '${(lat * 20).round()}_${(lng * 20).round()}_${curriculum}_$query';
    if (query.isEmpty && _fetchedCells.contains(cell) && places.isNotEmpty) {
      return const [];
    }
    final res = await AppApi.get(
      AppApi.uri('/schools/nearby', {
        'lat': lat.toString(),
        'lng': lng.toString(),
        'limit': '$limit',
        'radiusKm': '$radiusKm',
        if (query.trim().isNotEmpty) 'q': query.trim(),
        if (curriculum.isNotEmpty && curriculum != 'nearby')
          'curriculum': curriculum,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('Schools API ${res.statusCode}');
    }
    if (query.isEmpty) _fetchedCells.add(cell);
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    return [
      for (final item in map['items'] as List<dynamic>? ?? const [])
        School.fromJson(item as Map<String, dynamic>),
    ];
  }

  int _merge(List<School> incoming) {
    if (incoming.isEmpty) return 0;
    final byId = {for (final school in places) school.id: school};
    var added = 0;
    var changed = 0;
    for (final school in incoming) {
      final current = byId[school.id];
      if (current == null) {
        byId[school.id] = school;
        added += 1;
        continue;
      }
      final richer = school.fees.byGrade.isNotEmpty ||
          school.admission.steps.isNotEmpty;
      final image = school.image.isNotEmpty ? school.image : current.image;
      final placeId = school.googlePlaceId.isNotEmpty
          ? school.googlePlaceId
          : current.googlePlaceId;
      if (richer) {
        byId[school.id] = school.copyWith(image: image, googlePlaceId: placeId);
        changed += 1;
      } else if (image != current.image || placeId != current.googlePlaceId) {
        byId[school.id] =
            current.copyWith(image: image, googlePlaceId: placeId);
        changed += 1;
      }
    }
    places = byId.values.toList();
    return added + changed;
  }

  Future<void> _enrichPhotos(double lat, double lng) async {
    final cell = '${(lat * 40).round()}_${(lng * 40).round()}';
    if (_photosBusy || _photoCells.contains(cell)) return;
    _photosBusy = true;
    try {
      final hits = await GooglePlaces.nearbySchools(lat: lat, lng: lng);
      if (hits.isEmpty) return;
      final resolved = <GooglePlaceHit>[];
      for (final hit in hits) {
        final image = await GooglePlaces.resolvePhotoUrl(hit.image);
        resolved.add(
          GooglePlaceHit(
            placeId: hit.placeId,
            name: hit.name,
            lat: hit.lat,
            lng: hit.lng,
            image: image,
          ),
        );
      }
      final overlay = <School>[];
      final payload = <Map<String, dynamic>>[];
      for (final hit in resolved) {
        if (hit.image.isEmpty) continue;
        final match = _matchSchool(hit);
        if (match == null || match.image.contains('googleapis.com')) continue;
        overlay.add(
          match.copyWith(image: hit.image, googlePlaceId: hit.placeId),
        );
        payload.add({
          'id': match.id,
          'image': hit.image,
          'googlePlaceId': hit.placeId,
        });
      }
      if (overlay.isEmpty) return;
      if (_merge(overlay) > 0) notifyListeners();
      _persistPhotos(payload);
      _photoCells.add(cell);
    } catch (e) {
      debugPrint('school photos skipped: $e');
    } finally {
      _photosBusy = false;
    }
  }

  Future<void> _photoFor(School school) async {
    try {
      final hit = await GooglePlaces.findSchool(
        name: school.name,
        lat: school.lat,
        lng: school.lng,
      );
      if (hit == null || hit.image.isEmpty) return;
      final image = await GooglePlaces.resolvePhotoUrl(hit.image);
      if (image.isEmpty) return;
      if (_merge([school.copyWith(image: image, googlePlaceId: hit.placeId)]) >
          0) {
        notifyListeners();
      }
      _persistPhotos([
        {'id': school.id, 'image': image, 'googlePlaceId': hit.placeId},
      ]);
    } catch (e) {
      debugPrint('school photo skipped: $e');
    }
  }

  School? _matchSchool(GooglePlaceHit hit) {
    School? best;
    var bestScore = 1.2;
    final hitName = _norm(hit.name);
    for (final school in places) {
      if (!school.hasPin) continue;
      final d = km(hit.lat, hit.lng, school.lat, school.lng);
      if (d > 0.4) continue;
      final name = _norm(school.name);
      final named = name.contains(hitName) ||
          hitName.contains(name) ||
          (name.length > 8 && hitName.contains(name.substring(0, 8)));
      final score = d + (named ? 0 : 0.25);
      if (score >= bestScore) continue;
      bestScore = score;
      best = school;
    }
    return best;
  }

  static String _norm(String name) {
    final buf = StringBuffer();
    for (final rune in name.toLowerCase().runes) {
      final az = rune >= 97 && rune <= 122;
      final digit = rune >= 48 && rune <= 57;
      if (az || digit) buf.writeCharCode(rune);
    }
    return buf.toString();
  }

  Future<void> _persistPhotos(List<Map<String, dynamic>> items) async {
    if (items.isEmpty) return;
    try {
      await AppApi.post(
        AppApi.uri('/schools/photos'),
        body: jsonEncode({'items': items}),
      );
    } catch (_) {}
  }
}
