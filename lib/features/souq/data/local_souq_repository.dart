import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/auth_session.dart';
import '../domain/souq_categories.dart';
import '../domain/souq_models.dart';
import '../domain/souq_repository.dart';
import '../presentation/souq_format.dart';
import 'souq_api.dart';

class LocalSouqRepository implements SouqRepository {
  LocalSouqRepository();

  static const _userAdsKey = 'souq_user_ads_v1';
  static const _favKey = 'souq_favs_v1';
  static const _draftKey = 'souq_draft_v1';
  static const _savedKey = 'souq_saved_v1';
  static const _meKey = 'souq_me_v1';
  static const _chatKey = 'souq_chats_v1';
  static const expireAfter = Duration(days: 30);

  final List<Ad> _preview = [];
  final List<Ad> _user = [];
  final Set<String> _favorites = {};
  final List<SavedSearch> _saved = [];
  final List<SouqConversation> _chats = [];
  AdDraft? _draft;
  late SellerInfo _me;
  SharedPreferences? _prefs;

  List<Ad> get _all => [..._user, ..._preview];

  Future<void>? _readyJob;

  @override
  Future<void> ready() {
    return _readyJob ??= _doReady();
  }

  Future<void> _doReady() async {
    _prefs = await SharedPreferences.getInstance();
    _loadLocal();
    _expireUserAds();
    await refreshMine();
    await refreshFavorites();
    await refreshChats();
    try {
      final recent = await SouqApi.list(limit: 40);
      _preview
        ..clear()
        ..addAll(recent);
    } catch (e) {
      debugPrint('Souq catalog load failed: $e');
    }
  }

  Future<void> refreshMine() async {
    if (!AuthSession.instance.isSignedIn) {
      _user.clear();
      return;
    }
    try {
      final mine = await SouqApi.mine();
      _user
        ..clear()
        ..addAll(mine);
      await _persistUsers();
    } catch (e) {
      debugPrint('Souq my ads load failed: $e');
    }
  }

  final List<Ad> _favoriteAds = [];

  Future<void> refreshFavorites() async {
    if (!AuthSession.instance.isSignedIn) return;
    try {
      final saved = await SouqApi.favorites();
      _favorites
        ..clear()
        ..addAll(saved.ids);
      _favoriteAds
        ..clear()
        ..addAll(saved.items);
      await _persistFavs();
    } catch (e) {
      debugPrint('Souq favorites load failed: $e');
    }
  }

  Future<List<Ad>> favoriteAds() async {
    await refreshFavorites();
    return List.unmodifiable(_favoriteAds);
  }

  void _loadLocal() {
    final prefs = _prefs!;
    _user
      ..clear()
      ..addAll(_decodeAds(prefs.getString(_userAdsKey)));
    _favorites
      ..clear()
      ..addAll(prefs.getStringList(_favKey) ?? const []);
    final draftRaw = prefs.getString(_draftKey);
    _draft = draftRaw == null
        ? null
        : AdDraft.fromJson(jsonDecode(draftRaw) as Map<String, dynamic>);
    _saved
      ..clear()
      ..addAll(_decodeSaved(prefs.getString(_savedKey)));
    _chats
      ..clear()
      ..addAll(_decodeChats(prefs.getString(_chatKey)));
    final session = AuthSession.instance.user;
    final meRaw = prefs.getString(_meKey);
    _me = session != null
        ? SellerInfo(
            id: session.id,
            name: session.name,
            avatar: session.avatar.isEmpty ? null : session.avatar,
            memberSince: DateTime.now(),
            isVerified: true,
          )
        : meRaw == null
            ? SellerInfo(
                id: 'me',
                name: 'You',
                memberSince: DateTime.now(),
                isVerified: true,
              )
            : SellerInfo.fromJson(jsonDecode(meRaw) as Map<String, dynamic>);
  }

  void _expireUserAds() {
    final now = DateTime.now();
    var changed = false;
    for (var i = 0; i < _user.length; i++) {
      final ad = _user[i];
      if (ad.source != AdSource.user) continue;
      if (ad.status != AdStatus.active) continue;
      final end = ad.expiresAt ?? ad.createdAt.add(expireAfter);
      if (end.isBefore(now)) {
        _user[i] = ad.copyWith(status: AdStatus.expired, expiresAt: end);
        changed = true;
      }
    }
    if (changed) _persistUsers();
  }

