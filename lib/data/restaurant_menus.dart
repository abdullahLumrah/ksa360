import 'package:flutter/material.dart';

import '../models/restaurant.dart';

const cuisineKinds = <CuisineKind>[
  CuisineKind(
    id: 'nearby',
    title: 'Nearby',
    subtitle: 'Closest to you',
    icon: '📍',
  ),
  CuisineKind(
    id: 'arab',
    title: 'Arab',
    subtitle: 'Kabsa, mandi, grill',
    icon: '🥘',
  ),
  CuisineKind(
    id: 'chinese',
    title: 'Chinese',
    subtitle: 'Wok, rice, dumplings',
    icon: '🥡',
  ),
  CuisineKind(
    id: 'desi',
    title: 'Desi',
    subtitle: 'Biryani, karahi, naan',
    icon: '🍛',
  ),
  CuisineKind(
    id: 'turkish',
    title: 'Turkish',
    subtitle: 'Kebab, pide, tea',
    icon: '🥙',
  ),
  CuisineKind(
    id: 'italian',
    title: 'Italian',
    subtitle: 'Pizza and pasta',
    icon: '🍕',
  ),
  CuisineKind(
    id: 'american',
    title: 'American',
    subtitle: 'Burgers and fried chicken',
    icon: '🍔',
  ),
  CuisineKind(
    id: 'japanese',
    title: 'Japanese',
    subtitle: 'Sushi and ramen',
    icon: '🍣',
  ),
  CuisineKind(
    id: 'seafood',
    title: 'Seafood',
    subtitle: 'Fish and shrimp',
    icon: '🦐',
  ),
  CuisineKind(
    id: 'cafe',
    title: 'Cafes',
    subtitle: 'Coffee and dessert',
    icon: '☕',
  ),
];

const _arab = [
  Dish(name: 'Chicken kabsa', detail: 'Spiced rice with roasted chicken and raisins', price: '28–42 SAR'),
  Dish(name: 'Lamb mandi', detail: 'Slow pit rice with tender lamb', price: '45–70 SAR'),
  Dish(name: 'Mixed grill', detail: 'Kebab, kofta, chops and bread', price: '55–90 SAR'),
  Dish(name: 'Chicken shawarma', detail: 'Wrapped or plate with garlic sauce', price: '12–22 SAR'),
  Dish(name: 'Mutabbaq', detail: 'Stuffed folded pan bread, meat or veg', price: '8–16 SAR'),
  Dish(name: 'Hummus and fatteh', detail: 'Chickpeas, tahini, toasted bread', price: '14–24 SAR'),
  Dish(name: 'Jareesh', detail: 'Crushed wheat, yogurt and ghee', price: '22–34 SAR'),
  Dish(name: 'Luqaimat', detail: 'Sweet dumplings with date syrup', price: '12–20 SAR'),
];

const _chinese = [
  Dish(name: 'Chicken fried rice', detail: 'Wok rice with egg and spring onion', price: '22–32 SAR'),
  Dish(name: 'Chow mein', detail: 'Stir-fried noodles, veg or chicken', price: '24–34 SAR'),
  Dish(name: 'Sweet and sour chicken', detail: 'Crispy chicken in bright sauce', price: '28–40 SAR'),
  Dish(name: 'Kung pao chicken', detail: 'Chili, peanuts and wok chicken', price: '30–42 SAR'),
  Dish(name: 'Spring rolls', detail: 'Crisp rolls with sweet chili', price: '12–18 SAR'),
  Dish(name: 'Hot and sour soup', detail: 'Peppery broth with tofu and egg', price: '14–22 SAR'),
  Dish(name: 'Dumplings', detail: 'Steamed or fried, chicken or veg', price: '18–28 SAR'),
  Dish(name: 'Peking chicken', detail: 'Roasted pieces with hoisin', price: '36–55 SAR'),
];

const _desi = [
  Dish(name: 'Chicken biryani', detail: 'Layered spiced rice, raita on the side', price: '22–36 SAR'),
  Dish(name: 'Karahi', detail: 'Tomato-chili wok, chicken or mutton', price: '32–55 SAR'),
  Dish(name: 'Butter chicken', detail: 'Creamy tomato gravy and naan', price: '28–42 SAR'),
  Dish(name: 'Nihari', detail: 'Slow stew, lemon and ginger', price: '24–38 SAR'),
  Dish(name: 'Haleem', detail: 'Wheat, meat and ghee, especially Ramadan', price: '18–30 SAR'),
  Dish(name: 'Seekh kebab', detail: 'Minced grill with mint chutney', price: '22–34 SAR'),
  Dish(name: 'Dal makhani', detail: 'Black lentils, butter and cream', price: '16–26 SAR'),
  Dish(name: 'Samosa + chai', detail: 'The after-work bachelor plate', price: '8–14 SAR'),
];

