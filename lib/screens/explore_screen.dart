import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../data/app_analytics.dart';
import '../data/app_search.dart';
import '../data/category_style.dart';
import '../data/content_repository.dart';
import '../data/dial.dart';
import '../data/emergencies.dart';
import '../data/life_settings.dart';
import '../data/restaurant_repository.dart';
import '../features/souq/domain/souq_models.dart';
import '../features/souq/presentation/screens/souq_ad_details_screen.dart';
import '../models/activity.dart';
import '../models/models.dart';
import '../models/restaurant.dart';
import '../theme/app_theme.dart';
import '../widgets/activity_photo.dart';
import '../widgets/category_widgets.dart';
import '../widgets/motion.dart';
import '../widgets/post_cards.dart';
import 'activity_detail_screen.dart';
import 'category_screen.dart';
import 'embassy_directory_screen.dart';
import 'post_detail_screen.dart';
import 'restaurant_detail_screen.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = ContentRepository.instance;
    final tops = repo.topCategories;
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          title: const Text('Categories'),
          automaticallyImplyLeading: false,
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Text(
              'Browse every topic. Open a category to see its guides as cards.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.muted,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.86,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final category = tops[index];
                return CategoryPhotoTile(
                  category: category,
                  onTap: () {
                    AppAnalytics.instance.category('guides', category.name);
                    openCard(
                      context,
                      CategoryScreen(category: category),
                    );
                  },
                );
              },
              childCount: tops.length,
            ),
          ),
        ),
        for (final top in tops)
          if (repo.childrenOf(top).isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                child: Text(
                  top.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.86,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final category = repo.childrenOf(top)[index];
                    return CategoryPhotoTile(
                      category: category,
                      cover: CategoryStyle.imageFor(top.slug),
                      onTap: () {
                        AppAnalytics.instance.category('guides', category.name);
                        openCard(
                          context,
                          CategoryScreen(category: category),
                        );
                      },
                    );
                  },
                  childCount: repo.childrenOf(top).length,
                ),
              ),
            ),
          ],
        const SliverToBoxAdapter(child: SizedBox(height: 96)),
      ],
    );
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.pushed = false});

  final bool pushed;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<AppSearchGroup> _groups = const [];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 160), () {
      if (!mounted) return;
      final query = value.trim();
      setState(() => _groups = AppSearch.groups(query));
      final settings = LifeSettings.instance;
      RestaurantRepository.instance.searchRemote(
        query,
        settings.prayerLat,
        settings.prayerLng,
      );
    });
  }

  void _openHit(AppSearchHit hit) {
    final data = hit.data;
    if (data is GuideCategory) {
      AppAnalytics.instance.category('guides', data.name);
      openCard(context, CategoryScreen(category: data));
    } else if (data is GuidePost) {
      AppAnalytics.instance.open(
        section: 'guides',
        targetId: data.id,
        title: data.title,
      );
      openCard(context, PostDetailScreen(post: data));
    } else if (data is Restaurant) {
      openCard(context, RestaurantDetailScreen(place: data));
    } else if (data is KsaActivity) {
      openCard(context, ActivityDetailScreen(activity: data));
    } else if (data is EmergencyNumber) {
      callNumber(data.number);
    } else if (data is Hospital) {
      callNumber(data.phone);
    } else if (data is Embassy) {
      openCard(context, EmbassyDirectoryScreen(initialQuery: data.country));
    } else if (data is Ad) {
      openCard(context, SouqAdDetailsScreen(adId: data.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: widget.pushed,
        title: const Text('Search'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _controller,
              autofocus: widget.pushed,
              onChanged: _onChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Guides, food, play, embassies…',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: AppColors.card,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.stroke),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.gold, width: 1.2),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.stroke),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: Listenable.merge([
                LifeSettings.instance,
                RestaurantRepository.instance,
              ]),
              builder: (context, _) {
                final query = _controller.text.trim();
                final groups = query.length < 2
                    ? const <AppSearchGroup>[]
                    : AppSearch.groups(query);
                if (query.isEmpty) {
                  return const Center(
                    child: Text(
                      'Try “iqama”, “shawarma”, “bowling” or “india embassy”.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted),
                    ),
                  );
                }
                final shown = groups.isNotEmpty ? groups : _groups;
                if (shown.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nothing matched in guides, eat, play or life.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.only(bottom: 96),
                  children: [
                    for (final group in shown) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
                        child: Text(
                          group.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            letterSpacing: 0.4,
                            color: AppColors.goldSoft,
                          ),
                        ),
                      ),
                      for (final hit in group.hits)
                        _GlobalHitTile(
                          hit: hit,
                          onTap: () => _openHit(hit),
                        ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GlobalHitTile extends StatelessWidget {
  const _GlobalHitTile({required this.hit, required this.onTap});

  final AppSearchHit hit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: PressableScale(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.stroke),
          ),
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              _thumb(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hit.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    if (hit.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        hit.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
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

  Widget _thumb() {
    const size = 56.0;
    final radius = BorderRadius.circular(14);
    if (hit.data is KsaActivity) {
      final activity = hit.data as KsaActivity;
      return ClipRRect(
        borderRadius: radius,
        child: SizedBox(
          width: size,
          height: size,
          child: ActivityPhoto(url: activity.image, kind: activity.kind),
        ),
      );
    }
    final url = hit.image;
    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: CachedNetworkImage(
          imageUrl: url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _iconThumb(radius),
        ),
      );
    }
    return _iconThumb(radius);
  }

  Widget _iconThumb(BorderRadius radius) {
    final icon = switch (hit.section) {
      AppSearchSection.category => Icons.grid_view_rounded,
      AppSearchSection.guide => Icons.menu_book_rounded,
      AppSearchSection.eat => Icons.restaurant_rounded,
      AppSearchSection.play => Icons.sports_esports_rounded,
      AppSearchSection.life => Icons.health_and_safety_rounded,
      AppSearchSection.souq => Icons.storefront_rounded,
    };
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.chip,
        borderRadius: radius,
      ),
      child: Icon(icon, color: AppColors.goldSoft),
    );
  }
}

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = ContentRepository.instance;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Saved'),
      ),
      body: ListenableBuilder(
        listenable: repo,
        builder: (context, _) {
          final posts = repo.savedPosts;
          if (posts.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Save guides you want to re-read.\nTap the heart on any article.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, height: 1.5),
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 96),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return PostListTileCard(
                post: post,
                onTap: () => openCard(
                  context,
                  PostDetailScreen(post: post),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
