class Restaurant {
  const Restaurant({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.kind,
    this.cuisine = '',
    this.city = '',
    this.phone = '',
    this.hours = '',
    this.web = '',
    this.amenity = 'restaurant',
    this.image = '',
    this.rating = 0,
    this.ratings = 0,
    this.video = '',
    this.km = 0,
    this.dishes = const [],
    this.reviewSource = '',
  });

  final String id;
  final String name;
  final double lat;
  final double lng;
  final String kind;
  final String cuisine;
  final String city;
  final String phone;
  final String hours;
  final String web;
  final String amenity;
  final String image;
  final double rating;
  final int ratings;
  final String video;
  final double km;
  final List<Dish> dishes;
  final String reviewSource;

  Restaurant withDistance(double value) => Restaurant(
        id: id,
        name: name,
        lat: lat,
        lng: lng,
        kind: kind,
        cuisine: cuisine,
        city: city,
        phone: phone,
        hours: hours,
        web: web,
        amenity: amenity,
        image: image,
        rating: rating,
        ratings: ratings,
        video: video,
        km: value,
        dishes: dishes,
        reviewSource: reviewSource,
      );

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'] as String,
      name: json['name'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      kind: json['kind'] as String? ?? 'arab',
      cuisine: json['cuisine'] as String? ?? '',
      city: json['city'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      hours: json['hours'] as String? ?? '',
      web: json['web'] as String? ?? '',
      amenity: json['amenity'] as String? ?? 'restaurant',
      image: json['image'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      ratings: (json['ratings'] as num?)?.toInt() ?? 0,
      video: json['video'] as String? ?? '',
      km: (json['km'] as num?)?.toDouble() ?? 0,
      dishes: (json['dishes'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => Dish.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      reviewSource: json['reviewSource'] as String? ?? '',
    );
  }
}

class Dish {
  const Dish({
    required this.name,
    required this.detail,
    required this.price,
    this.image = '',
    this.category = '',
  });

  final String name;
  final String detail;
  final String price;
  final String image;
  final String category;

  factory Dish.fromJson(Map<String, dynamic> json) {
    return Dish(
      name: (json['name'] ?? '').toString(),
      detail: (json['detail'] ?? json['description'] ?? '').toString(),
      price: (json['price'] ?? '').toString(),
      image: (json['image'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
    );
  }
}

class CuisineKind {
  const CuisineKind({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String id;
  final String title;
  final String subtitle;
  final String icon;
}
