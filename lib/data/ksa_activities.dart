import '../models/activity.dart';
import 'activity_repository.dart';

List<KsaActivity> get ksaActivities => ActivityRepository.instance.places;

List<KsaActivity> activitiesNear(
  double lat,
  double lng, {
  String kind = 'all',
  String query = '',
  int limit = 800,
  String? preferCity,
}) {
  final q = query.trim().toLowerCase();
  final scored = <KsaActivity>[];
  for (final item in ksaActivities) {
    if (kind != 'all' && kind != 'nearby' && !activityMatchesKind(item, kind)) {
      continue;
    }
    if (q.isNotEmpty) {
      final blob =
          '${item.name} ${item.city} ${item.kind} ${item.about} ${item.area}'
              .toLowerCase();
      if (!blob.contains(q)) continue;
    }
    scored.add(
      item.withDistance(KsaActivity.kmBetween(lat, lng, item.lat, item.lng)),
    );
  }
  scored.sort((a, b) {
    final city = _cityFirst(a.city, b.city, preferCity);
    if (city != 0) return city;
    return a.km.compareTo(b.km);
  });
  if (scored.length <= limit) return scored;
  return scored.sublist(0, limit);
}

int _cityFirst(String a, String b, String? prefer) {
  if (prefer == null || prefer.trim().isEmpty) return 0;
  final ap = _sameCity(a, prefer);
  final bp = _sameCity(b, prefer);
  if (ap == bp) return 0;
  return ap ? -1 : 1;
}

bool _sameCity(String city, String prefer) {
  final left = city.trim().toLowerCase();
  final right = prefer.trim().toLowerCase();
  if (left.isEmpty || right.isEmpty) return false;
  return left == right;
}

bool activityMatchesKind(KsaActivity item, String kind) {
  if (item.kind == kind) return true;
  if (item.also.contains(kind)) return true;
  if (kind == 'mall') {
    final blob = '${item.name} ${item.area}'.toLowerCase();
    if (blob.contains('mall')) return true;
    const mallKinds = {
      'cinema',
      'bowl',
      'arcade',
      'ice',
      'trampoline',
      'vr',
      'escape',
    };
    if (mallKinds.contains(item.kind)) return true;
  }
  return false;
}

List<KsaActivity> activitiesInKind(List<KsaActivity> places, String kind) {
  return [for (final item in places) if (activityMatchesKind(item, kind)) item];
}

KsaActivity? activityById(String id) => ActivityRepository.instance.byId(id);
