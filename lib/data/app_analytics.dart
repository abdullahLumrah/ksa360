import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_api.dart';

class AppAnalytics {
  AppAnalytics._();
  static final instance = AppAnalytics._();

  static const _deviceKey = 'analytics.device_id';
  String? _deviceId;
  String _lastKey = '';
  DateTime? _lastAt;

  Future<String> deviceId() async {
    if (_deviceId != null && _deviceId!.isNotEmpty) return _deviceId!;
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_deviceKey);
    if (id == null || id.isEmpty) {
      id = 'dev_${DateTime.now().microsecondsSinceEpoch.toRadixString(16)}';
      await prefs.setString(_deviceKey, id);
    }
    _deviceId = id;
    return id;
  }

  Future<void> log({
    required String event,
    String section = '',
    String category = '',
    String targetId = '',
    String targetTitle = '',
    String path = '',
  }) async {
    final key = '$event|$section|$targetId';
    final now = DateTime.now();
    if (_lastKey == key &&
        _lastAt != null &&
        now.difference(_lastAt!) < const Duration(seconds: 8)) {
      return;
    }
    _lastKey = key;
    _lastAt = now;
    try {
      final device = await deviceId();
      await AppApi.post(
        AppApi.uri('/analytics/events'),
        body: jsonEncode({
          'event': event,
          'section': section,
          'category': category,
          'targetId': targetId,
          'targetTitle': targetTitle,
          'deviceId': device,
          'path': path,
        }),
      );
    } catch (e) {
      debugPrint('analytics skipped: $e');
    }
  }

  Future<void> section(String name) {
    return log(event: 'section_open', section: name, path: name);
  }

  Future<void> category(String section, String category) {
    return log(
      event: 'category_open',
      section: section,
      category: category,
      targetId: category,
      targetTitle: category,
    );
  }

  Future<void> open({
    required String section,
    required String targetId,
    String title = '',
    String category = '',
  }) {
    return log(
      event: 'item_open',
      section: section,
      category: category,
      targetId: targetId,
      targetTitle: title,
    );
  }
}
