import 'activity.dart';
import 'restaurant.dart';

class PlayReel {
  const PlayReel({
    required this.id,
    required this.youtubeId,
    required this.source,
    required this.placeId,
    this.title = '',
    this.hook = '',
    this.city = '',
    this.activity,
    this.restaurant,
  });

  final String id;
  final String youtubeId;
  final String source;
  final String placeId;
  final String title;
  final String hook;
  final String city;
  final KsaActivity? activity;
  final Restaurant? restaurant;

  String get activityId => source == 'activity' ? placeId : '';

  String get displayTitle {
    if (title.trim().isNotEmpty) return title;
    if (activity != null) return activity!.name;
    if (restaurant != null) return restaurant!.name;
    return hook;
  }

  String get thumb => 'https://i.ytimg.com/vi/$youtubeId/hqdefault.jpg';

  Uri get watchUri => Uri.parse('https://www.youtube.com/watch?v=$youtubeId');

  Uri get shortsUri => Uri.parse('https://www.youtube.com/shorts/$youtubeId');

  Uri get embedUri => Uri.parse(
        'https://www.youtube.com/embed/$youtubeId'
        '?autoplay=1&mute=1&playsinline=1&loop=1'
        '&playlist=$youtubeId&rel=0&modestbranding=1&controls=0'
        '&fs=0&enablejsapi=1&origin=https%3A%2F%2Fwww.youtube.com'
        '&widget_referrer=https%3A%2F%2Fwww.youtube.com',
      );

  factory PlayReel.fromJson(Map<String, dynamic> json) {
    final nestedActivity = json['activity'];
    final nestedRestaurant = json['restaurant'];
    final activity = nestedActivity is Map<String, dynamic>
        ? KsaActivity.fromJson(nestedActivity)
        : null;
    final restaurant = nestedRestaurant is Map<String, dynamic>
        ? Restaurant.fromJson(nestedRestaurant)
        : null;
    return PlayReel(
      id: json['id'] as String? ??
          json['youtubeId'] as String? ??
          json['youtube_id'] as String? ??
          '',
      youtubeId: json['youtubeId'] as String? ?? json['youtube_id'] as String? ?? '',
      source: json['source'] as String? ?? 'activity',
      placeId: json['placeId'] as String? ??
          json['place_id'] as String? ??
          json['activityId'] as String? ??
          json['activity_id'] as String? ??
          '',
      title: json['title'] as String? ?? '',
      hook: json['hook'] as String? ?? '',
      city: json['city'] as String? ??
          activity?.city ??
          restaurant?.city ??
          '',
      activity: activity,
      restaurant: restaurant,
    );
  }
}
