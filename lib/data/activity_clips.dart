import 'activity_repository.dart';

String? clipForActivity(String activityId) {
  final video = ActivityRepository.instance.byId(activityId)?.video.trim();
  if (video == null || video.isEmpty) return null;
  return video;
}
