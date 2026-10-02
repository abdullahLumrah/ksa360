import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../data/app_api.dart';
import '../../../data/app_api_config.dart';
import '../domain/souq_models.dart';

class SouqApi {
  static String mediaUrl(String path) {
    final value = path.trim();
    if (value.isEmpty) return value;
    if (value.startsWith('/uploads/')) {
      return '${AppApiConfig.baseUrl}$value';
    }
    return value;
  }

  static Ad parseAd(Map<String, dynamic> json) {
    final images = ((json['images'] as List?) ?? const [])
        .map((e) => mediaUrl('$e'))
        .where((e) => e.isNotEmpty)
        .toList();
    final rawStatus = '${json['status'] ?? ''}';
    return Ad.fromJson({
      ...json,
      'id': json['id'] ?? json['ad_id'] ?? json['adId'],
      'images': images,
      'video': mediaUrl('${json['video'] ?? ''}'),
      'subtitle': json['subtitle'] ?? '',
      'status': _statusName(rawStatus),
      'condition': _conditionName('${json['condition'] ?? ''}'),
    });
  }

  static String _statusName(String raw) {
    switch (raw) {
      case 'awaiting_approval':
      case 'awaitingApproval':
        return AdStatus.awaitingApproval.name;
      case 'pending':
        return AdStatus.pending.name;
      case 'approved':
      case 'active':
        return AdStatus.approved.name;
      case 'declined':
        return AdStatus.declined.name;
      case 'draft':
        return AdStatus.draft.name;
      case 'sold':
        return AdStatus.sold.name;
      case 'expired':
        return AdStatus.expired.name;
      case 'paused':
        return AdStatus.paused.name;
      default:
        return AdStatus.approved.name;
    }
  }

  static String _conditionName(String raw) {
    for (final value in AdCondition.values) {
      if (value.name == raw) return raw;
    }
    return AdCondition.good.name;
  }

  static Map<String, String> _filters(SearchFilters filters, {int? page, int? pageSize}) {
    return {
      if (filters.query.trim().isNotEmpty) 'q': filters.query.trim(),
      if (filters.categoryId != null && filters.categoryId!.isNotEmpty)
        'category': filters.categoryId!,
      if (filters.subcategoryId != null && filters.subcategoryId!.isNotEmpty)
        'subcategory': filters.subcategoryId!,
      if ('${filters.attributes['bodyType'] ?? ''}'.trim().isNotEmpty &&
          (filters.subcategoryId == null || filters.subcategoryId!.isEmpty))
        'bodyType': '${filters.attributes['bodyType']}',
      if ('${filters.attributes['make'] ?? filters.attributes['brand'] ?? ''}'
          .trim()
          .isNotEmpty) ...{
        'make':
            '${filters.attributes['make'] ?? filters.attributes['brand']}'.trim(),
        'brand':
            '${filters.attributes['make'] ?? filters.attributes['brand']}'.trim(),
      },
      if (filters.cities.isNotEmpty) 'city': filters.cities.first,
      if (filters.minPrice != null) 'minPrice': '${filters.minPrice}',
      if (filters.maxPrice != null) 'maxPrice': '${filters.maxPrice}',
      if (filters.photosOnly) 'photosOnly': '1',
      'sort': filters.sort.name,
      if (page != null) 'page': '$page',
      if (pageSize != null) 'limit': '$pageSize',
    };
  }

