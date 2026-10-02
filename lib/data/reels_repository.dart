import 'dart:convert';

import 'package:flutter/foundation.dart';
import '../models/play_reel.dart';
import 'app_api.dart';

class ReelsRepository extends ChangeNotifier {
  ReelsRepository._();
  static final ReelsRepository instance = ReelsRepository._();

  List<PlayReel> items = const [];
  bool loaded = false;
  String? error;

  Future<void> load() async {
    if (loaded) return;
    try {
      final uri = AppApi.uri('/reels');
      final res = await AppApi.get(uri);
      if (res.statusCode != 200) {
        throw Exception('Reels API ${res.statusCode}');
      }
      final map = jsonDecode(res.body) as Map<String, dynamic>;
      final list = map['items'] as List<dynamic>? ?? const [];
      items = [
        for (final item in list) PlayReel.fromJson(item as Map<String, dynamic>),
      ];
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      loaded = true;
      notifyListeners();
    }
  }
}
