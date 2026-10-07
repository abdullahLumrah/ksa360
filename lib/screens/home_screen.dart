import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../data/activity_repository.dart';
import '../data/app_analytics.dart';
import '../data/app_tabs.dart';
import '../data/content_repository.dart';
import '../data/healthcare_repository.dart';
import '../data/ksa_activities.dart';
import '../data/life_settings.dart';
import '../data/prayer_service.dart';
import '../data/restaurant_menus.dart';
import '../data/restaurant_repository.dart';
import '../data/school_repository.dart';
import '../data/shop_repository.dart';
import '../models/health_facility.dart';
import '../models/models.dart';
import '../models/restaurant.dart';
import '../models/school.dart';
import '../models/shop.dart';
import '../theme/app_theme.dart';
import '../widgets/category_widgets.dart';
import '../widgets/emergency_strip.dart';
import '../widgets/ksa360_mark.dart';
import '../widgets/motion.dart';
import '../widgets/post_cards.dart';
import '../widgets/school_photo.dart';
import 'category_screen.dart';
import 'emergency_screen.dart';
import 'explore_screen.dart';
import 'healthcare_detail_screen.dart';
import 'healthcare_screen.dart';
import 'life_screen.dart';
import 'play_screen.dart';
import 'post_detail_screen.dart';
import 'restaurant_detail_screen.dart';
import 'shop_category_screen.dart';
import 'shop_home_screen.dart';
import 'school_detail_screen.dart';
import 'schools_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = ContentRepository.instance;
    final tops = repo.topCategories;

    return ListenableBuilder(
      listenable: Listenable.merge([
        LifeSettings.instance,
        RestaurantRepository.instance,
        ActivityRepository.instance,
        ContentRepository.instance,
        ShopRepository.instance,
        HealthcareRepository.instance,
        SchoolRepository.instance,
      ]),
      builder: (context, _) {
        final settings = LifeSettings.instance;
        final lifestyleGuides = repo.guidesForLifestyle(
          settings.lifestyle == Lifestyle.bachelor ? 'bachelor' : 'family',
        );
        final carePlaces = HealthcareRepository.instance
            .nearby(
              lat: settings.prayerLat,
              lng: settings.prayerLng,
              limit: 40,
            )
            .where((place) {
              return place.emergency ||
                  place.kind == 'hospital' ||
                  place.kind == 'clinic' ||
                  place.kind == 'health_centre';
            })
            .take(16)
            .toList();
        final studyPlaces = SchoolRepository.instance.nearby(
          lat: settings.prayerLat,
          lng: settings.prayerLng,
          limit: 12,
        );
        final eatPlaces = RestaurantRepository.instance.nearby(
          lat: settings.prayerLat,
          lng: settings.prayerLng,
          preferCity: settings.city.name,
          limit: 12,
        );
        final playPlaces = activitiesNear(
          settings.prayerLat,
          settings.prayerLng,
          preferCity: settings.city.name,
          limit: 10,
        );
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: FadeSlideIn(
                child: _HomeHeader(settings: settings),
              ),
            ),
            SliverToBoxAdapter(
              child: FadeSlideIn(
                delay: const Duration(milliseconds: 40),
                child: const _HomeActionCard(
                  icon: Icons.search_rounded,
                  title: 'Search',
                  subtitle: 'Guides, food, play, embassies',
                  page: SearchScreen(pushed: true),
                  compact: true,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: FadeSlideIn(
                delay: const Duration(milliseconds: 55),
                child: _HomeActionCard(
                  icon: Icons.storefront_rounded,
                  title: 'Souq',
                  subtitle: 'Buy and sell used cars and more',
                  compact: true,
                  onTap: () => AppTabs.go(AppTabs.souq),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: FadeSlideIn(
                delay: const Duration(milliseconds: 68),
                child: SectionHeader(
                  title: 'Daily in KSA · Coupons & brands',
                  subtitle: 'Apps, shops, and offers',
                  onSeeAll: () => openCard(context, const ShopHomeScreen()),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: FadeSlideIn(
                delay: const Duration(milliseconds: 74),
                child: _DailyKsaGrid(
                  categories: ShopRepository.instance.categories,
                  loading: !ShopRepository.instance.loaded &&
                      ShopRepository.instance.refreshing,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: FadeSlideIn(
                delay: const Duration(milliseconds: 86),
                child: EmergencyStrip(
                  onSeeAll: () => openCard(context, const EmergencyScreen()),
                ),
              ),
            ),
            if (carePlaces.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: FadeSlideIn(
                  delay: const Duration(milliseconds: 90),
                  child: SectionHeader(
                    title: 'Find clinics',
                    subtitle: 'Hospitals and clinics around you',
                    onSeeAll: () => openCard(
                      context,
                      const HealthcareScreen(initialKind: 'clinic'),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: FadeSlideIn(
                  delay: const Duration(milliseconds: 96),
                  child: _HealthNearbyRail(
                    loading: !HealthcareRepository.instance.loaded,
                    places: carePlaces,
                  ),
                ),
              ),
            ],
            if (studyPlaces.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: FadeSlideIn(
                  delay: const Duration(milliseconds: 102),
                  child: SectionHeader(
                    title: 'Study in Saudi Arabia',
                    subtitle: 'International schools near you',
                    onSeeAll: () => openCard(context, const SchoolsScreen()),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: FadeSlideIn(
                  delay: const Duration(milliseconds: 108),
                  child: _SchoolNearbyRail(
                    loading: !SchoolRepository.instance.loaded,
                    schools: studyPlaces,
                  ),
                ),
              ),
            ],
            SliverToBoxAdapter(
              child: FadeSlideIn(
                delay: const Duration(milliseconds: 114),
                child: SectionHeader(
                  title: 'Categories',
                  subtitle: 'Guides grouped the way people look them up',
                  onSeeAll: () => AppTabs.go(AppTabs.categories),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: FadeSlideIn(
                delay: const Duration(milliseconds: 100),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: GridView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: tops.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.86,
                    ),
                    itemBuilder: (context, index) {
                      final category = tops[index];
                      return CategoryPhotoTile(
                        category: category,
                        onTap: () => openCard(
                          context,
                          CategoryScreen(category: category),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            if (eatPlaces.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: FadeSlideIn(
                  delay: const Duration(milliseconds: 140),
                  child: SectionHeader(
                    title: 'Eat nearby',
                    subtitle: 'Arab, Chinese, Desi and more',
                    onSeeAll: () => AppTabs.go(AppTabs.eat),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: FadeSlideIn(
                  delay: const Duration(milliseconds: 150),
                  child: _EatNearbyRail(
                    loading: !RestaurantRepository.instance.loaded,
                    places: eatPlaces,
                  ),
                ),
              ),
            ],
            if (playPlaces.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: FadeSlideIn(
                  delay: const Duration(milliseconds: 155),
                  child: SectionHeader(
                    title: 'Play nearby',
                    subtitle: 'Dunes, karting, snow, cinema, malls',
                    onSeeAll: () => AppTabs.go(AppTabs.play),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: FadeSlideIn(
                  delay: const Duration(milliseconds: 165),
                  child: PlayNearbyRail(places: playPlaces),
                ),
              ),
            ],
            if (lifestyleGuides.isNotEmpty)
              SliverToBoxAdapter(
                child: _CategoryRail(
                  categoryName: settings.lifestyle == Lifestyle.family
                      ? 'For families'
                      : 'For bachelor life',
                  subtitle: 'Housing, visa and daily setup',
                  posts: lifestyleGuides,
                ),
              ),
        for (final category in tops)
          SliverToBoxAdapter(
            child: _CategoryRail(
              category: category,
              posts: repo.postsFor(category, limit: 12),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        );
      },
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.settings});

  final LifeSettings settings;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 12,
        20,
        8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Ksa360Mark(size: 44),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        text: 'KSA ',
                        children: [
                          TextSpan(
                            text: '360',
                            style: TextStyle(color: AppColors.gold),
                          ),
                        ],
                      ),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Kingdom of Saudi Arabia',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _PrayerPill(settings: settings),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _HomeActionCard extends StatelessWidget {
  const _HomeActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.page,
    this.onTap,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? page;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, compact ? 8 : 12, 16, 4),
      child: PressableScale(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap ??
            () {
              if (page != null) openCard(context, page!);
            },
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 14,
            vertical: compact ? 8 : 16,
          ),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.stroke),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.gold, size: compact ? 20 : 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: compact ? 14 : null,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Next prayer and countdown, top right of the home header.
class _PrayerPill extends StatefulWidget {
  const _PrayerPill({required this.settings});

  final LifeSettings settings;

  @override
  State<_PrayerPill> createState() => _PrayerPillState();
}

class _PrayerPillState extends State<_PrayerPill> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prayers = PrayerService.forLocation(
      widget.settings.prayerLat,
      widget.settings.prayerLng,
    );
    return Tooltip(
      message: '${prayers.nextName} · ${widget.settings.locationLabel}',
      child: PressableScale(
        borderRadius: BorderRadius.circular(18),
        onTap: () => openCard(context, const LifeScreen()),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.stroke),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.greenDeep, AppColors.green],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  Icons.mosque_rounded,
                  color: AppColors.goldBright,
                  size: 15,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    prayers.nextName,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    'in ${PrayerService.countdown(prayers.nextTime)}',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryRail extends StatelessWidget {
  const _CategoryRail({
    required this.posts,
    this.category,
    this.categoryName,
    this.subtitle,
  });

  final GuideCategory? category;
  final String? categoryName;
  final String? subtitle;
  final List<GuidePost> posts;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) return const SizedBox.shrink();
    final title = categoryName ?? category?.name ?? 'Guides';
    final sub = subtitle ??
        (category == null ? null : '${category!.totalCount} topics');
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: title,
            subtitle: sub,
            onSeeAll: category == null
                ? null
                : () => openCard(
                      context,
                      CategoryScreen(category: category!),
                    ),
          ),
          HorizontalPostScroller(
            posts: posts,
            onOpen: (post) => openCard(context, PostDetailScreen(post: post)),
          ),
        ],
      ),
    );
  }
}

class _EatNearbyRail extends StatelessWidget {
  const _EatNearbyRail({required this.places, required this.loading});

  final List<Restaurant> places;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
        child: Text(
          loading ? 'Restaurants are loading…' : 'No restaurants nearby yet.',
          style: const TextStyle(color: AppColors.muted, fontSize: 13),
        ),
      );
    }
    return SizedBox(
      height: 178,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        itemCount: places.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final place = places[index];
          return PressableScale(
            onTap: () {
              AppAnalytics.instance.open(
                section: 'eat',
                targetId: place.id,
                title: place.name,
                category: 'nearby',
              );
              openCard(
                context,
                RestaurantDetailScreen(place: place),
              );
            },
            child: SizedBox(
              width: 148,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: SizedBox(
                      height: 108,
                      width: 148,
                      child: CachedNetworkImage(
                        imageUrl: foodPhotoFor(place),
                        httpHeaders: foodPhotoHeaders(foodPhotoFor(place)),
                        fit: BoxFit.cover,
                        placeholder: (_, __) => ColoredBox(
                          color: cuisineColor(place.kind).withValues(alpha: 0.3),
                        ),
                        errorWidget: (_, __, ___) => ColoredBox(
                          color: cuisineColor(place.kind).withValues(alpha: 0.35),
                          child: Icon(
                            Icons.restaurant_rounded,
                            color: cuisineColor(place.kind),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    place.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  Text(
                    [
                      cuisineTitle(place.kind),
                      if (place.km > 0)
                        '${place.km < 10 ? place.km.toStringAsFixed(1) : place.km.toStringAsFixed(0)} km',
                    ].join('  ·  '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.muted, fontSize: 11),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DailyKsaGrid extends StatelessWidget {
  const _DailyKsaGrid({required this.categories, required this.loading});

  final List<ShopCategory> categories;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty && loading) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(20, 4, 20, 16),
        child: Text(
          'Loading shops…',
          style: TextStyle(color: AppColors.muted, fontSize: 13),
        ),
      );
    }
    if (categories.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: GridView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: categories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.68,
        ),
        itemBuilder: (context, index) {
          final category = categories[index];
          return _DailyBrandTile(
            category: category,
            brands: ShopRepository.instance.previewMerchants(category.id),
          );
        },
      ),
    );
  }
}

class _DailyBrandTile extends StatelessWidget {
  const _DailyBrandTile({required this.category, required this.brands});

  final ShopCategory category;
  final List<ShopMerchant> brands;

  @override
  Widget build(BuildContext context) {
    final fallback = category.icon.isNotEmpty ? category.icon : category.image;
    final hero = brands.isNotEmpty ? brands.first : null;
    final extras = brands.skip(1).take(3).toList();
    return PressableScale(
      borderRadius: BorderRadius.circular(16),
      onTap: () => openCard(context, ShopCategoryScreen(category: category)),
      child: Container(
        padding: const EdgeInsets.fromLTRB(7, 7, 7, 6),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: _BrandMark(
                url: hero?.icon.isNotEmpty == true
                    ? hero!.icon
                    : (hero?.image ?? fallback),
                size: 34,
                radius: 10,
              ),
            ),
            if (extras.isNotEmpty) ...[
              const SizedBox(height: 5),
              Row(
                children: [
                  for (var i = 0; i < extras.length; i++) ...[
                    if (i > 0) const SizedBox(width: 3),
                    Expanded(
                      child: _BrandMark(
                        url: extras[i].icon.isNotEmpty
                            ? extras[i].icon
                            : extras[i].image,
                        size: 18,
                        radius: 5,
                      ),
                    ),
                  ],
                ],
              ),
            ],
            const Spacer(),
            Text(
              category.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 10.5,
                height: 1.1,
              ),
            ),
            Text(
              '${category.merchantCount} shops',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.w700,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.url, required this.size, required this.radius});

  final String url;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: url.isEmpty
          ? SizedBox(
              width: size,
              height: size,
              child: const ColoredBox(
                color: AppColors.bg,
                child: Icon(Icons.storefront_rounded, color: AppColors.gold, size: 14),
              ),
            )
          : CachedNetworkImage(
              imageUrl: url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => SizedBox(
                width: size,
                height: size,
                child: const ColoredBox(
                  color: AppColors.bg,
                  child: Icon(Icons.storefront_rounded, color: AppColors.gold, size: 14),
                ),
              ),
            ),
    );
  }
}

class _HealthNearbyRail extends StatelessWidget {
  const _HealthNearbyRail({required this.places, required this.loading});

  final List<HealthFacility> places;
  final bool loading;

  IconData _iconFor(String kind) {
    switch (kind) {
      case 'hospital':
        return Icons.local_hospital_rounded;
      case 'pharmacy':
        return Icons.local_pharmacy_rounded;
      case 'health_centre':
        return Icons.apartment_rounded;
      default:
        return Icons.medical_services_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
        child: Text(
          loading ? 'Clinics are loading…' : 'No clinics nearby yet.',
          style: const TextStyle(color: AppColors.muted, fontSize: 13),
        ),
      );
    }
    final width = (MediaQuery.sizeOf(context).width - 32 - 16) / 3;
    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        itemCount: places.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final place = places[index];
          final km = place.km > 0
              ? '${place.km < 10 ? place.km.toStringAsFixed(1) : place.km.toStringAsFixed(0)} km'
              : '';
          return PressableScale(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              AppAnalytics.instance.open(
                section: 'healthcare',
                targetId: place.id,
                title: place.name,
                category: 'nearby',
              );
              openCard(context, HealthcareDetailScreen(place: place));
            },
            child: Container(
              width: width,
              padding: const EdgeInsets.fromLTRB(9, 9, 9, 8),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.stroke),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          color: AppColors.bg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _iconFor(place.kind),
                          size: 14,
                          color: AppColors.green,
                        ),
                      ),
                      if (place.emergency) ...[
                        const SizedBox(width: 4),
                        const Text(
                          'ER',
                          style: TextStyle(
                            color: AppColors.red,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    place.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      height: 1.15,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    [
                      healthKindTitle(place.kind),
                      if (km.isNotEmpty) km,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                  if (place.city.isNotEmpty)
                    Text(
                      place.city,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                      ),
                    ),
                  if (place.phone.isNotEmpty)
                    Text(
                      place.phone,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SchoolNearbyRail extends StatelessWidget {
  const _SchoolNearbyRail({required this.schools, required this.loading});

  final List<School> schools;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (schools.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
        child: Text(
          loading
              ? 'Schools are loading…'
              : 'No international schools nearby yet.',
          style: const TextStyle(color: AppColors.muted, fontSize: 13),
        ),
      );
    }
    final width = (MediaQuery.sizeOf(context).width - 32 - 16) / 3;
    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        itemCount: schools.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final school = schools[index];
          return PressableScale(
            onTap: () {
              AppAnalytics.instance.open(
                section: 'schools',
                targetId: school.id,
                title: school.name,
                category: 'nearby',
              );
              openCard(context, SchoolDetailScreen(school: school));
            },
            child: Container(
              width: width,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.stroke),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SchoolPhoto(
                    school: school,
                    width: width,
                    height: 68,
                    radius: 0,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          school.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 11.5,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [
                            schoolFeeLabel(school),
                            if (school.km > 0)
                              '${school.km < 10 ? school.km.toStringAsFixed(1) : school.km.toStringAsFixed(0)} km',
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                            color: AppColors.gold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
