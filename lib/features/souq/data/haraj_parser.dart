import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../domain/souq_models.dart';
import '../presentation/souq_format.dart';

/// Maps bundled Haraj JSON (Excel sample or GraphQL scrape) into [Ad] maps.
class HarajParser {
  static const assetPath = 'assets/data/haraj_cars.json.gz';
  static const assetPathJson = 'assets/data/haraj_cars.json';

  static const makesAr = {
    'تويوتا': 'Toyota',
    'هيونداي': 'Hyundai',
    'هيونداى': 'Hyundai',
    'نيسان': 'Nissan',
    'لكزس': 'Lexus',
    'فورد': 'Ford',
    'شفروليه': 'Chevrolet',
    'شيفروليه': 'Chevrolet',
    'كيا': 'Kia',
    'مرسيدس': 'Mercedes',
    'بي ام دبليو': 'BMW',
    'بي إم دبليو': 'BMW',
    'جي ام سي': 'GMC',
    'هوندا': 'Honda',
    'مازدا': 'Mazda',
    'ايسوزو': 'Isuzu',
    'إيسوزو': 'Isuzu',
    'جيب': 'Jeep',
    'فولكس واجن': 'Volkswagen',
    'فولكسفاغن': 'Volkswagen',
    'دودج': 'Dodge',
    'ميتسوبيشي': 'Mitsubishi',
    'بورشه': 'Porsche',
    'اودي': 'Audi',
    'هافال': 'Haval',
    'شيري': 'Chery',
    'جينيسيس': 'Genesis',
    'كاديلاك': 'Cadillac',
    'انفينيتي': 'Infiniti',
    'رنج روفر': 'Land Rover',
    'لاند روفر': 'Land Rover',
  };

  static const cities = {
    'الرياض': 'Riyadh',
    'riyadh': 'Riyadh',
    'جدة': 'Jeddah',
    'جده': 'Jeddah',
    'jeddah': 'Jeddah',
    'الدمام': 'Dammam',
    'dammam': 'Dammam',
    'مكة': 'Makkah',
    'مكه': 'Makkah',
    'makkah': 'Makkah',
    'mecca': 'Makkah',
    'المدينة': 'Madinah',
    'المدينه': 'Madinah',
    'madinah': 'Madinah',
    'medina': 'Madinah',
    'تبوك': 'Tabuk',
    'tabuk': 'Tabuk',
    'خميس مشيط': 'Khamis Mushait',
    'khamis mushait': 'Khamis Mushait',
    'الجبيل': 'Al Jubail',
    'al jubail': 'Al Jubail',
    'jubail': 'Al Jubail',
    'الطائف': 'Taif',
    'taif': 'Taif',
    'بريدة': 'Buraidah',
    'buraidah': 'Buraidah',
    'حائل': 'Hail',
    'hail': 'Hail',
    'الخرج': 'Al Kharj',
    'al kharj': 'Al Kharj',
    'الدرعية': 'Diriyah',
    'diriyah': 'Diriyah',
    'نجران': 'Najran',
    'najran': 'Najran',
    'حفر الباطن': 'Hafr Al-Batin',
    'hafr al-batin': 'Hafr Al-Batin',
    'الزلفي': 'Zulfi',
    'zulfi': 'Zulfi',
    'ضرما': 'Dhurma',
    'dhurma': 'Dhurma',
    'بلسمر': 'Balasmar',
    'balasmar': 'Balasmar',
    'الدلم': 'Al Dilam',
    'al dilam': 'Al Dilam',
    'صفوى': 'Safwa',
    'safwa': 'Safwa',
    'الضرية': 'Dhariyah',
    'dhariyah': 'Dhariyah',
  };

