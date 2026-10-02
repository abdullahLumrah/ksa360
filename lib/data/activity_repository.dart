import 'dart:convert';

import 'package:flutter/foundation.dart';
import '../models/activity.dart';
import 'app_api.dart';
import 'app_api_config.dart';
import 'life_settings.dart';

class ActivityRepository extends ChangeNotifier {
  ActivityRepository._();
  static final ActivityRepository instance = ActivityRepository._();

  List<KsaActivity> places = const [];
  bool loaded = false;
  bool refreshing = false;
  String? refreshError;

  KsaActivity? byId(String id) {
    for (final item in places) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<void> load() async {
    if (loaded) return;
    final settings = LifeSettings.instance;
    await refreshAround(settings.prayerLat, settings.prayerLng);
    loaded = true;
    notifyListeners();
  }

  Future<void> refreshAround(double lat, double lng) async {
    refreshing = true;
    refreshError = null;
    notifyListeners();
    try {
      final incoming = await _fetchNearby(lat: lat, lng: lng);
      if (incoming.isNotEmpty) {
        places = incoming;
      }
    } catch (e) {
      refreshError = e.toString();
    } finally {
      refreshing = false;
      notifyListeners();
    }
  }

  Future<List<KsaActivity>> _fetchNearby({
    required double lat,
    required double lng,
    String query = '',
    String kind = 'all',
  }) async {
    final uri = Uri.parse('${AppApiConfig.baseUrl}/activities/nearby').replace(
      queryParameters: {
        'lat': lat.toString(),
        'lng': lng.toString(),
        'kind': kind,
        'limit': '400',
        'radiusKm': '800',
        if (query.trim().isNotEmpty) 'q': query.trim(),
        if (LifeSettings.instance.city.name.isNotEmpty)
          'city': LifeSettings.instance.city.name,
      },
    );
    final res = await AppApi.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Activities API ${res.statusCode}');
    }
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    final list = map['items'] as List<dynamic>? ?? const [];
    return [
      for (final item in list) KsaActivity.fromJson(item as Map<String, dynamic>),
    ];
  }
}
