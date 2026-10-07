import 'package:flutter/material.dart';

import '../models/school.dart';
import 'maps_config.dart';

Color schoolPinColor(School school) {
  final tag = school.curriculumTags.isEmpty
      ? ''
      : school.curriculumTags.first.toLowerCase();
  switch (tag) {
    case 'british':
      return const Color(0xFF8A5E2E);
    case 'ib':
      return const Color(0xFF1E7A4C);
    case 'indian':
      return const Color(0xFFB55242);
    case 'french':
      return const Color(0xFF3D6A94);
    case 'american':
      return const Color(0xFF2C5A88);
    case 'filipino':
      return const Color(0xFF2C7A68);
    case 'pakistani':
      return const Color(0xFF6E5688);
    default:
      return const Color(0xFF143D2C);
  }
}

String schoolStreetViewUrl(School school) {
  if (!school.hasPin) return '';
  return Uri.https('maps.googleapis.com', '/maps/api/streetview', {
    'size': '800x500',
    'location': '${school.lat},${school.lng}',
    'fov': '80',
    'source': 'outdoor',
    'key': kGoogleMapsApiKey,
  }).toString();
}

String schoolPhotoFor(School school) {
  if (school.image.trim().isNotEmpty) return school.image.trim();
  return schoolStreetViewUrl(school);
}

List<String> schoolGalleryUrls(School school) {
  final urls = <String>[];
  final own = school.image.trim();
  if (own.isNotEmpty) urls.add(own);
  final street = schoolStreetViewUrl(school);
  if (street.isNotEmpty && street != own) urls.add(street);
  return urls;
}

Map<String, String> schoolPhotoHeaders(String url) {
  if (!url.contains('googleapis.com')) return const {};
  return {
    ...kGooglePlacesAndroidHeaders,
    ...kGooglePlacesIosHeaders,
  };
}