  static Future<PagedAds> search(
    SearchFilters filters, {
    int page = 0,
    int pageSize = 20,
  }) async {
    final res = await AppApi.get(
      AppApi.uri('/souq/ads', _filters(filters, page: page, pageSize: pageSize)),
    );
    final data = _json(res);
    final items = ((data['items'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => parseAd(Map<String, dynamic>.from(e)))
        .toList();
    return PagedAds(items: items, total: data['total'] as int? ?? items.length);
  }

  static Future<int> count(SearchFilters filters) async {
    final page = await search(filters, page: 0, pageSize: 1);
    return page.total;
  }

  static Future<Ad?> byId(String id) async {
    final res = await AppApi.get(AppApi.uri('/souq/ads/${Uri.encodeComponent(id)}'));
    if (res.statusCode == 404) return null;
    return parseAd(_json(res));
  }

  static Future<List<Ad>> list({
    String? category,
    String? city,
    int limit = 20,
    String sort = 'newest',
  }) async {
    final page = await search(
      SearchFilters(
        categoryId: category,
        cities: city == null || city.isEmpty ? const [] : [city],
        sort: AdSort.values.firstWhere((e) => e.name == sort, orElse: () => AdSort.newest),
      ),
      pageSize: limit,
    );
    return page.items;
  }

  static Future<List<String>> makes() async {
    final res = await AppApi.get(AppApi.uri('/souq/makes'));
    final data = _json(res);
    return ((data['items'] as List?) ?? const []).map((e) => '$e').toList();
  }

  static Future<PriceInsight?> priceInsight({
    required String make,
    String? model,
    int? year,
  }) async {
    final res = await AppApi.get(
      AppApi.uri('/souq/price-insight', {
        'make': make,
        if (model != null && model.isNotEmpty) 'model': model,
        if (year != null) 'year': '$year',
      }),
    );
    final data = _json(res);
    final insight = data['insight'];
    if (insight is! Map) return null;
    return PriceInsight(
      low: (insight['low'] as num).toDouble(),
      high: (insight['high'] as num).toDouble(),
      sample: insight['sample'] as int? ?? 0,
    );
  }

  static Future<List<Ad>> mine() async {
    final res = await AppApi.get(AppApi.uri('/souq/mine'));
    if (res.statusCode == 401) return const [];
    final data = _json(res);
    return ((data['items'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => parseAd(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<Ad> create(Ad ad, {String? videoPath}) async {
    final files = <http.MultipartFile>[];
    for (final path in ad.images) {
      if (path.startsWith('http') || path.startsWith('/uploads/')) continue;
      final file = File(path);
      if (!file.existsSync()) continue;
      files.add(
        await http.MultipartFile.fromPath(
          'images',
          file.path,
          contentType: _mediaType(file.path),
        ),
      );
    }
    if (videoPath != null && videoPath.isNotEmpty && File(videoPath).existsSync()) {
      files.add(
        await http.MultipartFile.fromPath(
          'video',
          videoPath,
          contentType: _mediaType(videoPath),
        ),
      );
    }
    final res = await AppApi.postMultipart(
      AppApi.uri('/souq/ads'),
      fields: {
        'title': ad.title,
        'subtitle': ad.subtitle,
        'description': ad.description,
        'categoryId': ad.categoryId,
        if (ad.subcategoryId != null) 'subcategoryId': ad.subcategoryId!,
        if (ad.price != null) 'price': '${ad.price}',
        'isNegotiable': '${ad.isNegotiable}',
        'city': ad.city,
        if (ad.district != null) 'district': ad.district!,
        if (ad.seller.phone != null) 'phone': ad.seller.phone!,
        'condition': ad.condition.name,
        'attributes': jsonEncode(ad.attributes),
        'contact': jsonEncode(ad.contact.toJson()),
      },
      files: files,
    );
    return parseAd(_json(res));
  }

  static SouqConversation parseChat(Map<String, dynamic> json) {
    return SouqConversation.fromJson(json);
  }

  static Future<List<SouqConversation>> chats({String? adId}) async {
    final res = await AppApi.get(
      AppApi.uri('/souq/chats', {
        if (adId != null && adId.isNotEmpty) 'adId': adId,
      }),
    );
    if (res.statusCode == 401) return const [];
    final data = _json(res);
    return ((data['items'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => parseChat(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<SouqConversation> chat(String conversationId) async {
    final res = await AppApi.get(
      AppApi.uri('/souq/chats/${Uri.encodeComponent(conversationId)}'),
    );
    return parseChat(_json(res));
  }

  static Future<SouqConversation> openChat(String adId, {String? message}) async {
    final res = await AppApi.post(
      AppApi.uri('/souq/chats'),
      body: jsonEncode({
        'adId': adId,
        if (message != null && message.trim().isNotEmpty) 'message': message.trim(),
      }),
    );
    return parseChat(_json(res));
  }

  static Future<SouqConversation> sendMessage(
    String conversationId,
    String text,
  ) async {
    final res = await AppApi.post(
      AppApi.uri('/souq/chats/${Uri.encodeComponent(conversationId)}/messages'),
      body: jsonEncode({'text': text}),
    );
    return parseChat(_json(res));
  }

  static Future<List<Ad>> bySeller(String sellerId) async {
    final res = await AppApi.get(
      AppApi.uri('/souq/ads', {'seller': sellerId, 'limit': '50'}),
    );
    final data = _json(res);
    return ((data['items'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => parseAd(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<({List<String> ids, List<Ad> items})> favorites() async {
    final res = await AppApi.get(AppApi.uri('/souq/favorites'));
    if (res.statusCode == 401) {
      return (ids: const <String>[], items: const <Ad>[]);
    }
    final data = _json(res);
    return (
      ids: ((data['ids'] as List?) ?? const []).map((e) => '$e').toList(),
      items: ((data['items'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => parseAd(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  static Future<({List<String> ids, bool favorited, int count})> toggleFavorite(
    String id,
  ) async {
    final res = await AppApi.post(
      AppApi.uri('/souq/favorites/${Uri.encodeComponent(id)}'),
    );
    final data = _json(res);
    return (
      ids: ((data['ids'] as List?) ?? const []).map((e) => '$e').toList(),
      favorited: data['favorited'] as bool? ?? false,
      count: (data['count'] as num?)?.toInt() ?? 0,
    );
  }

  static Future<Ad> patch(String id, Map<String, dynamic> body) async {
    final res = await AppApi.patch(
      AppApi.uri('/souq/ads/${Uri.encodeComponent(id)}'),
      body: jsonEncode(body),
    );
    return parseAd(_json(res));
  }

  static Future<void> delete(String id) async {
    final res = await AppApi.delete(AppApi.uri('/souq/ads/${Uri.encodeComponent(id)}'));
    if (res.statusCode >= 400) {
      throw Exception(_error(res));
    }
  }

  static Map<String, dynamic> _json(http.Response res) {
    if (res.statusCode >= 400) {
      throw Exception(_error(res));
    }
    final body = jsonDecode(res.body);
    if (body is Map<String, dynamic>) return body;
    throw Exception('Unexpected Souq response');
  }

  static MediaType _mediaType(String path) {
    switch (path.split('.').last.toLowerCase()) {
      case 'png':
        return MediaType('image', 'png');
      case 'webp':
        return MediaType('image', 'webp');
      case 'gif':
        return MediaType('image', 'gif');
      case 'heic':
        return MediaType('image', 'heic');
      case 'heif':
        return MediaType('image', 'heif');
      case 'mp4':
        return MediaType('video', 'mp4');
      case 'mov':
        return MediaType('video', 'quicktime');
      case 'm4v':
        return MediaType('video', 'mp4');
      default:
        return MediaType('image', 'jpeg');
    }
  }

  static String _error(http.Response res) {
    try {
      final body = jsonDecode(res.body);
      if (body is Map && body['error'] != null) return '${body['error']}';
    } catch (_) {}
    return 'Souq request failed (${res.statusCode})';
  }
}
