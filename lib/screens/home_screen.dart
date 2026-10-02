import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../data/activity_repository.dart';
import '../data/app_analytics.dart';
import '../data/app_tabs.dart';
import '../data/content_repository.dart';
import '../data/ksa_activities.dart';
import '../data/life_settings.dart';
import '../data/prayer_service.dart';
import '../data/restaurant_menus.dart';
import '../data/restaurant_repository.dart';
import '../models/models.dart';
import '../models/restaurant.dart';
import '../theme/app_theme.dart';
import '../widgets/category_widgets.dart';
import '../widgets/emergency_strip.dart';
import '../widgets/ksa360_mark.dart';
import '../widgets/motion.dart';
import '../widgets/post_cards.dart';
import 'category_screen.dart';
import 'emergency_screen.dart';
import 'explore_screen.dart';
import 'life_screen.dart';
import 'play_screen.dart';
import 'post_detail_screen.dart';
import 'restaurant_detail_screen.dart';

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
      ]),
      builder: (context, _) {
        final settings = LifeSettings.instance;
        final lifestyleGuides = repo.guidesForLifestyle(
          settings.lifestyle == Lifestyle.bachelor ? 'bachelor' : 'family',
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
                delay: const Duration(milliseconds: 80),
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
                  places: RestaurantRepository.instance.nearby(
                    lat: settings.prayerLat,
                    lng: settings.prayerLng,
                    preferCity: settings.city.name,
                    limit: 12,
                  ),
                ),
              ),
            ),
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
                child: PlayNearbyRail(
                  places: activitiesNear(
                    settings.prayerLat,
                    settings.prayerLng,
                    preferCity: settings.city.name,
                    limit: 10,
                  ),
                ),
              ),
            ),
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
            SliverToBoxAdapter(
              child: EmergencyStrip(
                onSeeAll: () => openCard(context, const EmergencyScreen()),
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
