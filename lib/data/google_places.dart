import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/restaurant.dart';
import 'maps_config.dart';
import 'restaurant_menus.dart';

class GooglePlacesException implements Exception {
  GooglePlacesException(this.message, {this.blocked = false});
  final String message;
  final bool blocked;
  @override
  String toString() => message;
}

class GooglePlaces {
  static const _nearby = 'https://places.googleapis.com/v1/places:searchNearby';
  static const _text = 'https://places.googleapis.com/v1/places:searchText';
  static const _fields =
      'places.id,places.displayName,places.formattedAddress,places.location,places.types,places.primaryType,places.nationalPhoneNumber,places.internationalPhoneNumber,places.websiteUri,places.googleMapsUri,places.photos,places.rating,places.userRatingCount,places.regularOpeningHours.weekdayDescriptions';

  static const _foodTypes = <String>[
    'restaurant',
    'cafe',
    'fast_food_restaurant',
    'meal_takeaway',
    'meal_delivery',
    'bakery',
    'coffee_shop',
  ];

  static Future<List<Restaurant>> nearby({
    required double lat,
    required double lng,
    double radius = 2200,
  }) async {
    try {
      return await _post(
        _nearby,
        {
          'includedTypes': _foodTypes,
          'maxResultCount': 20,
          'rankPreference': 'DISTANCE',
          'locationRestriction': {
            'circle': {
              'center': {'latitude': lat, 'longitude': lng},
              'radius': radius,
            },
          },
        },
      );
    } on GooglePlacesException catch (e) {
      if (e.blocked) rethrow;
      return _post(
        _nearby,
        {
          'includedTypes': ['restaurant'],
          'maxResultCount': 20,
          'rankPreference': 'DISTANCE',
          'locationRestriction': {
            'circle': {
              'center': {'latitude': lat, 'longitude': lng},
              'radius': radius,
            },
          },
        },
      );
    }
  }

  static Future<List<Restaurant>> searchText({
    required String query,
    required double lat,
    required double lng,
    double radius = 12000,
  }) async {
    final q = query.trim();
    if (q.length < 2) return const [];
    final body = {
      'textQuery': q,
      'pageSize': 20,
      'rankPreference': 'RELEVANCE',
      'locationBias': {
        'circle': {
          'center': {'latitude': lat, 'longitude': lng},
          'radius': radius,
        },
      },
    };
    try {
      return await _post(_text, body);
    } on GooglePlacesException catch (e) {
      if (e.blocked) rethrow;
      return _post(_text, {
        ...body,
        'includedType': 'restaurant',
      });
    }
  }

  static Future<List<Restaurant>> _post(
    String url,
    Map<String, dynamic> body,
  ) async {
    final res = await http
        .post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': kGoogleMapsApiKey,
            'X-Goog-FieldMask': _fields,
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));
    Map<String, dynamic> jsonMap;
    try {
      jsonMap = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw GooglePlacesException('Places returned ${res.statusCode}');
    }
    if (res.statusCode != 200) {
      final err = jsonMap['error'] as Map<String, dynamic>? ?? const {};
      final status = '${err['status'] ?? res.statusCode}';
      final message = '${err['message'] ?? 'Places request failed'}';
      final blocked = status.contains('PERMISSION') ||
          status.contains('DENIED') ||
          message.contains('enable') ||
          message.contains('Billing') ||
          message.contains('blocked');
      throw GooglePlacesException(message, blocked: blocked);
    }
    final out = <Restaurant>[];
    for (final item in jsonMap['places'] as List<dynamic>? ?? const []) {
      if (item is! Map<String, dynamic>) continue;
      final parsed = _fromPlace(item);
      if (parsed != null) out.add(parsed);
    }
    return out;
  }

  static Restaurant? _fromPlace(Map<String, dynamic> place) {
    final loc = place['location'] as Map<String, dynamic>? ?? const {};
    final lat = (loc['latitude'] as num?)?.toDouble();
    final lng = (loc['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;
    final name =
        '${(place['displayName'] as Map?)?['text'] ?? 'Restaurant'}'.trim();
    final types = (place['types'] as List?)?.map((e) => '$e').join(' ') ?? '';
    final primary = '${place['primaryType'] ?? ''}';
    final photos = place['photos'] as List<dynamic>? ?? const [];
    var image = '';
    for (final photo in photos) {
      if (photo is! Map) continue;
      final photoName = '${photo['name'] ?? ''}';
      if (photoName.isEmpty) continue;
      image =
          'https://places.googleapis.com/v1/$photoName/media?maxWidthPx=900&key=$kGoogleMapsApiKey';
      break;
    }
    final hours = ((place['regularOpeningHours'] as Map?)?['weekdayDescriptions']
                as List?)
            ?.map((e) => '$e')
            .join(' · ') ??
        '';
    final address = '${place['formattedAddress'] ?? ''}';
    return Restaurant(
      id: 'g-${place['id']}',
      name: name,
      lat: lat,
      lng: lng,
      kind: classifyCuisine('$primary $types', name),
      cuisine: primary.replaceAll('_', ' '),
      city: _cityFrom(address),
      phone:
          '${place['nationalPhoneNumber'] ?? place['internationalPhoneNumber'] ?? ''}',
      hours: hours,
      web: '${place['websiteUri'] ?? place['googleMapsUri'] ?? ''}',
      amenity: primary.isEmpty ? 'restaurant' : primary,
      image: image,
      rating: (place['rating'] as num?)?.toDouble() ?? 0,
      ratings: (place['userRatingCount'] as num?)?.toInt() ?? 0,
    );
  }

  static String _cityFrom(String address) {
    final parts = address
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.length < 2) return '';
    for (final part in parts.reversed) {
      final lower = part.toLowerCase();
      if (lower.contains('saudi') || lower.contains('kingdom')) continue;
      if (part.isNotEmpty &&
          part.codeUnitAt(0) >= 48 &&
          part.codeUnitAt(0) <= 57) {
        continue;
      }
      return part;
    }
    return parts.length >= 2 ? parts[parts.length - 2] : '';
  }
}
