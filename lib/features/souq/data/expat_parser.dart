import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../domain/souq_models.dart';
import '../presentation/souq_format.dart';
import 'haraj_parser.dart';

/// Maps bundled expatriates.com Riyadh car JSON into [Ad] maps.
class ExpatParser {
  static const assetPath = 'assets/data/expat_cars.json.gz';
  static const assetPathJson = 'assets/data/expat_cars.json';

  static List<Map<String, dynamic>> parseAssetJson(String raw) {
    final decoded = jsonDecode(raw);
    final listings = <dynamic>[];
    if (decoded is List) {
      listings.addAll(decoded);
    } else if (decoded is Map) {
      final inner = decoded['listings'] ?? decoded['data'] ?? decoded['ads'];
      if (inner is List) listings.addAll(inner);
    }
    final seen = <String>{};
    final out = <Map<String, dynamic>>[];
    for (var i = 0; i < listings.length; i++) {
      final item = listings[i];
      if (item is! Map) continue;
      final rec = <String, dynamic>{
        for (final e in item.entries) '${e.key}': e.value,
      };
      final ad = fromRecord(rec, index: i);
      if (ad == null) continue;
      if (!seen.add(ad.id)) continue;
      out.add(ad.toJson());
    }
    return _collapseReposts(out);
  }

  static List<Map<String, dynamic>> _collapseReposts(
    List<Map<String, dynamic>> ads,
  ) {
    final best = <String, Map<String, dynamic>>{};
    for (final ad in ads) {
      final key = SouqFormat.normalizeSearch('${ad['title']}');
      if (key.isEmpty) continue;
      final prev = best[key];
      if (prev == null) {
        best[key] = ad;
        continue;
      }
      final prevImgs = (prev['images'] as List?)?.length ?? 0;
      final imgs = (ad['images'] as List?)?.length ?? 0;
      final prevAt = DateTime.tryParse('${prev['createdAt']}') ?? DateTime(2000);
      final at = DateTime.tryParse('${ad['createdAt']}') ?? DateTime(2000);
      if (imgs > prevImgs || (imgs == prevImgs && at.isAfter(prevAt))) {
        best[key] = ad;
      }
    }
    return best.values.toList();
  }

  static Ad? fromRecord(Map<String, dynamic> rec, {int index = 0}) {
    final id = '${rec['id'] ?? ''}'.trim();
    if (id.isEmpty || id == 'null') return null;
    final titleRaw = '${rec['title'] ?? ''}'.trim();
    if (titleRaw.isEmpty) return null;

    final parsed = _parseTitle(titleRaw);
    final make = parsed.make ?? HarajParser.extractMake(titleRaw);
    final year = parsed.year;
    var model = parsed.model;
    if (model == null || model.isEmpty) {
      model = HarajParser.extractModel(parsed.vehicle, make);
    }
    final body = HarajParser.inferBodyType(model ?? parsed.vehicle, titleRaw);
    final images = <String>[
      for (final item in (rec['images'] as List? ?? const []))
        if ('$item'.startsWith('http')) '$item'.split('?').first,
    ];
    final when = _postedAt(rec['postDate']);
    final url = '${rec['url'] ?? 'https://www.expatriates.com/cls/$id.html'}';
    final price = parsed.price ?? SouqFormat.parsePrice(titleRaw);

    return Ad(
      id: 'expat-$id',
      source: AdSource.expatriates,
      categoryId: 'cars',
      subcategoryId: body,
      title: _title(make, model, year, parsed.vehicle),
      description: parsed.rest.isEmpty ? titleRaw : parsed.rest,
      price: price,
      isNegotiable: price == null,
      condition: AdCondition.good,
      images: images,
      city: HarajParser.normalizeCity('${rec['city'] ?? 'Riyadh'}'),
      attributes: {
        if (make != null) 'make': make,
        if (model != null && model.isNotEmpty) 'model': model,
        if (year != null) 'year': year,
        if (parsed.mileage != null) 'mileage': parsed.mileage,
        if (parsed.gear != null) 'transmission': parsed.gear,
        'bodyType': body,
        'sellerType': rec['premium'] == true ? 'Dealer' : 'Owner',
        'origin': 'Saudi',
      },
      seller: SellerInfo(
        id: 'expat-$id',
        name: 'Expat seller',
        memberSince: DateTime(2020),
      ),
      contact: const ContactPreference(
        call: false,
        whatsapp: false,
        chat: false,
        hidePhone: true,
      ),
      status: AdStatus.active,
      createdAt: when,
      isFeatured: rec['premium'] == true && images.isNotEmpty && index < 12,
      originalUrl: url,
    );
  }

