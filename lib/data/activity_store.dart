import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ActivityStore extends ChangeNotifier {
  ActivityStore._();
  static final ActivityStore instance = ActivityStore._();

  static const _key = 'play_saved_ids';
  final saved = <String>{};
  bool loaded = false;

  bool isSaved(String id) => saved.contains(id);

  Future<void> load() async {
    if (loaded) return;
    final prefs = await SharedPreferences.getInstance();
    saved
      ..clear()
      ..addAll(prefs.getStringList(_key) ?? const []);
    loaded = true;
    notifyListeners();
  }

  Future<void> toggle(String id) async {
    if (saved.contains(id)) {
      saved.remove(id);
    } else {
      saved.add(id);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, saved.toList());
  }
}
