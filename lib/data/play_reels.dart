import '../models/play_reel.dart';
import 'reels_repository.dart';

export '../models/play_reel.dart';

List<PlayReel> get playReels => ReelsRepository.instance.items;

PlayReel? reelForActivity(String activityId) {
  for (final reel in playReels) {
    if (reel.source == 'activity' && reel.placeId == activityId) return reel;
  }
  return null;
}

/// Unwatched clips in the current city, then other unwatched clips, then
/// anything already watched.
List<PlayReel> orderedReels({
  required Set<String> watchedIds,
  String? preferCity,
}) {
  final city = preferCity?.trim().toLowerCase() ?? '';
  int rank(PlayReel reel) {
    final seen = watchedIds.contains(reel.youtubeId);
    final same = city.isNotEmpty && reel.city.toLowerCase() == city;
    if (!seen && same) return 0;
    if (!seen) return 1;
    return 2;
  }

  final indexed = playReels.asMap().entries.toList();
  indexed.sort((a, b) {
    final byRank = rank(a.value).compareTo(rank(b.value));
    if (byRank != 0) return byRank;
    return a.key.compareTo(b.key);
  });
  return [for (final entry in indexed) entry.value];
}