  static List<Map<String, dynamic>> parseAssetJson(String raw) {
    final decoded = jsonDecode(raw);
    final listings = <dynamic>[];
    if (decoded is List) {
      listings.addAll(decoded);
    } else if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);
      final inner = map['listings'] ?? map['data'] ?? map['ads'] ?? map['cars'];
      if (inner is List) listings.addAll(inner);
    }
    final seen = <String>{};
    final out = <Map<String, dynamic>>[];
    final scrapedAt = DateTime.tryParse(
          decoded is Map ? '${decoded['scraped_at'] ?? ''}' : '',
        ) ??
        DateTime(2026, 10, 1);

    for (var i = 0; i < listings.length; i++) {
      final item = listings[i];
      if (item is! Map) continue;
      final rec = _asStringKeyed(item);
      final ad = fromRecord(rec, index: i, scrapedAt: scrapedAt);
      if (ad == null) continue;
      final key = ad.id;
      if (seen.contains(key)) continue;
      seen.add(key);
      out.add(ad.toJson());
    }
    return out;
  }

  static Ad? fromRecord(
    Map<String, dynamic> rec, {
    int index = 0,
    DateTime? scrapedAt,
  }) {
    final id = _first(rec, const [
          'Haraj ad ID',
          'haraj_ad_id',
          'id',
          'ad_id',
          'url',
        ])
        ?.toString()
        .trim();
    if (id == null || id.isEmpty || id == 'null') return null;

    final brandRaw = _first(rec, const ['Brand', 'brand', 'make', 'Make']);
    final modelRaw = _first(rec, const ['Model', 'model']);
    final titleRaw = _first(rec, const ['title', 'Title', 'name']);
    var make = _clean(brandRaw);
    var model = _clean(modelRaw);
    final titleSource = _clean(titleRaw) ?? '';
    if ((make == null || make.isEmpty) && titleSource.isNotEmpty) {
      make = extractMake(titleSource);
    }
    if ((model == null || model.isEmpty) && titleSource.isNotEmpty) {
      model = extractModel(titleSource, make);
    }

    final nestedPrice = rec['price'];
    final carInfo = rec['carInfo'] is Map
        ? Map<String, dynamic>.from(rec['carInfo'] as Map)
        : const <String, dynamic>{};
    final year = _year(
      _first(rec, const ['Year', 'year', 'model_year']) ?? carInfo['model'],
    );
    final city = normalizeCity(
      _clean(_first(rec, const ['City', 'city', 'location', 'geoCity'])) ?? '',
    );
    final price = SouqFormat.parsePrice(
      nestedPrice is Map
          ? (nestedPrice['inputPrice'] ?? nestedPrice['formattedPrice'])
          : _first(rec, const ['Price (SAR)', 'price', 'priceText', 'Price', 'cost']),
    );
    final type = _clean(
          _first(rec, const ['Type / condition', 'condition', 'type', 'status']) ??
              carInfo['condition'],
        ) ??
        '';

    final body = inferBodyType(model, type);
    final condition = inferCondition(type);
    final sellerType = type.toLowerCase().contains('dealer') ? 'Dealer' : 'Owner';
    final title = _title(make, model, year, titleSource);
    final negotiable = price == null;
    final when = _postedAt(rec, scrapedAt, index);
    final url = _absoluteUrl(
      _clean(_first(rec, const ['url', 'URL', 'link'])),
      id,
    );
    final images = _images(rec);
    final author =
        _clean(_first(rec, const ['author', 'authorUsername'])) ?? 'Haraj seller';
    final desc = _clean(_first(rec, const ['body', 'bodyTEXT', 'description'])) ??
        _description(make, model, year, city, type, price);
    final mileage = _asInt(rec['mileage'] ?? carInfo['mileage']);
    final fuel = _fuel(_clean(rec['fuel'] ?? carInfo['fuel']));
    final gear = _gear(_clean(rec['gear'] ?? carInfo['gear']));

    return Ad(
      id: 'haraj-$id',
      source: AdSource.haraj,
      categoryId: 'cars',
      subcategoryId: body,
      title: title,
      description: desc,
      price: price,
      isNegotiable: negotiable,
      condition: condition,
      images: images,
      city: city.isEmpty ? 'Saudi Arabia' : city,
      attributes: {
        if (make != null) 'make': make,
        if (model != null) 'model': model,
        if (year != null) 'year': year,
        if (mileage != null) 'mileage': mileage <= 400 ? mileage * 1000 : mileage,
        if (fuel != null) 'fuel': fuel,
        if (gear != null) 'transmission': gear,
        'bodyType': _bodyLabel(body),
        'sellerType': sellerType,
        'origin': 'Saudi',
        if (type.isNotEmpty) 'listingType': type,
      },
      seller: SellerInfo(
        id: 'haraj-$id',
        name: author,
        memberSince: DateTime(2020),
        isVerified: false,
      ),
      contact: const ContactPreference(
        call: false,
        whatsapp: false,
        chat: false,
        hidePhone: true,
      ),
      status: AdStatus.active,
      createdAt: when,
      isFeatured: index < 8 && price != null && images.isNotEmpty,
      originalUrl: url,
    );
  }

  static String? extractMake(String title) {
    final n = SouqFormat.normalizeSearch(title);
    for (final entry in makesAr.entries) {
      if (n.contains(SouqFormat.normalizeSearch(entry.key)) ||
          n.contains(entry.value.toLowerCase())) {
        return entry.value;
      }
    }
    const en = [
      'Toyota',
      'Hyundai',
      'Nissan',
      'Lexus',
      'Ford',
      'Chevrolet',
      'Kia',
      'Mercedes',
      'BMW',
      'GMC',
      'Honda',
      'Mazda',
      'Isuzu',
      'Jeep',
      'Volkswagen',
      'Dodge',
      'Mitsubishi',
      'Land Rover',
      'Porsche',
      'Audi',
      'Haval',
      'Infiniti',
      'Changan',
      'Cadillac',
      'Genesis',
      'Chery',
      'Geely',
      'Suzuki',
      'Renault',
      'Peugeot',
      'Great Wall',
      'Jetour',
      'GAC',
      'BYD',
      'MG',
    ];
    for (final m in en) {
      if (n.contains(m.toLowerCase())) return m;
    }
    return null;
  }

  static String? extractModel(String title, String? make) {
    var t = title;
    if (make != null) {
      t = t.replaceAll(RegExp(make, caseSensitive: false), '');
      for (final e in makesAr.entries) {
        if (e.value == make) t = t.replaceAll(e.key, '');
      }
    }
    t = SouqFormat.westernDigits(t).replaceAll(RegExp(r'\b(19|20)\d{2}\b'), '');
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    return t.isEmpty ? null : t;
  }

  static String normalizeCity(String raw) {
    final n = SouqFormat.normalizeSearch(raw);
    return cities[n] ??
        cities[raw.trim().toLowerCase()] ??
        (raw.trim().isEmpty ? '' : raw.trim());
  }

  static String inferBodyType(String? model, String type) {
    final t = '${model ?? ''} $type'.toLowerCase();
    if (t.contains('part') || t.contains('spare')) return 'parts';
    if (RegExp(
          r'silverado|f-?150|f-?250|ranger|hilux|tundra|canyon|d-?max|navara|frontier',
        ).hasMatch(t) ||
        t.contains('truck') ||
        t.contains('pickup')) {
      return 'pickup';
    }
    if (RegExp(r'mustang|camaro|challenger|supra|86|coupe').hasMatch(t)) {
      return 'coupe';
    }
    if (RegExp(r'carnival|staria|hiace|urvan|transit|van|bus').hasMatch(t)) {
      return 'van';
    }
    if (RegExp(
      r'tahoe|suburban|expedition|explorer|edge|land cruiser|prado|patrol|fortuner|rav4|highlander|4runner|pajero|sportage|tucson|santa fe|palisade|telluride|sorento|seltos|stonic|niro|rx|gx|lx|nx|ux|cx-|pathfinder|armada|murano|kicks|xterra|grand cherokee|wrangler|compass',
    ).hasMatch(t)) {
      return 'suv';
    }
    if (RegExp(r'yaris|spark|polo|fiesta|accent hatch').hasMatch(t)) {
      return 'hatchback';
    }
    return 'sedan';
  }

  static AdCondition inferCondition(String type) {
    final t = type.toLowerCase();
    if (t.contains('part') || t.contains('damaged') || t.contains('damg') || t.contains('تشليح')) {
      return AdCondition.forParts;
    }
    if (t.contains('new')) return AdCondition.brandNew;
    if (t.contains('like')) return AdCondition.likeNew;
    return AdCondition.good;
  }

  static String _title(String? make, String? model, int? year, String fallback) {
    final parts = <String>[
      if (make != null && make.isNotEmpty) make,
      if (model != null && model.isNotEmpty) model,
      if (year != null) '$year',
    ];
    if (parts.isNotEmpty) return parts.join(' ');
    if (fallback.isNotEmpty) return fallback;
    return 'Car listing';
  }

  static String _description(
    String? make,
    String? model,
    int? year,
    String city,
    String type,
    double? price,
  ) {
    final bits = <String>[
      if (make != null) make,
      if (model != null) model,
      if (year != null) '$year',
      if (city.isNotEmpty) 'in $city',
    ];
    final head = bits.isEmpty ? 'Used car listed on Haraj' : bits.join(' ');
    final cond = type.isEmpty ? 'Used' : type;
    final offer = price == null ? 'Price on request (best offer).' : '';
    return '$head. Condition: $cond. Listed on Haraj. $offer'.trim();
  }

  static String _bodyLabel(String id) {
    return switch (id) {
      'suv' => 'SUV',
      'pickup' => 'Pickup',
      'hatchback' => 'Hatchback',
      'coupe' => 'Coupe',
      'van' => 'Van/Bus',
      'classic' => 'Classic',
      'parts' => 'Spare Parts',
      'accessories' => 'Accessories',
      _ => 'Sedan',
    };
  }

  static int? _year(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) {
      final y = raw.toInt();
      return (y >= 1950 && y <= 2030) ? y : null;
    }
    final s = SouqFormat.westernDigits('$raw');
    final m = RegExp(r'(19|20)\d{2}').firstMatch(s);
    if (m == null) return null;
    return int.tryParse(m.group(0)!);
  }

  static dynamic _first(Map<String, dynamic> rec, List<String> keys) {
    for (final key in keys) {
      if (rec.containsKey(key) && rec[key] != null && '${rec[key]}'.trim().isNotEmpty) {
        return rec[key];
      }
    }
    final lower = {
      for (final e in rec.entries) e.key.toLowerCase().trim(): e.value,
    };
    for (final key in keys) {
      final v = lower[key.toLowerCase()];
      if (v != null && '$v'.trim().isNotEmpty) return v;
    }
    return null;
  }

  static String? _clean(dynamic v) {
    if (v == null) return null;
    final s = '$v'.trim();
    if (s.isEmpty || s == 'null' || s == 'None') return null;
    return s;
  }

  static Map<String, dynamic> _asStringKeyed(Map raw) {
    return {
      for (final e in raw.entries) '${e.key}': e.value,
    };
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(SouqFormat.westernDigits('$v'));
  }

  static DateTime _postedAt(
    Map<String, dynamic> rec,
    DateTime? scrapedAt,
    int index,
  ) {
    final raw = rec['postDate'] ?? rec['createdAt'] ?? rec['date'];
    if (raw is num) {
      final n = raw.toInt();
      if (n > 1000000000 && n < 20000000000) {
        return DateTime.fromMillisecondsSinceEpoch(n * 1000);
      }
    }
    final parsed = DateTime.tryParse('$raw');
    if (parsed != null) return parsed;
    return (scrapedAt ?? DateTime.now()).subtract(Duration(minutes: index * 17));
  }

  static String _absoluteUrl(String? url, String id) {
    if (url == null || url.isEmpty) return 'https://haraj.com.sa/$id';
    if (url.startsWith('http')) return url;
    return 'https://haraj.com.sa/${url.replaceFirst(RegExp(r'^/+'), '')}';
  }

  static List<String> _images(Map<String, dynamic> rec) {
    final out = <String>[];
    final raw = rec['images'] ?? rec['imagesList'];
    if (raw is List) {
      for (final item in raw) {
        final url = _imageUrl('$item');
        if (url != null) out.add(url);
      }
    }
    final thumb = rec['thumb'] ?? rec['thumbURL'];
    if (out.isEmpty && thumb != null) {
      final url = _imageUrl('$thumb');
      if (url != null) out.add(url);
    }
    return out;
  }

  static String? _imageUrl(String raw) {
    final s = raw.trim();
    if (s.isEmpty || s == 'null') return null;
    if (s.startsWith('http')) return s;
    return 'https://thumbcdn.haraj.com.sa/$s';
  }

  static String? _gear(String? raw) {
    if (raw == null) return null;
    final n = raw.toLowerCase();
    if (n.contains('auto') || n.contains('اوتم')) return 'Automatic';
    if (n.contains('man') || n.contains('عادي')) return 'Manual';
    return raw;
  }

  static String? _fuel(String? raw) {
    if (raw == null) return null;
    switch (raw.toUpperCase()) {
      case 'GASOLINE':
      case 'PETROL':
        return 'Petrol';
      case 'DIESEL':
        return 'Diesel';
      case 'HYBRID':
        return 'Hybrid';
      case 'ELECTRIC':
        return 'Electric';
      default:
        return raw;
    }
  }
}

/// Isolate entry — gzip bytes from the bundled asset.
List<Map<String, dynamic>> parseHarajGzipIsolate(Uint8List bytes) {
  final raw = utf8.decode(gzip.decode(bytes));
  return HarajParser.parseAssetJson(raw);
}

/// Isolate entry — uncompressed JSON string.
List<Map<String, dynamic>> parseHarajIsolate(String raw) {
  return HarajParser.parseAssetJson(raw);
}
