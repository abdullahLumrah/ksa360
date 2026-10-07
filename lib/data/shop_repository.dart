import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/shop.dart';
import 'app_api.dart';
import 'app_api_config.dart';

class ShopRepository extends ChangeNotifier {
  ShopRepository._();
  static final ShopRepository instance = ShopRepository._();

  List<ShopCategory> categories = const [];
  List<ShopMerchant> merchants = const [];
  bool loaded = false;
  bool refreshing = false;
  String? refreshError;
  final _details = <String, List<ShopMerchant>>{};

  Future<void> load() async {
    if (loaded && categories.isNotEmpty) return;
    await refresh();
  }

  Future<void> refresh() async {
    refreshing = true;
    refreshError = null;
    notifyListeners();
    try {
      final uri = Uri.parse('${AppApiConfig.baseUrl}/shops');
      final res = await AppApi.get(uri);
      if (res.statusCode != 200) {
        throw Exception('Shops API ${res.statusCode}');
      }
      final map = jsonDecode(res.body) as Map<String, dynamic>;
      categories = [
        for (final item in map['categories'] as List<dynamic>? ?? const [])
          ShopCategory.fromJson(item as Map<String, dynamic>),
      ];
      merchants = [
        for (final item in map['merchants'] as List<dynamic>? ?? const [])
          ShopMerchant.fromJson(item as Map<String, dynamic>),
      ];
      _details
        ..clear()
        ..addEntries([
          for (final category in categories)
            MapEntry(
              category.id,
              [
                for (final merchant in merchants)
                  if (merchant.categories.contains(category.id)) merchant,
              ],
            ),
        ]);
      loaded = categories.isNotEmpty;
    } catch (e) {
      refreshError = e.toString();
      loaded = categories.isNotEmpty;
    } finally {
      refreshing = false;
      notifyListeners();
    }
  }

  List<ShopMerchant> previewMerchants(String categoryId, {int limit = 4}) {
    final cached = _details[categoryId];
    final source = cached != null && cached.isNotEmpty
        ? cached
        : merchants.where((item) => item.categories.contains(categoryId));
    return source.take(limit).toList();
  }

  Future<List<ShopMerchant>> merchantsFor(String categoryId) async {
    final cached = _details[categoryId];
    if (cached != null && cached.isNotEmpty) return cached;
    if (categories.isEmpty) await refresh();
    final fromCatalog = _details[categoryId];
    if (fromCatalog != null && fromCatalog.isNotEmpty) return fromCatalog;

    final uri = Uri.parse('${AppApiConfig.baseUrl}/shops').replace(
      queryParameters: {'category': categoryId},
    );
    final res = await AppApi.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Shops category API ${res.statusCode}');
    }
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    final found = [
      for (final item in map['merchants'] as List<dynamic>? ?? const [])
        ShopMerchant.fromJson(item as Map<String, dynamic>),
    ];
    _details[categoryId] = found;
    notifyListeners();
    return found;
  }

  Future<ShopSearchResult> search({
    String q = '',
    String category = '',
    String filter = '',
  }) async {
    final query = <String, String>{
      if (q.trim().isNotEmpty) 'q': q.trim(),
      if (category.isNotEmpty) 'category': category,
      if (filter.isNotEmpty) 'filter': filter,
    };
    final uri = Uri.parse('${AppApiConfig.baseUrl}/shops/search').replace(
      queryParameters: query,
    );
    final res = await AppApi.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Shops search API ${res.statusCode}');
    }
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    return ShopSearchResult.fromJson(map);
  }
}
