import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/app_analytics.dart';
import '../data/activity_photos.dart';
import '../data/activity_repository.dart';
import '../data/activity_store.dart';
import '../data/ksa_activities.dart';
import '../data/life_settings.dart';
import '../models/activity.dart';
import '../theme/app_theme.dart';
import '../widgets/activity_photo.dart';
import '../widgets/category_widgets.dart';
import '../widgets/motion.dart';
import 'activity_detail_screen.dart';
import 'play_reels_screen.dart';

class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key});

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  final _search = TextEditingController();
  String _kind = 'all';
  String _sort = 'near';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _openActivity(KsaActivity item) {
    AppAnalytics.instance.open(
      section: 'play',
      targetId: item.id,
      title: item.name,
      category: item.kind,
    );
    openCard(context, ActivityDetailScreen(activity: item));
  }

  List<KsaActivity> _applySort(List<KsaActivity> places, String city) {
    var next = [...places];
    final prefer = city.toLowerCase();
    int cityRank(KsaActivity item) =>
        item.city.toLowerCase() == prefer ? 0 : 1;
    if (_sort == 'price') {
      next.sort((a, b) {
        final rank = cityRank(a).compareTo(cityRank(b));
        if (rank != 0) return rank;
        return a.priceFrom.compareTo(b.priceFrom);
      });
    } else if (_sort == 'saved') {
      final saved = ActivityStore.instance.saved;
      next = next.where((item) => saved.contains(item.id)).toList();
    }
    return next;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        LifeSettings.instance,
        ActivityStore.instance,
        ActivityRepository.instance,
      ]),
      builder: (context, _) {
        final settings = LifeSettings.instance;
        final places = _applySort(
          activitiesNear(
            settings.prayerLat,
            settings.prayerLng,
            kind: _kind,
            query: _search.text,
            preferCity: settings.city.name,
          ),
          settings.city.name,
        );
        final nearby = activitiesNear(
          settings.prayerLat,
          settings.prayerLng,
          preferCity: settings.city.name,
          limit: 10,
        );
        final groups = [
          for (final kind in activityKinds)
            if (activitiesInKind(places, kind.id).isNotEmpty) kind,
        ];
        final showBrowse = _search.text.isEmpty && _kind == 'all' && _sort != 'saved';

        return Scaffold(
          backgroundColor: AppColors.bg,
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    MediaQuery.paddingOf(context).top + 10,
                    16,
                    0,
                  ),
                  child: FadeSlideIn(
                    child: Material(
                      color: Colors.transparent,
                      child: TextField(
                        controller: _search,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText: 'Movies, bowling, karting, dunes…',
                          prefixIcon: Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: AppColors.card,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 52,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    scrollDirection: Axis.horizontal,
                    itemCount: activityKinds.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _KindChip(
                          label: '📍  All',
                          color: AppColors.green,
                          selected: _kind == 'all',
                          onTap: () {
                            setState(() => _kind = 'all');
                            AppAnalytics.instance.category('play', 'all');
                          },
                        );
                      }
                      final kind = activityKinds[index - 1];
                      return _KindChip(
                        label: '${kind.icon}  ${kind.title}',
                        color: Color(kind.color),
                        selected: _kind == kind.id,
                        onTap: () {
                          setState(() => _kind = kind.id);
                          AppAnalytics.instance.category('play', kind.id);
                        },
                      );
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Row(
                    children: [
                      _SortChip(
                        label: 'Nearby',
                        selected: _sort == 'near',
                        onTap: () => setState(() => _sort = 'near'),
                      ),
                      const SizedBox(width: 8),
                      _SortChip(
                        label: 'Cheapest',
                        selected: _sort == 'price',
                        onTap: () => setState(() => _sort = 'price'),
                      ),
                      const SizedBox(width: 8),
                      _SortChip(
                        label: 'Saved',
                        selected: _sort == 'saved',
                        onTap: () => setState(() => _sort = 'saved'),
                      ),
                      const Spacer(),
                      Text(
                        '${places.length} spots',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_search.text.isEmpty && _sort != 'saved')
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Reels',
                    subtitle: 'Swipe shorts · tap to open the activity',
                    onSeeAll: () => openCard(
                      context,
                      const PlayReelsScreen(),
                    ),
                  ),
                ),
              if (_search.text.isEmpty && _sort != 'saved')
                const SliverToBoxAdapter(child: PlayReelsStrip()),
              if (showBrowse)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.92,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final kind = activityKinds[index];
                        final count = ksaActivities
                            .where((item) => activityMatchesKind(item, kind.id))
                            .length;
                        return StaggerIn(
                          index: index,
                          child: _CategoryPoster(
                            kind: kind,
                            count: count,
                            onTap: () {
                              setState(() => _kind = kind.id);
                              AppAnalytics.instance.category('play', kind.id);
                            },
                          ),
                        );
                      },
                      childCount: activityKinds.length,
                    ),
                  ),
                ),
              if (showBrowse)
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Near you',
                    subtitle: settings.locationLabel,
                  ),
                ),
              if (showBrowse)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 268,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      scrollDirection: Axis.horizontal,
                      itemCount: nearby.take(8).length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final item = nearby[index];
                        return StaggerIn(
                          index: index,
                          child: SizedBox(
                            width: 188,
                            child: _PlayPoster(
                              activity: item,
                              useHero: false,
                              onTap: () => _openActivity(item),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              if (places.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 16, 20, 40),
                    child: Text(
                      'Nothing in this filter yet. Tap All or another category.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ),
                )
              else
                for (final kind in groups) ...[
                  SliverToBoxAdapter(
                    child: SectionHeader(
                      title: '${kind.icon}  ${kind.title}',
                      subtitle: () {
                        final items = activitiesInKind(places, kind.id);
                        final low = items
                            .map((item) => item.priceFrom)
                            .reduce((a, b) => a < b ? a : b);
                        return '${items.length} places · from $low SAR';
                      }(),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      kind.id == groups.last.id ? 110 : 12,
                    ),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.72,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item =
                              activitiesInKind(places, kind.id)[index];
                          return StaggerIn(
                            index: index,
                            child: _PlayPoster(
                              activity: item,
                              useHero: false,
                              onTap: () => _openActivity(item),
                            ),
                          );
                        },
                        childCount:
                            activitiesInKind(places, kind.id).length,
                      ),
                    ),
                  ),
                ],
            ],
          ),
        );
      },
    );
  }
}

