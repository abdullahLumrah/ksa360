import 'package:flutter/material.dart';

import '../../../../data/app_analytics.dart';
import '../../../../data/life_settings.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/category_widgets.dart';
import '../../../../widgets/motion.dart';
import '../../domain/souq_categories.dart';
import '../../domain/souq_models.dart';
import '../souq_controller.dart';
import '../souq_l10n.dart';
import '../souq_motion.dart';
import '../widgets/souq_ad_card.dart';
import '../widgets/souq_widgets.dart';
import 'souq_category_screen.dart';
import '../souq_sell.dart';
import 'souq_search_screen.dart';

class SouqHomeScreen extends StatefulWidget {
  const SouqHomeScreen({super.key});

  @override
  State<SouqHomeScreen> createState() => _SouqHomeScreenState();
}

class _SouqHomeScreenState extends State<SouqHomeScreen> {
  final _scroll = ScrollController();
  List<Ad> _featured = [];
  List<Ad> _recent = [];
  List<Ad> _near = [];
  double _featuredPage = 0;

  @override
  void initState() {
    super.initState();
    SouqController.instance.addListener(_onCtrl);
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    await SouqController.instance.ensureReady();
    await _load();
  }

  Future<void> _load() async {
    final repo = SouqController.instance.repo;
    final city = LifeSettings.instance.city.name;
    final featured = await repo.featuredCars();
    final recent = await repo.recentlyAdded();
    final near = await repo.nearCity(city);
    if (!mounted) return;
    setState(() {
      _featured = featured;
      _recent = recent;
      _near = near;
    });
  }

  void _onCtrl() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _scroll.dispose();
    SouqController.instance.removeListener(_onCtrl);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = SouqL10n.of(context);
    final ctrl = SouqController.instance;
    final pad = MediaQuery.paddingOf(context);
    final restCats = SouqCatalog.all
        .where((c) => c.id != SouqCatalog.cars)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        color: AppColors.green,
        onRefresh: _load,
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              toolbarHeight: 56,
              backgroundColor: AppColors.bg,
              automaticallyImplyLeading: false,
              titleSpacing: 12,
              title: _HeroHeader(
                onFavorites: () => openSouqFavorites(context),
                onMyAds: () => openSouqMyAds(context),
                onChats: () => openSouqChats(context),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Material(
                        color: AppColors.card,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppColors.stroke),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () =>
                              openCard(context, const SouqSearchScreen()),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.search_rounded, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    l10n.searchHint,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      height: 1.1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () => openSouqSell(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: Text(
                        l10n.placeAd,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (ctrl.loadError != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(ctrl.loadError!),
                ),
              ),
            SliverToBoxAdapter(
              child: SouqMotion.fadeOnly(
                context: context,
                child: SectionHeader(
                  title: l10n.categories,
                  subtitle: l10n.categoriesSub,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SouqMotion.fadeOnly(
                context: context,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: SizedBox(
                    height: 148,
                    child: SouqCategoryTile(
                      category: SouqCatalog.byId(SouqCatalog.cars),
                      featured: true,
                      onTap: () {
                        AppAnalytics.instance.category('souq', SouqCatalog.cars);
                        openCard(
                          context,
                          SouqCategoryScreen(categoryId: SouqCatalog.cars),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SouqMotion.fadeOnly(
                context: context,
                delay: const Duration(milliseconds: 60),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: GridView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: restCats.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.86,
                    ),
                    itemBuilder: (context, i) {
                      final cat = restCats[i];
                      return SouqCategoryTile(
                        category: cat,
                        onTap: () {
                          AppAnalytics.instance.category('souq', cat.id);
                          openCard(
                            context,
                            SouqCategoryScreen(categoryId: cat.id),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
            if (_featured.isNotEmpty)
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: l10n.featured,
                  subtitle: l10n.featuredSub,
                ),
              ),
            if (_featured.isNotEmpty)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 296,
                  child: PageView.builder(
                    controller: PageController(viewportFraction: 0.88),
                    itemCount: _featured.length,
                    onPageChanged: (i) => setState(() => _featuredPage = i.toDouble()),
                    itemBuilder: (context, i) {
                      return Padding(
                        padding: const EdgeInsetsDirectional.only(end: 12),
                        child: SouqAdCard(
                          ad: _featured[i],
                          wide: true,
                          heroPrefix: 'feat',
                        ),
                      );
                    },
                  ),
                ),
              ),
            if (_featured.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: WormDots(
                    count: _featured.length,
                    index: _featuredPage,
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: SectionHeader(
                title: l10n.recent,
                subtitle: l10n.recentSub,
              ),
            ),
            if (_recent.isEmpty && ctrl.ready)
              const SliverToBoxAdapter(
                child: SouqEmpty(title: 'No ads yet'),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.62,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => SouqAdCard(ad: _recent[i], heroPrefix: 'home'),
                    childCount: _recent.length,
                  ),
                ),
              ),
            if (_near.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: l10n.nearYou,
                  subtitle: LifeSettings.instance.city.name,
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 268,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: _near.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) => SizedBox(
                      width: 196,
                      child: SouqAdCard(ad: _near[i], heroPrefix: 'near'),
                    ),
                  ),
                ),
              ),
            ],
            SliverToBoxAdapter(child: SizedBox(height: pad.bottom + 120)),
          ],
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.onFavorites,
    required this.onMyAds,
    required this.onChats,
  });
  final VoidCallback onFavorites;
  final VoidCallback onMyAds;
  final VoidCallback onChats;

  @override
  Widget build(BuildContext context) {
    final l10n = SouqL10n.of(context);
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.greenDeep, AppColors.green],
            ),
          ),
          child: const Icon(
            Icons.storefront_rounded,
            color: AppColors.goldBright,
            size: 16,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.souq,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  height: 1.1,
                ),
              ),
              Text(
                l10n.greeting,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
        _HeaderIcon(
          tooltip: l10n.favorites,
          icon: Icons.favorite_outline_rounded,
          onTap: onFavorites,
        ),
        _HeaderIcon(
          tooltip: l10n.chats,
          icon: Icons.chat_bubble_outline_rounded,
          onTap: onChats,
        ),
        _HeaderIcon(
          tooltip: l10n.myAds,
          icon: Icons.storefront_outlined,
          onTap: onMyAds,
        ),
      ],
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 30, height: 30),
      iconSize: 18,
      onPressed: onTap,
      icon: Icon(icon, color: AppColors.navy),
    );
  }
}