  List<Ad> _decodeAds(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => Ad.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  List<SavedSearch> _decodeSaved(String? raw) {
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => SavedSearch.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  List<SouqConversation> _decodeChats(String? raw) {
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map(
            (e) => SouqConversation.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _persistUsers() async {
    await _prefs?.setString(
      _userAdsKey,
      jsonEncode(_user.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _persistFavs() async {
    await _prefs?.setStringList(_favKey, _favorites.toList());
  }

  Future<void> _persistSaved() async {
    await _prefs?.setString(
      _savedKey,
      jsonEncode(_saved.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _persistChats() async {
    await _prefs?.setString(
      _chatKey,
      jsonEncode(_chats.map((e) => e.toJson()).toList()),
    );
  }

  bool _visibleInCategory(Ad ad, String? categoryId) {
    if (ad.status == AdStatus.draft || ad.status == AdStatus.paused) {
      return false;
    }
    if (categoryId == null || categoryId.isEmpty) return true;
    if (ad.categoryId != categoryId) return false;
    return true;
  }

  bool _matches(Ad ad, SearchFilters f) {
    if (ad.status == AdStatus.draft) return false;
    if (!_visibleInCategory(ad, f.categoryId)) return false;
    if (f.subcategoryId != null && ad.subcategoryId != f.subcategoryId) {
      return false;
    }
    if (f.minPrice != null && (ad.price == null || ad.price! < f.minPrice!)) {
      return false;
    }
    if (f.maxPrice != null && (ad.price == null || ad.price! > f.maxPrice!)) {
      return false;
    }
    if (f.cities.isNotEmpty &&
        !f.cities.any((c) => SouqFormat.matches(ad.city, c))) {
      return false;
    }
    if (f.condition != null && ad.condition != f.condition) return false;
    if (f.postedAfter != null && ad.createdAt.isBefore(f.postedAfter!)) {
      return false;
    }
    if (f.photosOnly && !ad.hasPhotos) return false;
    if (f.sellerType != null &&
        '${ad.attributes['sellerType'] ?? ''}' != f.sellerType) {
      return false;
    }
    for (final entry in f.attributes.entries) {
      if (entry.value == null || '${entry.value}'.isEmpty) continue;
      final got = '${ad.attributes[entry.key] ?? ''}';
      if (!SouqFormat.matches(got, '${entry.value}')) return false;
    }
    if (f.query.trim().isNotEmpty) {
      final q = f.query;
      final blob = [
        ad.title,
        ad.description,
        ad.city,
        ad.make,
        ad.model,
        ...ad.attributes.values.map((e) => '$e'),
      ].join(' ');
      if (!SouqFormat.matches(blob, q)) return false;
    }
    return true;
  }

  List<Ad> _filtered(SearchFilters f) {
    final seen = <String>{};
    final list = _all.where((a) => _matches(a, f) && seen.add(a.id)).toList();
    list.sort((a, b) {
      return switch (f.sort) {
        AdSort.newest => b.createdAt.compareTo(a.createdAt),
        AdSort.priceAsc => (a.price ?? 1e12).compareTo(b.price ?? 1e12),
        AdSort.priceDesc => (b.price ?? -1).compareTo(a.price ?? -1),
        AdSort.mileageDesc => (b.mileage ?? -1).compareTo(a.mileage ?? -1),
        AdSort.yearDesc => (b.year ?? -1).compareTo(a.year ?? -1),
      };
    });
    return list;
  }

  @override
  Future<PagedAds> search(
    SearchFilters filters, {
    int page = 0,
    int pageSize = 20,
  }) {
    return SouqApi.search(filters, page: page, pageSize: pageSize);
  }

  @override
  Future<int> count(SearchFilters filters) => SouqApi.count(filters);

  @override
  Future<Ad?> byId(String id) async {
    try {
      final remote = await SouqApi.byId(id);
      if (remote != null) {
        _syncMine(remote);
        return remote;
      }
    } catch (_) {}
    for (final ad in _all) {
      if (ad.id == id) return ad;
    }
    return null;
  }

  void _syncMine(Ad remote) {
    final ui = _user.indexWhere((a) => a.id == remote.id);
    if (ui < 0) return;
    _user[ui] = _user[ui].copyWith(
      views: remote.views,
      status: remote.status,
      favoritesCount: remote.favoritesCount,
    );
    _persistUsers();
  }

  @override
  Future<List<Ad>> featuredCars({int limit = 8}) {
    return SouqApi.list(category: 'cars', limit: limit, sort: 'priceDesc');
  }

  @override
  Future<List<Ad>> recentlyAdded({int limit = 24}) {
    return SouqApi.list(limit: limit);
  }

  @override
  Future<List<Ad>> nearCity(String city, {int limit = 12}) {
    return SouqApi.list(city: city, limit: limit);
  }

  @override
  Future<List<Ad>> similarTo(Ad ad, {int limit = 8}) async {
    final page = await SouqApi.search(
      SearchFilters(categoryId: ad.categoryId),
      pageSize: limit + 4,
    );
    return page.items.where((item) => item.id != ad.id).take(limit).toList();
  }

  @override
  Future<List<Ad>> bySeller(String sellerId) async {
    if (AuthSession.instance.user?.id == sellerId) {
      await refreshMine();
      return List.of(_user);
    }
    return SouqApi.bySeller(sellerId);
  }

  @override
  Future<List<String>> makes() => SouqApi.makes();

  @override
  Future<PriceInsight?> priceInsight({
    required String make,
    String? model,
    int? year,
  }) {
    return SouqApi.priceInsight(make: make, model: model, year: year);
  }

  @override
  Future<List<double>> priceHistogram(SearchFilters filters) async {
    final page = await SouqApi.search(filters, pageSize: 50);
    return page.items
        .where((ad) => ad.price != null)
        .map((ad) => ad.price!)
        .toList();
  }

  List<Ad> quickSearch(String query, {int limit = 8}) {
    return _filtered(SearchFilters(query: query)).take(limit).toList();
  }

  @override
  Future<List<String>> suggest(String query) async {
    if (query.trim().length < 2) return const [];
    final page = await SouqApi.search(
      SearchFilters(query: query),
      pageSize: 12,
    );
    final seen = <String>{};
    return [
      for (final ad in page.items)
        if (seen.add(ad.title)) ad.title,
    ];
  }

  @override
  Future<Ad> publish(Ad ad) async {
    final saved = await SouqApi.create(ad, videoPath: ad.video);
    final idx = _user.indexWhere((a) => a.id == saved.id);
    if (idx >= 0) {
      _user[idx] = saved;
    } else {
      _user.insert(0, saved);
    }
    return saved;
  }

  @override
  Future<Ad> update(Ad ad) async {
    if (ad.isImported) return ad;
    final saved = await SouqApi.patch(ad.id, {
      'title': ad.title,
      'subtitle': ad.subtitle,
      'description': ad.description,
      'city': ad.city,
      'district': ad.district,
      'price': ad.price,
      'status': ad.status.name,
      if (ad.expiresAt != null) 'expiresAt': ad.expiresAt!.toIso8601String(),
    });
    _syncMine(saved);
    return saved;
  }

  @override
  Future<void> delete(String id) async {
    await SouqApi.delete(id);
    _user.removeWhere((a) => a.id == id);
  }

  @override
  Future<void> markStatus(String id, AdStatus status) async {
    final saved = await SouqApi.patch(id, {'status': status.name});
    _syncMine(saved);
  }

  @override
  Future<void> bumpViews(String id) async {
    // Real views increment on GET /souq/ads/:id for everyone except the seller.
    try {
      final remote = await SouqApi.byId(id);
      if (remote != null) _syncMine(remote);
    } catch (_) {}
  }

  @override
  Set<String> get favoriteIds => Set.unmodifiable(_favorites);

  @override
  Future<void> toggleFavorite(String id) async {
    if (!AuthSession.instance.isSignedIn) return;
    final saved = await SouqApi.toggleFavorite(id);
    _favorites
      ..clear()
      ..addAll(saved.ids);
    await _persistFavs();
    final ui = _user.indexWhere((a) => a.id == id);
    if (ui >= 0) {
      _user[ui] = _user[ui].copyWith(favoritesCount: saved.count);
      await _persistUsers();
    }
  }

  @override
  List<Ad> get myAds => List.unmodifiable(_user);

  @override
  AdDraft? get draft => _draft;

  @override
  Future<void> saveDraft(AdDraft draft) async {
    _draft = draft;
    await _prefs?.setString(_draftKey, jsonEncode(draft.toJson()));
  }

  @override
  Future<void> clearDraft() async {
    _draft = null;
    await _prefs?.remove(_draftKey);
  }

  @override
  List<SavedSearch> get savedSearches => List.unmodifiable(_saved);

  @override
  Future<void> saveSearch(SavedSearch search) async {
    _saved.removeWhere((s) => s.id == search.id);
    _saved.insert(0, search);
    await _persistSaved();
  }

  @override
  Future<void> deleteSearch(String id) async {
    _saved.removeWhere((s) => s.id == id);
    await _persistSaved();
  }

  @override
  SellerInfo get me => _me;

  @override
  Future<void> updateMe(SellerInfo me) async {
    _me = me;
    await _prefs?.setString(_meKey, jsonEncode(me.toJson()));
  }

  @override
  List<SouqConversation> get conversations => List.unmodifiable(_chats);

  Future<void> refreshChats({String? adId}) async {
    if (!AuthSession.instance.isSignedIn) {
      _chats.clear();
      return;
    }
    try {
      final items = await SouqApi.chats(adId: adId);
      if (adId == null) {
        _chats
          ..clear()
          ..addAll(items);
      } else {
        _chats
          ..removeWhere((c) => c.adId == adId)
          ..addAll(items);
        _chats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      }
    } catch (e) {
      debugPrint('Souq chats load failed: $e');
    }
  }

  @override
  Future<SouqConversation> openChat({
    required Ad ad,
    String? firstMessage,
  }) async {
    final saved = await SouqApi.openChat(ad.id, message: firstMessage);
    final idx = _chats.indexWhere((c) => c.id == saved.id);
    if (idx >= 0) {
      _chats[idx] = saved;
    } else {
      _chats.insert(0, saved);
    }
    return saved;
  }

  @override
  Future<void> sendMessage(String conversationId, String text) async {
    final saved = await SouqApi.sendMessage(conversationId, text);
    final idx = _chats.indexWhere((c) => c.id == saved.id);
    if (idx >= 0) {
      _chats[idx] = saved;
    } else {
      _chats.insert(0, saved);
    }
  }
}
