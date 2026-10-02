import 'package:flutter/material.dart';

enum AdSource { haraj, expatriates, user }

enum AdCondition { brandNew, likeNew, good, fair, forParts }

enum AdStatus {
  draft,
  active,
  sold,
  expired,
  paused,
  awaitingApproval,
  pending,
  approved,
  declined,
}

enum AttributeType {
  text,
  number,
  dropdown,
  chips,
  year,
  toggle,
  range,
  color,
}

enum AdSort { newest, priceAsc, priceDesc, mileageDesc, yearDesc }

class GeoPoint {
  const GeoPoint(this.lat, this.lng);
  final double lat;
  final double lng;

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};

  factory GeoPoint.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const GeoPoint(0, 0);
    return GeoPoint(
      (json['lat'] as num?)?.toDouble() ?? 0,
      (json['lng'] as num?)?.toDouble() ?? 0,
    );
  }
}

class SellerInfo {
  const SellerInfo({
    required this.id,
    required this.name,
    this.avatar,
    this.phone,
    this.whatsapp,
    required this.memberSince,
    this.rating = 0,
    this.isVerified = false,
  });

  final String id;
  final String name;
  final String? avatar;
  final String? phone;
  final String? whatsapp;
  final DateTime memberSince;
  final double rating;
  final bool isVerified;

  SellerInfo copyWith({
    String? name,
    String? avatar,
    String? phone,
    String? whatsapp,
    double? rating,
    bool? isVerified,
  }) {
    return SellerInfo(
      id: id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      memberSince: memberSince,
      rating: rating ?? this.rating,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatar': avatar,
        'phone': phone,
        'whatsapp': whatsapp,
        'memberSince': memberSince.toIso8601String(),
        'rating': rating,
        'isVerified': isVerified,
      };

  factory SellerInfo.fromJson(Map<String, dynamic> json) {
    return SellerInfo(
      id: json['id'] as String? ?? 'unknown',
      name: json['name'] as String? ?? 'Seller',
      avatar: json['avatar'] as String?,
      phone: json['phone'] as String?,
      whatsapp: json['whatsapp'] as String?,
      memberSince: DateTime.tryParse(json['memberSince'] as String? ?? '') ??
          DateTime(2024),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }
}

class ContactPreference {
  const ContactPreference({
    this.call = true,
    this.whatsapp = true,
    this.chat = true,
    this.hidePhone = false,
  });

  final bool call;
  final bool whatsapp;
  final bool chat;
  final bool hidePhone;

  bool get hasAny => call || whatsapp || chat;

  ContactPreference copyWith({
    bool? call,
    bool? whatsapp,
    bool? chat,
    bool? hidePhone,
  }) {
    return ContactPreference(
      call: call ?? this.call,
      whatsapp: whatsapp ?? this.whatsapp,
      chat: chat ?? this.chat,
      hidePhone: hidePhone ?? this.hidePhone,
    );
  }

  Map<String, dynamic> toJson() => {
        'call': call,
        'whatsapp': whatsapp,
        'chat': chat,
        'hidePhone': hidePhone,
      };

  factory ContactPreference.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ContactPreference();
    return ContactPreference(
      call: json['call'] as bool? ?? true,
      whatsapp: json['whatsapp'] as bool? ?? true,
      chat: json['chat'] as bool? ?? true,
      hidePhone: json['hidePhone'] as bool? ?? false,
    );
  }
}

class AttributeField {
  const AttributeField({
    required this.key,
    required this.labelEn,
    required this.labelAr,
    required this.type,
    this.options = const [],
    this.unit,
    this.dependsOn,
  });

  final String key;
  final String labelEn;
  final String labelAr;
  final AttributeType type;
  final List<String> options;
  final String? unit;
  final String? dependsOn;
}

class SouqCategory {
  const SouqCategory({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.icon,
    required this.gradient,
    required this.subcategories,
    required this.fields,
    this.photoTipsEn = '',
    this.photoTipsAr = '',
    this.photosRequired = true,
  });