const _turkish = [
  Dish(name: 'Adana kebab', detail: 'Spicy minced grill with onion salad', price: '32–48 SAR'),
  Dish(name: 'Iskender', detail: 'Doner on bread, yogurt and tomato butter', price: '36–52 SAR'),
  Dish(name: 'Pide', detail: 'Boat bread with cheese or meat', price: '24–38 SAR'),
  Dish(name: 'Lahmacun', detail: 'Thin topped flatbread', price: '14–22 SAR'),
  Dish(name: 'Lentil soup', detail: 'Mercimek with lemon', price: '10–16 SAR'),
  Dish(name: 'Baklava', detail: 'Pistachio layers and syrup', price: '12–20 SAR'),
  Dish(name: 'Turkish tea', detail: 'Tulip glass, unlimited refills in many spots', price: '4–8 SAR'),
];

const _italian = [
  Dish(name: 'Margherita', detail: 'Tomato, mozzarella, basil', price: '28–42 SAR'),
  Dish(name: 'Pepperoni pizza', detail: 'The default office-night order', price: '32–48 SAR'),
  Dish(name: 'Pasta alfredo', detail: 'Cream, garlic, chicken optional', price: '30–44 SAR'),
  Dish(name: 'Arrabbiata', detail: 'Chili tomato pasta', price: '26–38 SAR'),
  Dish(name: 'Garlic bread', detail: 'With dip', price: '12–18 SAR'),
  Dish(name: 'Tiramisu', detail: 'Coffee mascarpone', price: '16–24 SAR'),
];

const _american = [
  Dish(name: 'Fried chicken meal', detail: 'Pieces, fries, bun or rice — KSA classic', price: '18–32 SAR'),
  Dish(name: 'Cheeseburger', detail: 'Beef or chicken, fries', price: '16–28 SAR'),
  Dish(name: 'Grilled chicken sandwich', detail: 'The lighter office lunch', price: '18–26 SAR'),
  Dish(name: 'Broasted plate', detail: 'Crispy chicken with garlic sauce', price: '22–34 SAR'),
  Dish(name: 'Loaded fries', detail: 'Cheese, sauce, sometimes shawarma meat', price: '14–22 SAR'),
  Dish(name: 'Milkshake', detail: 'Chocolate or strawberry', price: '12–18 SAR'),
];

const _japanese = [
  Dish(name: 'Salmon sushi set', detail: 'Nigiri and maki', price: '45–75 SAR'),
  Dish(name: 'California roll', detail: 'The starter roll everywhere', price: '22–34 SAR'),
  Dish(name: 'Ramen', detail: 'Broth, noodles, egg, chashu or chicken', price: '38–58 SAR'),
  Dish(name: 'Chicken katsu', detail: 'Crumbed cutlet with rice', price: '36–52 SAR'),
  Dish(name: 'Miso soup', detail: 'Side bowl', price: '8–14 SAR'),
  Dish(name: 'Edamame', detail: 'Salted beans', price: '12–18 SAR'),
];

const _seafood = [
  Dish(name: 'Grilled hammour', detail: 'Gulf grouper, lemon and rice', price: '55–90 SAR'),
  Dish(name: 'Shrimp sayadiya', detail: 'Spiced rice and fried shrimp', price: '48–75 SAR'),
  Dish(name: 'Fish mandi', detail: 'Coastal Friday plate', price: '40–65 SAR'),
  Dish(name: 'Calamari', detail: 'Fried rings, garlic dip', price: '28–42 SAR'),
  Dish(name: 'Mixed seafood grill', detail: 'Fish, shrimp, calamari', price: '80–120 SAR'),
];