  static _ParsedTitle _parseTitle(String title) {
    var t = title.trim().replaceAll(RegExp(r'\s+'), ' ');
    double? price;
    final priceMatch = RegExp(
      r'^(SAR|USD|AED|BHD|QAR|KWD)?\s*([\d,]+)\s*,\s*',
      caseSensitive: false,
    ).firstMatch(t);
    if (priceMatch != null) {
      price = double.tryParse(priceMatch.group(2)!.replaceAll(',', ''));
      t = t.substring(priceMatch.end);
    }

    final parts = t
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    var vehicle = parts.isNotEmpty ? parts.first : t;
    int? year;
    String? gear;
    int? mileage;
    final restParts = <String>[];
    for (var i = 1; i < parts.length; i++) {
      final p = parts[i];
      final yearMatch = RegExp(r'^(19|20)\d{2}$').firstMatch(p);
      if (year == null && yearMatch != null) {
        year = int.tryParse(p);
        continue;
      }
      if (gear == null && RegExp(r'^(automatic|manual)$', caseSensitive: false).hasMatch(p)) {
        gear = p[0].toUpperCase() + p.substring(1).toLowerCase();
        continue;
      }
      final km = RegExp(
        r'^([\d,]+)\s*KM$',
        caseSensitive: false,
      ).firstMatch(p);
      if (mileage == null && km != null) {
        mileage = int.tryParse(km.group(1)!.replaceAll(',', ''));
        continue;
      }
      restParts.add(p);
    }

    final make = HarajParser.extractMake(vehicle);
    var model = vehicle;
    if (make != null) {
      model = vehicle.replaceAll(RegExp(make, caseSensitive: false), '').trim();
      model = model.replaceAll(RegExp(r'^great wall\s*', caseSensitive: false), '').trim();
    }
    return _ParsedTitle(
      price: price,
      vehicle: vehicle,
      make: make,
      model: model.isEmpty ? null : model,
      year: year,
      gear: gear,
      mileage: mileage,
      rest: restParts.join(', '),
    );
  }

  static String _title(String? make, String? model, int? year, String fallback) {
    final bits = [
      if (make != null) make,
      if (model != null && model.isNotEmpty) model,
      if (year != null) '$year',
    ];
    if (bits.isEmpty) return fallback;
    return bits.join(' ');
  }

  static DateTime _postedAt(dynamic raw) {
    if (raw is num) {
      final n = raw.toInt();
      if (n > 1000000000) {
        return DateTime.fromMillisecondsSinceEpoch(n * 1000);
      }
    }
    return DateTime.tryParse('$raw') ?? DateTime.now();
  }
}

class _ParsedTitle {
  const _ParsedTitle({
    this.price,
    required this.vehicle,
    this.make,
    this.model,
    this.year,
    this.gear,
    this.mileage,
    this.rest = '',
  });

  final double? price;
  final String vehicle;
  final String? make;
  final String? model;
  final int? year;
  final String? gear;
  final int? mileage;
  final String rest;
}

List<Map<String, dynamic>> parseExpatGzipIsolate(Uint8List bytes) {
  final raw = utf8.decode(gzip.decode(bytes));
  return ExpatParser.parseAssetJson(raw);
}