  final String id;
  final String nameEn;
  final String nameAr;
  final IconData icon;
  final List<Color> gradient;
  final List<SouqSubcategory> subcategories;
  final List<AttributeField> fields;
  final String photoTipsEn;
  final String photoTipsAr;
  final bool photosRequired;

  String name(bool ar) => ar ? nameAr : nameEn;

  /// Bundled still-life, same graphic language as Home category photos.
  String get imageAsset => 'assets/souq/$id.jpg';

  /// Bright caption color on the photo scrim.
  Color get accent => switch (id) {
        'cars' => const Color(0xFF4EE0D1),
        'mobiles' => const Color(0xFFFFC44D),
        'electronics' => const Color(0xFF5CE1F2),
        'furniture' => const Color(0xFFE8B86D),
        'appliances' => const Color(0xFF2DD4BF),
        'fashion' => const Color(0xFFFF7AD4),
        'realestate' => const Color(0xFFE4C48A),
        'sports' => const Color(0xFF84CC16),
        'animals' => const Color(0xFFFFB45A),
        'kids' => const Color(0xFFFFC44D),
        'books' => const Color(0xFFC4A574),
        'tools' => const Color(0xFFFF8B5C),
        'motors' => const Color(0xFFD97706),
        'services' => const Color(0xFF5EEAD4),
        _ => const Color(0xFFE4C48A),
      };

  /// Soft highlight used for glows and bilingual captions on saturated tiles.
  Color get glow => Color.lerp(accent, const Color(0xFFFFFFFF), 0.18)!;
}

class SouqSubcategory {
  const SouqSubcategory({
    required this.id,
    required this.nameEn,
    required this.nameAr,
  });

  final String id;
  final String nameEn;
  final String nameAr;
  String name(bool ar) => ar ? nameAr : nameEn;
}

class Ad {
  const Ad({
    required this.id,
    required this.source,
    required this.categoryId,
    this.subcategoryId,
    required this.title,
    this.subtitle = '',
    required this.description,
    this.video = '',
    this.price,
    this.isNegotiable = false,
    this.currency = 'SAR',
    this.condition = AdCondition.good,
    this.images = const [],
    required this.city,
    this.district,
    this.location,
    this.attributes = const {},
    required this.seller,
    this.contact = const ContactPreference(),
    this.status = AdStatus.awaitingApproval,
    this.views = 0,
    this.favoritesCount = 0,
    required this.createdAt,
    this.updatedAt,
    this.isFeatured = false,
    this.originalUrl,
    this.expiresAt,
  });

  final String id;
  final AdSource source;
  final String categoryId;
  final String? subcategoryId;
  final String title;
  final String subtitle;
  final String description;
  final String video;
  final double? price;
  final bool isNegotiable;
  final String currency;
  final AdCondition condition;
  final List<String> images;
  final String city;
  final String? district;
  final GeoPoint? location;
  final Map<String, dynamic> attributes;
  final SellerInfo seller;
  final ContactPreference contact;
  final AdStatus status;
  final int views;
  final int favoritesCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isFeatured;
  final String? originalUrl;
  final DateTime? expiresAt;

  bool get isHaraj => source == AdSource.haraj;
  bool get isExpat => source == AdSource.expatriates;
  bool get isImported =>
      source == AdSource.haraj || source == AdSource.expatriates;
  bool get isPublic =>
      status == AdStatus.approved || status == AdStatus.active;
  bool get isSold => status == AdStatus.sold;
  bool get isExpired =>
      status == AdStatus.expired ||
      (expiresAt != null && expiresAt!.isBefore(DateTime.now()));
  bool get hasPhotos => images.isNotEmpty;

  String? get make => _text(attributes['make']);
  String? get model => _text(attributes['model']);
  int? get year => _asInt(attributes['year']);
  int? get mileage => _asInt(attributes['mileage']);
  String? get transmission => _text(attributes['transmission']);
  String? get fuel => _text(attributes['fuel']);
  String? get bodyType => _text(attributes['bodyType']);
  String? get color => _text(attributes['color']);