const _cafe = [
  Dish(name: 'Saudi coffee', detail: 'Qahwa with dates', price: '12–22 SAR'),
  Dish(name: 'Flat white', detail: 'The compound-cafe order', price: '16–24 SAR'),
  Dish(name: 'Karak', detail: 'Strong milk tea, South Asian bakeries', price: '4–10 SAR'),
  Dish(name: 'Date cake', detail: 'Or pistachio croissant', price: '14–22 SAR'),
  Dish(name: 'Avocado toast', detail: 'Brunch menus in Khobar and Riyadh', price: '28–42 SAR'),
  Dish(name: 'Cheesecake', detail: 'Slice to share', price: '18–28 SAR'),
];

const _alBaik = [
  Dish(name: 'Broasted chicken meal', detail: 'The national late-night order', price: '16–28 SAR'),
  Dish(name: 'Chicken nuggets', detail: 'With garlic and hot sauce', price: '12–20 SAR'),
  Dish(name: 'Fish meal', detail: 'Crispy fish, fries, bun', price: '18–26 SAR'),
  Dish(name: 'Value meal', detail: 'Chicken, fries, drink', price: '14–22 SAR'),
  Dish(name: 'Garlic sauce extra', detail: 'People come back for this', price: '1–3 SAR'),
];

const _herfy = [
  Dish(name: 'Herfy burger', detail: 'Beef or chicken, the old KSA chain', price: '14–24 SAR'),
  Dish(name: 'Chicken strips', detail: 'With fries', price: '16–24 SAR'),
  Dish(name: 'Breakfast sandwich', detail: 'Egg and chicken, early shift', price: '10–16 SAR'),
];

const _kudu = [
  Dish(name: 'Kudu chicken sandwich', detail: 'Toasted, very KSA office lunch', price: '14–22 SAR'),
  Dish(name: 'Tuna sandwich', detail: 'The lighter one', price: '12–18 SAR'),
  Dish(name: 'Fries', detail: 'Side', price: '8–12 SAR'),
];

const _thai = [
  Dish(name: 'Pad thai', detail: 'Noodles, tamarind, egg, shrimp or chicken', price: '28–42 SAR'),
  Dish(name: 'Green curry', detail: 'Coconut, basil, rice', price: '30–44 SAR'),
  Dish(name: 'Tom yum', detail: 'Hot and sour prawn soup', price: '18–28 SAR'),
  Dish(name: 'Mango sticky rice', detail: 'When they have it', price: '16–24 SAR'),
];

const Map<String, List<Dish>> _byKind = {
  'arab': _arab,
  'chinese': _chinese,
  'desi': _desi,
  'turkish': _turkish,
  'italian': _italian,
  'american': _american,
  'japanese': _japanese,
  'seafood': _seafood,
  'cafe': _cafe,
  'thai': _thai,
};

List<Dish> dishesFor(Restaurant place) {
  final n = place.name.toLowerCase();
  if (n.contains('baik') || n.contains('البيك')) return _alBaik;
  if (n.contains('herfy') || n.contains('هرفي')) return _herfy;
  if (n.contains('kudu') || n.contains('كودو')) return _kudu;
  return _byKind[place.kind] ?? _arab;
}

String classifyCuisine(String raw, String name) {
  final n = name.toLowerCase();
  if (n.contains('shawarma') || n.contains('شاورما')) return 'arab';
  final blob =
      '${raw}_$name'.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
  const table = <String, List<String>>{
    'desi': [
      'indian',
      'pakistani',
      'bangladeshi',
      'punjabi',
      'biryani',
      'karachi',
      'lahore',
      'hyderabadi',
      'kerala',
      'indian_restaurant',
    ],
    'chinese': ['chinese', 'taiwanese', 'dim_sum', 'szechuan', 'wok', 'chinese_restaurant'],
    'japanese': ['japanese', 'sushi', 'ramen', 'japanese_restaurant', 'sushi_restaurant'],
    'korean': ['korean', 'korean_restaurant'],
    'thai': ['thai', 'vietnamese', 'asian', 'thai_restaurant', 'vietnamese_restaurant'],
    'italian': ['italian', 'pizza', 'pasta', 'italian_restaurant', 'pizza_restaurant'],
    'turkish': ['turkish', 'kebab', 'adana', 'turkish_restaurant'],
    'american': [
      'american',
      'burger',
      'chicken',
      'fried_chicken',
      'kfc',
      'mcdonald',
      'herfy',
      'kudu',
      'baik',
      'hardee',
      'hamburger_restaurant',
      'fast_food_restaurant',
    ],
    'seafood': ['seafood', 'fish', 'shrimp', 'seafood_restaurant'],
    'cafe': [
      'cafe',
      'coffee',
      'dessert',
      'ice_cream',
      'bakery',
      'donut',
      'starbucks',
      'dunkin',
      'coffee_shop',
      'dessert_shop',
    ],
    'arab': [
      'arab',
      'saudi',
      'lebanese',
      'yemeni',
      'egyptian',
      'shawarma',
      'falafel',
      'mandi',
      'kabsa',
      'gulf',
      'middle_eastern',
      'mediterranean_restaurant',
      'lebanese_restaurant',
    ],
  };
  for (final entry in table.entries) {
    if (entry.value.any(blob.contains)) return entry.key;
  }
  if (n.contains('cafe') || n.contains('coffee')) return 'cafe';
  if (n.contains('pizza')) return 'italian';
  if (n.contains('china') || n.contains('chinese')) return 'chinese';
  if (n.contains('india') || n.contains('pakistan') || n.contains('biryani')) {
    return 'desi';
  }
  return 'arab';
}

