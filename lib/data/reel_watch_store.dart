import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Reels the user has already opened. The feed keeps these at the end.
class ReelWatchStore extends ChangeNotifier {
  ReelWatchStore._();
  static final ReelWatchStore instance = ReelWatchStore._();

  static const _key = 'play_watched_reel_ids';
  final watched = <String>{};
  bool loaded = false;

  bool isWatched(String youtubeId) => watched.contains(youtubeId);

  Future<void> load() async {
    if (loaded) return;
    final prefs = await SharedPreferences.getInstance();
    watched
      ..clear()
      ..addAll(prefs.getStringList(_key) ?? const []);
    loaded = true;
    notifyListeners();
  }

  Future<void> mark(String youtubeId) async {
    if (youtubeId.isEmpty || watched.contains(youtubeId)) return;
    watched.add(youtubeId);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, watched.toList());
  }
}
