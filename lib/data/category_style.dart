import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CategoryStyle {
  const CategoryStyle(this.icon, this.color);

  final IconData icon;
  final Color color;

  static const _fallback = CategoryStyle(Icons.article_outlined, AppColors.green);

  static const _images = {
    'jawazat-and-moi',
    'driving-in-saudi-arabia',
    'saudi-laws',
    'career',
    'general-information',
    'important',
    'latest-news',
    'social-issues',
    'online-shopping',
  };

  /// Bundled editorial photo for a top-level category, if there is one.
  static String? imageFor(String slug) =>
      _images.contains(slug) ? 'assets/categories/$slug.jpg' : null;

  /// Bright label color for photo tiles, one hue per top-level category.
  static Color accentFor(String slug) {
    final own = _accents[slug];
    if (own != null) return own;
    const palette = [
      Color(0xFF7EB6FF),
      Color(0xFF4EE0D1),
      Color(0xFFFF8A9A),
      Color(0xFFFFB45A),
      Color(0xFF5CE1F2),
      Color(0xFFFF7AD4),
      Color(0xFFFFC44D),
      Color(0xFFFF8B5C),
    ];
    return palette[slug.hashCode.abs() % palette.length];
  }

  static const _accents = {
    'jawazat-and-moi': Color(0xFF7EB6FF),
    'driving-in-saudi-arabia': Color(0xFF4EE0D1),
    'saudi-laws': Color(0xFFFF8A9A),
    'career': Color(0xFFFFB45A),
    'general-information': Color(0xFF5CE1F2),
    'important': Color(0xFFFF7AD4),
    'latest-news': Color(0xFFFFC44D),
    'social-issues': Color(0xFFFF8B5C),
    'online-shopping': Color(0xFFFF8AA8),
  };

  static CategoryStyle of(String slug, [String name = '']) {
    final key = slug.toLowerCase();
    if (_bySlug.containsKey(key)) return _bySlug[key]!;
    final lower = name.toLowerCase();
    for (final entry in _byKeyword.entries) {
      if (lower.contains(entry.key) || key.contains(entry.key)) {
        return entry.value;
      }
    }
    return _fallback;
  }

  static const gold = Color(0xFF8A5E2E);
  static const emerald = Color(0xFF1E7A4C);
  static const mint = Color(0xFF2C7A68);
  static const sapphire = Color(0xFF3D6A94);
  static const teal = Color(0xFF2A7572);
  static const amethyst = Color(0xFF6E5688);
  static const coral = Color(0xFFB55242);
  static const copper = Color(0xFF9A6234);
  static const sage = Color(0xFF5C675F);
  static const rose = Color(0xFF9A5568);

  static const _bySlug = {
    'career': CategoryStyle(Icons.work_outline_rounded, gold),
    'job-hunting': CategoryStyle(Icons.search_rounded, gold),
    'business-index': CategoryStyle(Icons.storefront_outlined, copper),
    'establishing-business': CategoryStyle(Icons.apartment_rounded, copper),
    'work-environment': CategoryStyle(Icons.groups_outlined, gold),
    'working-women': CategoryStyle(Icons.badge_outlined, rose),
    'driving-in-saudi-arabia': CategoryStyle(Icons.directions_car_filled_rounded, sapphire),
    'cars-in-saudi-arabia': CategoryStyle(Icons.directions_car_rounded, sapphire),
    'istamara-and-fahas': CategoryStyle(Icons.assignment_outlined, sapphire),
    'traffic-violations': CategoryStyle(Icons.speed_rounded, sapphire),
    'accidents-and-insurance': CategoryStyle(Icons.health_and_safety_outlined, sapphire),
    'women-driving': CategoryStyle(Icons.drive_eta_outlined, sapphire),
    'other-driving-issues': CategoryStyle(Icons.car_crash_outlined, sapphire),
    'general-information': CategoryStyle(Icons.public_rounded, teal),
    'important': CategoryStyle(Icons.star_rounded, coral),
    'jawazat-and-moi': CategoryStyle(Icons.badge_rounded, emerald),
    'moi-account-abshir-services': CategoryStyle(Icons.phone_android_rounded, emerald),
    'iqama': CategoryStyle(Icons.credit_card_rounded, emerald),
    'iqama-for-newcomers': CategoryStyle(Icons.how_to_reg_outlined, emerald),
    'iqama-for-newly-born': CategoryStyle(Icons.child_care_outlined, mint),
    'iqama-profession': CategoryStyle(Icons.work_history_outlined, emerald),
    'renewal-of-iqama': CategoryStyle(Icons.autorenew_rounded, mint),
    'transfer-of-sponsorship-naqal-kafala': CategoryStyle(Icons.swap_horiz_rounded, mint),
    'visas': CategoryStyle(Icons.flight_takeoff_rounded, emerald),
    'exit-re-entry-visa': CategoryStyle(Icons.flight_rounded, emerald),
    'family-visit-visa': CategoryStyle(Icons.family_restroom_rounded, mint),
    'final-exit-visa': CategoryStyle(Icons.logout_rounded, emerald),
    'work-visa': CategoryStyle(Icons.card_travel_rounded, emerald),
    'hajj-and-umrah': CategoryStyle(Icons.mosque_rounded, mint),
    'hajj-umrah': CategoryStyle(Icons.mosque_rounded, mint),
    'qiwa': CategoryStyle(Icons.apartment_outlined, emerald),
    'ejar-contract': CategoryStyle(Icons.home_work_outlined, emerald),
    'latest-news': CategoryStyle(Icons.newspaper_rounded, amethyst),
    'online-shopping': CategoryStyle(Icons.shopping_bag_outlined, copper),
    'amazon-deals': CategoryStyle(Icons.local_offer_outlined, copper),
    'saudi-laws': CategoryStyle(Icons.gavel_rounded, sage),
    'saudi-labor-law': CategoryStyle(Icons.balance_rounded, sage),
    'other-laws': CategoryStyle(Icons.policy_outlined, sage),
    'punishments': CategoryStyle(Icons.warning_amber_rounded, coral),
    'cyber-crimes': CategoryStyle(Icons.security_rounded, sage),
    'social-issues': CategoryStyle(Icons.diversity_3_rounded, gold),
    'banks-in-saudi-arabia': CategoryStyle(Icons.account_balance_rounded, sapphire),
    'account-opening': CategoryStyle(Icons.account_balance_wallet_outlined, sapphire),
    'al-rajhi-bank': CategoryStyle(Icons.account_balance_rounded, teal),
    'snb-al-ahli': CategoryStyle(Icons.account_balance_rounded, sapphire),
    'digital-e-wallets': CategoryStyle(Icons.wallet_rounded, amethyst),
    'crypto': CategoryStyle(Icons.currency_bitcoin, gold),
    'technology': CategoryStyle(Icons.devices_rounded, amethyst),
    'mobile-phones': CategoryStyle(Icons.smartphone_rounded, sage),
    'health-issues': CategoryStyle(Icons.local_hospital_outlined, coral),
    'food-issues': CategoryStyle(Icons.restaurant_rounded, copper),
    'places-to-visit-in-saudi-arabia': CategoryStyle(Icons.travel_explore_rounded, teal),
    'places-to-visit-in-riyadh': CategoryStyle(Icons.location_city_rounded, teal),
    'places-to-visit-in-jeddah': CategoryStyle(Icons.sailing_rounded, teal),
    'places-to-visit-in-makkah': CategoryStyle(Icons.mosque_outlined, mint),
    'places-to-visit-in-madina': CategoryStyle(Icons.mosque_outlined, mint),
    'travelling-from-ksa': CategoryStyle(Icons.flight_rounded, sapphire),
    'marriage': CategoryStyle(Icons.favorite_outline_rounded, rose),
    'getting-married-in-ksa': CategoryStyle(Icons.favorite_rounded, rose),
    'islamic-information': CategoryStyle(Icons.menu_book_rounded, mint),
    'islamic-values': CategoryStyle(Icons.auto_stories_rounded, mint),
    'islamic-news': CategoryStyle(Icons.rss_feed_rounded, amethyst),
    'dream-interpretation-tabeer': CategoryStyle(Icons.nights_stay_outlined, amethyst),
    'education-system': CategoryStyle(Icons.school_outlined, sapphire),
    'ramadan': CategoryStyle(Icons.nightlight_round, mint),
    'shopping': CategoryStyle(Icons.storefront_rounded, copper),
    'nitaqat': CategoryStyle(Icons.groups_2_outlined, gold),
    'employee-benefits': CategoryStyle(Icons.card_giftcard_rounded, gold),
    'expat-community': CategoryStyle(Icons.groups_rounded, gold),
    'blog': CategoryStyle(Icons.rss_feed_rounded, amethyst),
    'deals-offers': CategoryStyle(Icons.local_offer_rounded, copper),
    'jawazat': CategoryStyle(Icons.badge_outlined, emerald),
    'saudi-arabia-covid-19-laws': CategoryStyle(Icons.health_and_safety_outlined, coral),
    'sports': CategoryStyle(Icons.sports_soccer_rounded, emerald),
    'top-10': CategoryStyle(Icons.emoji_events_outlined, gold),
    'top-android-apps': CategoryStyle(Icons.apps_rounded, sage),
  };

  static const _byKeyword = {
    'visa': CategoryStyle(Icons.flight_takeoff_rounded, emerald),
    'iqama': CategoryStyle(Icons.credit_card_rounded, emerald),
    'bank': CategoryStyle(Icons.account_balance_rounded, sapphire),
    'mobile': CategoryStyle(Icons.smartphone_rounded, sage),
    'news': CategoryStyle(Icons.newspaper_rounded, amethyst),
    'law': CategoryStyle(Icons.gavel_rounded, sage),
    'drive': CategoryStyle(Icons.directions_car_rounded, sapphire),
    'car': CategoryStyle(Icons.directions_car_rounded, sapphire),
    'travel': CategoryStyle(Icons.flight_rounded, sapphire),
    'place': CategoryStyle(Icons.place_outlined, teal),
    'islam': CategoryStyle(Icons.mosque_rounded, mint),
    'hajj': CategoryStyle(Icons.mosque_rounded, mint),
    'umrah': CategoryStyle(Icons.mosque_rounded, mint),
    'health': CategoryStyle(Icons.local_hospital_outlined, coral),
    'food': CategoryStyle(Icons.restaurant_rounded, copper),
    'job': CategoryStyle(Icons.work_outline_rounded, gold),
    'marriage': CategoryStyle(Icons.favorite_outline_rounded, rose),
    'embassy': CategoryStyle(Icons.account_balance_outlined, sapphire),
    'nitaqat': CategoryStyle(Icons.groups_2_outlined, gold),
    'deal': CategoryStyle(Icons.local_offer_rounded, copper),
    'benefit': CategoryStyle(Icons.card_giftcard_rounded, gold),
  };
}