String cuisineTitle(String id) {
  for (final k in cuisineKinds) {
    if (k.id == id) return k.title;
  }
  return 'Arab';
}

Color cuisineColor(String id) {
  switch (id) {
    case 'chinese':
      return const Color(0xFFB33A2B);
    case 'desi':
      return const Color(0xFFC4621A);
    case 'turkish':
      return const Color(0xFFA33B52);
    case 'italian':
      return const Color(0xFF1E7A4C);
    case 'american':
      return const Color(0xFF8A5E2E);
    case 'japanese':
      return const Color(0xFF9A3D55);
    case 'seafood':
      return const Color(0xFF2A7572);
    case 'cafe':
      return const Color(0xFF8A5E2E);
    case 'thai':
      return const Color(0xFF6E5688);
    default:
      return const Color(0xFF9A6234);
  }
}

const _cuisinePhotos = <String, List<String>>{
  'arab': [
    'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&w=900&q=70',
    'https://images.unsplash.com/photo-1512058564366-18510be2db19?auto=format&fit=crop&w=900&q=70',
    'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?auto=format&fit=crop&w=900&q=70',
  ],
  'chinese': [
    'https://images.unsplash.com/photo-1585032226651-759b368d7246?auto=format&fit=crop&w=900&q=70',
    'https://images.unsplash.com/photo-1563245372-f21724e3856d?auto=format&fit=crop&w=900&q=70',
  ],
  'desi': [
    'https://images.unsplash.com/photo-1585937421612-70a008356fbe?auto=format&fit=crop&w=900&q=70',
    'https://images.unsplash.com/photo-1567188040759-fb8a883dc6d8?auto=format&fit=crop&w=900&q=70',
  ],
  'turkish': [
    'https://images.unsplash.com/photo-1529042410759-befb1204b468?auto=format&fit=crop&w=900&q=70',
    'https://images.unsplash.com/photo-1603360946369-dc9bb6258143?auto=format&fit=crop&w=900&q=70',
  ],
  'italian': [
    'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=900&q=70',
    'https://images.unsplash.com/photo-1473093295043-cdd812d0e601?auto=format&fit=crop&w=900&q=70',
  ],
  'american': [
    'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=900&q=70',
    'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?auto=format&fit=crop&w=900&q=70',
  ],
  'japanese': [
    'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?auto=format&fit=crop&w=900&q=70',
    'https://images.unsplash.com/photo-1617196034796-73dfa7b1fd56?auto=format&fit=crop&w=900&q=70',
  ],
  'seafood': [
    'https://images.unsplash.com/photo-1559339352-11d035aa65de?auto=format&fit=crop&w=900&q=70',
    'https://images.unsplash.com/photo-1534085563651-2c62c0f38a11?auto=format&fit=crop&w=900&q=70',
  ],
  'cafe': [
    'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=900&q=70',
    'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=900&q=70',
  ],
  'thai': [
    'https://images.unsplash.com/photo-1559314809-0d155014e29e?auto=format&fit=crop&w=900&q=70',
  ],
};

String cuisineFallbackPhoto(Restaurant place) {
  final shots = _cuisinePhotos[place.kind] ?? _cuisinePhotos['arab']!;
  return shots[place.id.hashCode.abs() % shots.length];
}

String foodPhotoFor(Restaurant place) {
  if (place.image.isNotEmpty) return place.image;
  return cuisineFallbackPhoto(place);
}
