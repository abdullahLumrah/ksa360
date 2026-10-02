import 'dart:convert';

import '../models/restaurant.dart';
import 'app_api.dart';
import 'app_api_config.dart';

class PlaceVideos {
  PlaceVideos._();

  static const _skip = {
    'restaurant',
    'cafe',
    'fast food',
    'food',
    'coffee',
    'cafeteria',
    'مطعم',
    'كافيه',
  };

  static final _memory = <String, String?>{};

  /// Clip mapped to this restaurant on the backend. No local JSON, no live guess.
  static Future<String?> forRestaurant(Restaurant place) async {
    if (place.video.trim().isNotEmpty) return place.video.trim();
    final key = place.name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    if (key.length < 3 || _skip.contains(key)) return null;
    if (_memory.containsKey(key)) return _memory[key];
    try {
      final uri = Uri.parse('${AppApiConfig.baseUrl}/restaurants/video').replace(
        queryParameters: {'name': place.name},
      );
      final res = await AppApi.get(uri, timeout: const Duration(seconds: 8));
      if (res.statusCode != 200) {
        _memory[key] = null;
        return null;
      }
      final map = jsonDecode(res.body) as Map<String, dynamic>;
      final video = (map['video'] as String?)?.trim();
      final id = (video == null || video.isEmpty) ? null : video;
      _memory[key] = id;
      return id;
    } catch (_) {
      _memory[key] = null;
      return null;
    }
  }
}