  static String? _text(dynamic value) {
    final text = '${value ?? ''}'.trim();
    if (text.isEmpty || text == 'null') return null;
    return text;
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  Ad copyWith({
    String? title,
    String? subtitle,
    String? description,
    String? video,
    double? price,
    bool clearPrice = false,
    bool? isNegotiable,
    AdCondition? condition,
    List<String>? images,
    String? city,
    String? district,
    GeoPoint? location,
    Map<String, dynamic>? attributes,
    SellerInfo? seller,
    ContactPreference? contact,
    AdStatus? status,
    int? views,
    int? favoritesCount,
    DateTime? updatedAt,
    bool? isFeatured,
    DateTime? expiresAt,
    String? subcategoryId,
    String? categoryId,
  }) {
    return Ad(
      id: id,
      source: source,
      categoryId: categoryId ?? this.categoryId,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      video: video ?? this.video,
      price: clearPrice ? null : (price ?? this.price),
      isNegotiable: isNegotiable ?? this.isNegotiable,
      currency: currency,
      condition: condition ?? this.condition,
      images: images ?? this.images,
      city: city ?? this.city,
      district: district ?? this.district,
      location: location ?? this.location,
      attributes: attributes ?? this.attributes,
      seller: seller ?? this.seller,
      contact: contact ?? this.contact,
      status: status ?? this.status,
      views: views ?? this.views,
      favoritesCount: favoritesCount ?? this.favoritesCount,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFeatured: isFeatured ?? this.isFeatured,
      originalUrl: originalUrl,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'source': source.name,
        'categoryId': categoryId,
        'subcategoryId': subcategoryId,
        'title': title,
        'subtitle': subtitle,
        'description': description,
        'video': video,
        'price': price,
        'isNegotiable': isNegotiable,
        'currency': currency,
        'condition': condition.name,
        'images': images,
        'city': city,
        'district': district,
        'location': location?.toJson(),
        'attributes': attributes,
        'seller': seller.toJson(),
        'contact': contact.toJson(),
        'status': status.name,
        'views': views,
        'favoritesCount': favoritesCount,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'isFeatured': isFeatured,
        'originalUrl': originalUrl,
        'expiresAt': expiresAt?.toIso8601String(),
      };

  factory Ad.fromJson(Map<String, dynamic> json) {
    return Ad(
      id: json['id'] as String? ?? '',
      source: AdSource.values.firstWhere(
        (e) => e.name == json['source'],
        orElse: () => AdSource.user,
      ),
      categoryId: json['categoryId'] as String? ?? 'other',
      subcategoryId: json['subcategoryId'] as String?,
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      description: json['description'] as String? ?? '',
      video: json['video'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble(),
      isNegotiable: json['isNegotiable'] as bool? ?? false,
      currency: json['currency'] as String? ?? 'SAR',
      condition: AdCondition.values.firstWhere(
        (e) => e.name == json['condition'],
        orElse: () => AdCondition.good,
      ),
      images: (json['images'] as List?)?.map((e) => '$e').toList() ?? const [],
      city: json['city'] as String? ?? '',
      district: json['district'] as String?,
      location: json['location'] is Map
          ? GeoPoint.fromJson(Map<String, dynamic>.from(json['location'] as Map))
          : null,
      attributes: json['attributes'] is Map
          ? Map<String, dynamic>.from(json['attributes'] as Map)
          : const {},
      seller: json['seller'] is Map
          ? SellerInfo.fromJson(Map<String, dynamic>.from(json['seller'] as Map))
          : SellerInfo(
              id: 'unknown',
              name: 'Seller',
              memberSince: DateTime(2024),
            ),
      contact: ContactPreference.fromJson(
        json['contact'] is Map
            ? Map<String, dynamic>.from(json['contact'] as Map)
            : null,
      ),
      status: AdStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AdStatus.active,
      ),
      views: (json['views'] as num?)?.toInt() ?? 0,
      favoritesCount: (json['favoritesCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
      isFeatured: json['isFeatured'] as bool? ?? false,
      originalUrl: json['originalUrl'] as String?,
      expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? ''),
    );
  }
}

class SearchFilters {
  const SearchFilters({
    this.query = '',
    this.categoryId,
    this.subcategoryId,
    this.minPrice,
    this.maxPrice,
    this.cities = const [],
    this.condition,
    this.postedAfter,
    this.photosOnly = false,
    this.sellerType,
    this.sort = AdSort.newest,
    this.attributes = const {},
  });

  final String query;
  final String? categoryId;
  final String? subcategoryId;
  final double? minPrice;
  final double? maxPrice;
  final List<String> cities;
  final AdCondition? condition;
  final DateTime? postedAfter;
  final bool photosOnly;
  final String? sellerType;
  final AdSort sort;
  final Map<String, dynamic> attributes;

  int get activeCount {
    var n = 0;
    if (minPrice != null || maxPrice != null) n++;
    if (cities.isNotEmpty) n++;
    if (condition != null) n++;
    if (postedAfter != null) n++;
    if (photosOnly) n++;
    if (sellerType != null) n++;
    if (subcategoryId != null) n++;
    n += attributes.values.where((v) => v != null && '$v'.isNotEmpty).length;
    return n;
  }

  SearchFilters copyWith({
    String? query,
    String? categoryId,
    bool clearCategory = false,
    String? subcategoryId,
    bool clearSubcategory = false,
    double? minPrice,
    bool clearMinPrice = false,
    double? maxPrice,
    bool clearMaxPrice = false,
    List<String>? cities,
    AdCondition? condition,
    bool clearCondition = false,
    DateTime? postedAfter,
    bool clearPostedAfter = false,
    bool? photosOnly,
    String? sellerType,
    bool clearSellerType = false,
    AdSort? sort,
    Map<String, dynamic>? attributes,
  }) {
    return SearchFilters(
      query: query ?? this.query,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      subcategoryId:
          clearSubcategory ? null : (subcategoryId ?? this.subcategoryId),
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      cities: cities ?? this.cities,
      condition: clearCondition ? null : (condition ?? this.condition),
      postedAfter:
          clearPostedAfter ? null : (postedAfter ?? this.postedAfter),
      photosOnly: photosOnly ?? this.photosOnly,
      sellerType: clearSellerType ? null : (sellerType ?? this.sellerType),
      sort: sort ?? this.sort,
      attributes: attributes ?? this.attributes,
    );
  }

  Map<String, dynamic> toJson() => {
        'query': query,
        'categoryId': categoryId,
        'subcategoryId': subcategoryId,
        'minPrice': minPrice,
        'maxPrice': maxPrice,
        'cities': cities,
        'condition': condition?.name,
        'postedAfter': postedAfter?.toIso8601String(),
        'photosOnly': photosOnly,
        'sellerType': sellerType,
        'sort': sort.name,
        'attributes': attributes,
      };

  factory SearchFilters.fromJson(Map<String, dynamic> json) {
    return SearchFilters(
      query: json['query'] as String? ?? '',
      categoryId: json['categoryId'] as String?,
      subcategoryId: json['subcategoryId'] as String?,
      minPrice: (json['minPrice'] as num?)?.toDouble(),
      maxPrice: (json['maxPrice'] as num?)?.toDouble(),
      cities: (json['cities'] as List?)?.map((e) => '$e').toList() ?? const [],
      condition: AdCondition.values
          .where((e) => e.name == json['condition'])
          .firstOrNull,
      postedAfter: DateTime.tryParse(json['postedAfter'] as String? ?? ''),
      photosOnly: json['photosOnly'] as bool? ?? false,
      sellerType: json['sellerType'] as String?,
      sort: AdSort.values.firstWhere(
        (e) => e.name == json['sort'],
        orElse: () => AdSort.newest,
      ),
      attributes: json['attributes'] is Map
          ? Map<String, dynamic>.from(json['attributes'] as Map)
          : const {},
    );
  }
}

class SavedSearch {
  const SavedSearch({
    required this.id,
    required this.title,
    required this.filters,
    required this.createdAt,
    this.lastCount = 0,
  });

  final String id;
  final String title;
  final SearchFilters filters;
  final DateTime createdAt;
  final int lastCount;

  SavedSearch copyWith({int? lastCount, String? title}) {
    return SavedSearch(
      id: id,
      title: title ?? this.title,
      filters: filters,
      createdAt: createdAt,
      lastCount: lastCount ?? this.lastCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'filters': filters.toJson(),
        'createdAt': createdAt.toIso8601String(),
        'lastCount': lastCount,
      };

  factory SavedSearch.fromJson(Map<String, dynamic> json) {
    return SavedSearch(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      filters: SearchFilters.fromJson(
        Map<String, dynamic>.from(json['filters'] as Map? ?? {}),
      ),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      lastCount: json['lastCount'] as int? ?? 0,
    );
  }
}

class AdDraft {
  const AdDraft({
    required this.id,
    required this.step,
    required this.updatedAt,
    required this.payload,
  });

  final String id;
  final int step;
  final DateTime updatedAt;
  final Map<String, dynamic> payload;

  Map<String, dynamic> toJson() => {
        'id': id,
        'step': step,
        'updatedAt': updatedAt.toIso8601String(),
        'payload': payload,
      };

  factory AdDraft.fromJson(Map<String, dynamic> json) {
    return AdDraft(
      id: json['id'] as String? ?? 'draft',
      step: json['step'] as int? ?? 0,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      payload: Map<String, dynamic>.from(json['payload'] as Map? ?? {}),
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.fromMe,
    required this.at,
    this.senderId = '',
  });

  final String id;
  final String text;
  final bool fromMe;
  final DateTime at;
  final String senderId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'fromMe': fromMe,
        'senderId': senderId,
        'at': at.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      fromMe: json['fromMe'] as bool? ?? false,
      senderId: json['senderId'] as String? ?? '',
      at: DateTime.tryParse(json['at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class SouqConversation {
  const SouqConversation({
    required this.id,
    required this.adId,
    required this.peerName,
    required this.messages,
    required this.updatedAt,
    this.role = 'buyer',
    this.canSend = true,
    this.canReply = false,
    this.adTitle = '',
  });

  final String id;
  final String adId;
  final String peerName;
  final List<ChatMessage> messages;
  final DateTime updatedAt;
  final String role;
  final bool canSend;
  final bool canReply;
  final String adTitle;

  bool get isSeller => role == 'seller';

  String get preview => messages.isEmpty ? '' : messages.last.text;

  Map<String, dynamic> toJson() => {
        'id': id,
        'adId': adId,
        'peerName': peerName,
        'messages': messages.map((m) => m.toJson()).toList(),
        'updatedAt': updatedAt.toIso8601String(),
        'role': role,
        'canSend': canSend,
        'canReply': canReply,
        'adTitle': adTitle,
      };

  factory SouqConversation.fromJson(Map<String, dynamic> json) {
    final ad = json['ad'] is Map
        ? Map<String, dynamic>.from(json['ad'] as Map)
        : const <String, dynamic>{};
    return SouqConversation(
      id: json['id'] as String? ?? '',
      adId: json['adId'] as String? ?? ad['id'] as String? ?? '',
      peerName: json['peerName'] as String? ?? '',
      messages: (json['messages'] as List? ?? [])
          .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      role: json['role'] as String? ?? 'buyer',
      canSend: json['canSend'] as bool? ?? true,
      canReply: json['canReply'] as bool? ?? false,
      adTitle: json['adTitle'] as String? ?? ad['title'] as String? ?? '',
    );
  }
}

class PriceInsight {
  const PriceInsight({
    required this.low,
    required this.high,
    required this.sample,
  });

  final double low;
  final double high;
  final int sample;
}

class PagedAds {
  const PagedAds({required this.items, required this.total});
  final List<Ad> items;
  final int total;
}
