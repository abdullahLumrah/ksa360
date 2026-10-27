import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_api.dart';
import 'auth_session.dart';

/// Local + server list of users/ads the current person has blocked.
/// Hides their UGC immediately, then notifies the developer via the report channel.
class BlockStore extends ChangeNotifier {
  BlockStore._();
  static final BlockStore instance = BlockStore._();

  final Set<String> _ids = {};
  final Set<String> _adIds = {};
  bool loaded = false;

  String get _uid => AuthSession.instance.user?.id ?? '';

  String get _usersKey => 'ugc.blocked_user_ids.${_uid.isEmpty ? 'guest' : _uid}';

  String get _adsKey => 'ugc.blocked_ad_ids.${_uid.isEmpty ? 'guest' : _uid}';

  Set<String> get ids => Set.unmodifiable(_ids);

  /// Catalog listings (Haraj / Expat) share one seller id. Blocking that
  /// must not wipe the whole Marketplace.
  static bool isAppUserId(String? id) {
    final value = (id ?? '').trim();
    if (value.isEmpty || value == 'unknown') return false;
    if (value.contains(':')) return false;
    return true;
  }

  bool isBlocked(String? userId) {
    final id = (userId ?? '').trim();
    return isAppUserId(id) && _ids.contains(id);
  }

  bool isBlockedAd(String? adId) {
    final id = (adId ?? '').trim();
    return id.isNotEmpty && _adIds.contains(id);
  }

  bool hidesListing({required String adId, required String sellerId}) {
    return isBlockedAd(adId) || isBlocked(sellerId);
  }

  List<T> hideUsers<T>(Iterable<T> items, String Function(T) userIdOf) {
    return items.where((item) => !isBlocked(userIdOf(item))).toList();
  }

  List<T> hideListings<T>(
    Iterable<T> items, {
    required String Function(T) adIdOf,
    required String Function(T) sellerIdOf,
  }) {
    return items
        .where(
          (item) => !hidesListing(adId: adIdOf(item), sellerId: sellerIdOf(item)),
        )
        .toList();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _ids
      ..clear()
      ..addAll(
        (prefs.getStringList(_usersKey) ?? const [])
            .where((id) => isAppUserId(id)),
      );
    _adIds
      ..clear()
      ..addAll(
        (prefs.getStringList(_adsKey) ?? const [])
            .where((id) => id.trim().isNotEmpty),
      );
    loaded = true;
    notifyListeners();
    await syncFromServer();
  }

  void resetMemory() {
    _ids.clear();
    _adIds.clear();
    loaded = false;
    notifyListeners();
  }

  Future<void> syncFromServer() async {
    if (!AuthSession.instance.isSignedIn) return;
    try {
      final res = await AppApi.get(AppApi.uri('/communities/blocks'));
      if (res.statusCode != 200) return;
      final body = jsonDecode(res.body);
      if (body is! Map) return;
      final users = (body['ids'] as List? ?? [])
          .map((item) => item.toString().trim())
          .where(isAppUserId);
      final ads = (body['adIds'] as List? ?? body['ad_ids'] as List? ?? [])
          .map((item) => item.toString().trim())
          .where((id) => id.isNotEmpty);
      var changed = false;
      for (final id in users) {
        if (_ids.add(id)) changed = true;
      }
      for (final id in ads) {
        if (_adIds.add(id)) changed = true;
      }
      if (changed) {
        await _persist();
        notifyListeners();
      }
    } catch (_) {
      // Local list still applies.
    }
  }

  /// Adds the id locally first so feeds hide instantly, then tells the API.
  Future<void> block({
    required String userId,
    String adId = '',
    String reason = 'Block user',
    String details = '',
    String targetType = 'user',
    String targetId = '',
    String communityId = '',
  }) async {
    final id = userId.trim();
    final listingId = adId.trim();
    final catalog = listingId.isNotEmpty && !isAppUserId(id);
    if (id.isEmpty && listingId.isEmpty) {
      throw Exception('Could not block this user.');
    }
    if (isAppUserId(id) && id == AuthSession.instance.user?.id) {
      throw Exception('You cannot block yourself.');
    }
    var changed = false;
    if (isAppUserId(id) && _ids.add(id)) changed = true;
    if (catalog && _adIds.add(listingId)) changed = true;
    if (changed) {
      await _persist();
      notifyListeners();
    }
    final res = await AppApi.post(
      AppApi.uri('/communities/blocks'),
      body: jsonEncode({
        if (isAppUserId(id)) 'userId': id,
        if (listingId.isNotEmpty) 'adId': listingId,
        'reason': reason,
        'details': details,
        'targetType': catalog ? 'souq_ad' : targetType,
        'targetId': catalog
            ? listingId
            : (targetId.isNotEmpty ? targetId : id),
        if (communityId.isNotEmpty) 'communityId': communityId,
      }),
    );
    if (res.statusCode == 401) {
      throw Exception('Sign in to block a user.');
    }
    if (res.statusCode >= 400 && res.statusCode != 409) {
      dynamic body;
      try {
        body = jsonDecode(res.body);
      } catch (_) {
        body = null;
      }
      throw Exception(
        body is Map
            ? (body['error'] ?? 'Could not notify the team.')
            : 'Could not notify the team.',
      );
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_usersKey, _ids.toList());
    await prefs.setStringList(_adsKey, _adIds.toList());
  }
}
