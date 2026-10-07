import 'dart:convert';
import 'dart:math' as math;

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

  static bool _newApiDisabled = false;

  static Future<List<Restaurant>> nearby({
    required double lat,
    required double lng,
    double radius = 2200,
  }) async {
    if (!_newApiDisabled) {
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
        if (e.blocked) _newApiDisabled = true;
      }
    }
    return _legacyNearby(lat: lat, lng: lng, radius: radius);
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
    if (!_newApiDisabled) {
      try {
        return await _post(_text, body);
      } on GooglePlacesException catch (e) {
        if (e.blocked) _newApiDisabled = true;
      }
    }
    return _legacyText(query: q, lat: lat, lng: lng, radius: radius);
  }

  static Future<Restaurant> withDisplayPhoto(Restaurant place) async {
    if (place.image.isEmpty) return place;
    if (!place.image.contains('googleapis.com')) return place;
    final resolved = await resolvePhotoUrl(place.image);
    if (resolved == place.image) return place;
    return Restaurant(
      id: place.id,
      name: place.name,
      lat: place.lat,
      lng: place.lng,
      kind: place.kind,
      cuisine: place.cuisine,
      city: place.city,
      phone: place.phone,
      hours: place.hours,
      web: place.web,
      amenity: place.amenity,
      image: resolved,
      rating: place.rating,
      ratings: place.ratings,
      video: place.video,
      km: place.km,
    );
  }

  static Future<String> resolvePhotoUrl(String url) async {
    if (url.isEmpty) return url;
    try {
      final client = http.Client();
      try {
        final req = http.Request('GET', Uri.parse(url))
          ..followRedirects = false
          ..headers.addAll(kGooglePlacesAndroidHeaders);
        final streamed =
            await client.send(req).timeout(const Duration(seconds: 12));
        if (streamed.statusCode >= 300 && streamed.statusCode < 400) {
          final loc = streamed.headers['location'] ?? '';
          if (loc.startsWith('http')) return loc;
        }
        if (streamed.statusCode == 200) return url;
      } finally {
        client.close();
      }
    } catch (_) {}
    return url;
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
            ...kGooglePlacesAndroidHeaders,
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

  static Future<List<Restaurant>> _legacyNearby({
    required double lat,
    required double lng,
    required double radius,
  }) async {
    final chunks = await Future.wait([
      _legacyGet(
        path: '/maps/api/place/nearbysearch/json',
        query: {
          'location': '$lat,$lng',
          'radius': '${radius.round()}',
          'type': 'restaurant',
        },
      ),
      _legacyGet(
        path: '/maps/api/place/nearbysearch/json',
        query: {
          'location': '$lat,$lng',
          'radius': '${radius.round()}',
          'type': 'cafe',
        },
      ),
    ]);
    final byId = <String, Restaurant>{};
    for (final chunk in chunks) {
      for (final place in chunk) {
        byId[place.id] = place;
      }
    }
    return byId.values.toList();
  }

  static Future<List<Restaurant>> _legacyText({
    required String query,
    required double lat,
    required double lng,
    required double radius,
  }) {
    return _legacyGet(
      path: '/maps/api/place/textsearch/json',
      query: {
        'query': query,
        'location': '$lat,$lng',
        'radius': '${radius.round()}',
        'type': 'restaurant',
      },
    );
  }

  static Future<List<Restaurant>> _legacyGet({
    required String path,
    required Map<String, String> query,
  }) async {
    final uri = Uri.https('maps.googleapis.com', path, {
      ...query,
      'key': kGoogleMapsApiKey,
    });
    final res = await http
        .get(uri, headers: kGooglePlacesAndroidHeaders)
        .timeout(const Duration(seconds: 20));
    Map<String, dynamic> jsonMap;
    try {
      jsonMap = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw GooglePlacesException('Places returned ${res.statusCode}');
    }
    final status = '${jsonMap['status'] ?? res.statusCode}';
    if (status != 'OK' && status != 'ZERO_RESULTS') {
      final message = '${jsonMap['error_message'] ?? status}';
      throw GooglePlacesException(
        message,
        blocked: status == 'REQUEST_DENIED' ||
            message.contains('Billing') ||
            message.contains('enable'),
      );
    }
    final out = <Restaurant>[];
    for (final item in jsonMap['results'] as List<dynamic>? ?? const []) {
      if (item is! Map<String, dynamic>) continue;
      final parsed = _fromLegacy(item);
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

  static Restaurant? _fromLegacy(Map<String, dynamic> place) {
    final loc = place['geometry'] as Map<String, dynamic>? ?? const {};
    final coords = loc['location'] as Map<String, dynamic>? ?? const {};
    final lat = (coords['lat'] as num?)?.toDouble();
    final lng = (coords['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;
    final name = '${place['name'] ?? 'Restaurant'}'.trim();
    final types = (place['types'] as List?)?.map((e) => '$e').join(' ') ?? '';
    final photos = place['photos'] as List<dynamic>? ?? const [];
    var image = '';
    for (final photo in photos) {
      if (photo is! Map) continue;
      final ref = '${photo['photo_reference'] ?? ''}';
      if (ref.isEmpty) continue;
      image =
          'https://maps.googleapis.com/maps/api/place/photo?maxwidth=900&photoreference=$ref&key=$kGoogleMapsApiKey';
      break;
    }
    return Restaurant(
      id: 'g-${place['place_id']}',
      name: name,
      lat: lat,
      lng: lng,
      kind: classifyCuisine(types, name),
      cuisine: types.replaceAll('_', ' '),
      city: _cityFrom('${place['vicinity'] ?? place['formatted_address'] ?? ''}'),
      phone: '',
      hours: '',
      web: '',
      amenity: types.contains('cafe') ? 'cafe' : 'restaurant',
      image: image,
      rating: (place['rating'] as num?)?.toDouble() ?? 0,
      ratings: (place['user_ratings_total'] as num?)?.toInt() ?? 0,
    );
  }

  static String _cityFrom(String address) {
    final parts = address
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.length < 2) return parts.isEmpty ? '' : parts.first;
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

  static Future<List<GooglePlaceHit>> nearbySchools({
    required double lat,
    required double lng,
    double radius = 2500,
  }) async {
    if (!_newApiDisabled) {
      try {
        final places = await _post(_nearby, {
          'includedTypes': ['school'],
          'maxResultCount': 20,
          'rankPreference': 'DISTANCE',
          'locationRestriction': {
            'circle': {
              'center': {'latitude': lat, 'longitude': lng},
              'radius': radius,
            },
          },
        });
        return [
          for (final place in places)
            if (place.image.isNotEmpty) _hitFromRestaurant(place),
        ];
      } on GooglePlacesException catch (e) {
        if (e.blocked) _newApiDisabled = true;
      }
    }
    return [
      for (final place in await _legacyGet(
        path: '/maps/api/place/nearbysearch/json',
        query: {
          'location': '$lat,$lng',
          'radius': '${radius.round()}',
          'type': 'school',
        },
      ))
        if (place.image.isNotEmpty) _hitFromRestaurant(place),
    ];
  }

  static Future<GooglePlaceHit?> findSchool({
    required String name,
    required double lat,
    required double lng,
  }) async {
    final q = name.trim();
    if (q.length < 3) return null;
    List<Restaurant> found = const [];
    if (!_newApiDisabled) {
      try {
        found = await _post(_text, {
          'textQuery': '$q school Riyadh',
          'pageSize': 8,
          'includedType': 'school',
          'rankPreference': 'DISTANCE',
          'locationBias': {
            'circle': {
              'center': {'latitude': lat, 'longitude': lng},
              'radius': 2500,
            },
          },
        });
      } on GooglePlacesException catch (e) {
        if (e.blocked) _newApiDisabled = true;
      }
    }
    if (found.isEmpty) {
      found = await _legacyGet(
        path: '/maps/api/place/textsearch/json',
        query: {
          'query': '$q Riyadh',
          'location': '$lat,$lng',
          'radius': '2000',
          'type': 'school',
        },
      );
    }
    GooglePlaceHit? best;
    var bestKm = 0.45;
    for (final place in found) {
      if (place.image.isEmpty) continue;
      final d = _km(lat, lng, place.lat, place.lng);
      if (d > bestKm) continue;
      bestKm = d;
      best = _hitFromRestaurant(place);
    }
    return best;
  }

  static GooglePlaceHit _hitFromRestaurant(Restaurant place) {
    final id = place.id.startsWith('g-') ? place.id.substring(2) : place.id;
    return GooglePlaceHit(
      placeId: id,
      name: place.name,
      lat: place.lat,
      lng: place.lng,
      image: place.image,
    );
  }

  static double _km(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final p = math.pi / 180;
    final dLat = (lat2 - lat1) * p;
    final dLng = (lng2 - lng1) * p;
    final h = (1 - math.cos(dLat)) / 2 +
        math.cos(lat1 * p) * math.cos(lat2 * p) * (1 - math.cos(dLng)) / 2;
    return 2 * r * math.asin(math.sqrt(h.clamp(0.0, 1.0)));
  }
}

class GooglePlaceHit {
  const GooglePlaceHit({
    required this.placeId,
    required this.name,
    required this.lat,
    required this.lng,
    this.image = '',
  });

  final String placeId;
  final String name;
  final double lat;
  final double lng;
  final String image;
}