class _KindChip extends StatelessWidget {
  const _KindChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.14) : AppColors.chip,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : AppColors.stroke),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.navy : AppColors.muted,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.gold.withValues(alpha: 0.18) : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.gold : AppColors.stroke,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.goldSoft : AppColors.muted,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _CategoryPoster extends StatelessWidget {
  const _CategoryPoster({
    required this.kind,
    required this.count,
    required this.onTap,
  });

  final ActivityKind kind;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ActivityPhoto(url: kindPhotoFor(kind.id), kind: kind.id),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x33000000), Color(0xE8000000)],
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${kind.icon}  ${kind.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.onDark,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    '$count places',
                    style: const TextStyle(
                      color: AppColors.goldBright,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayPoster extends StatelessWidget {
  const _PlayPoster({
    required this.activity,
    required this.onTap,
    this.useHero = true,
  });

  final KsaActivity activity;
  final VoidCallback onTap;
  final bool useHero;

  @override
  Widget build(BuildContext context) {
    final store = ActivityStore.instance;
    final saved = store.isSaved(activity.id);
    return PressableScale(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ActivityPhoto(
              url: activityPhotoFor(activity),
              kind: activity.kind,
              heroTag: useHero ? 'activity-image-${activity.id}' : null,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x14000000), Color(0xF2000000)],
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    store.toggle(activity.id);
                  },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: Icon(
                      saved
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      key: ValueKey(saved),
                      color: saved ? AppColors.red : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.city,
                    style: const TextStyle(
                      color: AppColors.goldBright,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    activity.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.onDark,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activity.fromLabel,
                    style: const TextStyle(
                      color: AppColors.onDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlayNearbyRail extends StatelessWidget {
  const PlayNearbyRail({super.key, required this.places});

  final List<KsaActivity> places;

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 268,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        itemCount: places.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = places[index];
          return StaggerIn(
            index: index,
            child: SizedBox(
              width: 188,
              child: _PlayPoster(
                activity: item,
                useHero: false,
                onTap: () {
                  AppAnalytics.instance.open(
                    section: 'play',
                    targetId: item.id,
                    title: item.name,
                    category: item.kind,
                  );
                  openCard(context, ActivityDetailScreen(activity: item));
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
