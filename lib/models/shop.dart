class ShopFilter {
  const ShopFilter({
    required this.id,
    required this.label,
    this.count = 0,
    this.selected = false,
  });

  final String id;
  final String label;
  final int count;
  final bool selected;

  factory ShopFilter.fromJson(Map<String, dynamic> json) {
    return ShopFilter(
      id: '${json['id'] ?? ''}',
      label: '${json['label'] ?? ''}',
      count: (json['count'] as num?)?.toInt() ?? 0,
      selected: json['selected'] == true,
    );
  }
}

class ShopSearchResult {
  const ShopSearchResult({
    this.query = '',
    this.category = '',
    this.filter = '',
    this.total = 0,
    this.filters = const [],
    this.merchants = const [],
  });

  final String query;
  final String category;
  final String filter;
  final int total;
  final List<ShopFilter> filters;
  final List<ShopMerchant> merchants;

  factory ShopSearchResult.fromJson(Map<String, dynamic> json) {
    return ShopSearchResult(
      query: '${json['query'] ?? ''}',
      category: '${json['category'] ?? ''}',
      filter: '${json['filter'] ?? ''}',
      total: (json['total'] as num?)?.toInt() ?? 0,
      filters: [
        for (final item in json['filters'] as List<dynamic>? ?? const [])
          if (item is Map)
            ShopFilter.fromJson(Map<String, dynamic>.from(item)),
      ],
      merchants: [
        for (final item in json['merchants'] as List<dynamic>? ?? const [])
          if (item is Map)
            ShopMerchant.fromJson(Map<String, dynamic>.from(item)),
      ],
    );
  }
}

class ShopCategory {
  const ShopCategory({
    required this.id,
    required this.name,
    this.blurb = '',
    this.image = '',
    this.icon = '',
    this.merchantCount = 0,
    this.couponCount = 0,
  });

  final String id;
  final String name;
  final String blurb;
  final String image;
  final String icon;
  final int merchantCount;
  final int couponCount;

  factory ShopCategory.fromJson(Map<String, dynamic> json) {
    return ShopCategory(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? ''}',
      blurb: '${json['blurb'] ?? ''}',
      image: '${json['image'] ?? ''}',
      icon: '${json['icon'] ?? json['image'] ?? ''}',
      merchantCount: (json['merchantCount'] as num?)?.toInt() ?? 0,
      couponCount: (json['couponCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class ShopCoupon {
  const ShopCoupon({
    required this.id,
    required this.title,
    this.detail = '',
    this.code = '',
    this.url = '',
    this.merchantId = '',
    this.merchantName = '',
  });

  final String id;
  final String title;
  final String detail;
  final String code;
  final String url;
  final String merchantId;
  final String merchantName;

  factory ShopCoupon.fromJson(Map<String, dynamic> json) {
    return ShopCoupon(
      id: '${json['id'] ?? ''}',
      title: '${json['title'] ?? ''}',
      detail: '${json['detail'] ?? ''}',
      code: '${json['code'] ?? ''}',
      url: '${json['url'] ?? ''}',
      merchantId: '${json['merchantId'] ?? ''}',
      merchantName: '${json['merchantName'] ?? ''}',
    );
  }
}

class ShopMerchant {
  const ShopMerchant({
    required this.id,
    required this.name,
    this.blurb = '',
    this.website = '',
    this.androidId = '',
    this.iosId = '',
    this.androidUrl = '',
    this.iosUrl = '',
    this.image = '',
    this.icon = '',
    this.kind = 'app',
    this.featured = false,
    this.categories = const [],
    this.coupons = const [],
  });

  final String id;
  final String name;
  final String blurb;
  final String website;
  final String androidId;
  final String iosId;
  final String androidUrl;
  final String iosUrl;
  final String image;
  final String icon;
  final String kind;
  final bool featured;
  final List<String> categories;
  final List<ShopCoupon> coupons;

  bool get hasApp => androidId.isNotEmpty || iosId.isNotEmpty;

  String get playStoreUrl {
    if (androidUrl.isNotEmpty) return androidUrl;
    if (androidId.isEmpty) return '';
    return 'https://play.google.com/store/apps/details?id=$androidId';
  }

  String get appStoreUrl {
    if (iosUrl.isNotEmpty) return iosUrl;
    if (iosId.isEmpty) return '';
    return 'https://apps.apple.com/sa/app/id$iosId';
  }

  factory ShopMerchant.fromJson(Map<String, dynamic> json) {
    return ShopMerchant(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? ''}',
      blurb: '${json['blurb'] ?? ''}',
      website: '${json['website'] ?? ''}',
      androidId: '${json['androidId'] ?? ''}',
      iosId: '${json['iosId'] ?? ''}',
      androidUrl: '${json['androidUrl'] ?? ''}',
      iosUrl: '${json['iosUrl'] ?? ''}',
      image: '${json['image'] ?? ''}',
      icon: '${json['icon'] ?? json['image'] ?? ''}',
      kind: '${json['kind'] ?? 'app'}',
      featured: json['featured'] == true,
      categories: [
        for (final item in json['categories'] as List<dynamic>? ?? const [])
          item.toString(),
      ],
      coupons: [
        for (final item in json['coupons'] as List<dynamic>? ?? const [])
          if (item is Map)
            ShopCoupon.fromJson(Map<String, dynamic>.from(item)),
      ],
    );
  }
}
