import 'package:flutter/material.dart';

import '../../../../data/app_analytics.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/app_filter_chip.dart';
import '../../domain/souq_categories.dart';
import '../../domain/souq_models.dart';
import '../souq_controller.dart';
import '../souq_l10n.dart';
import '../souq_sell.dart';
import '../widgets/souq_ad_card.dart';
import '../widgets/souq_filters_sheet.dart';
import '../widgets/souq_widgets.dart';

class SouqCategoryScreen extends StatefulWidget {
  const SouqCategoryScreen({super.key, required this.categoryId, this.make});
  final String categoryId;
  final String? make;

  @override
  State<SouqCategoryScreen> createState() => _SouqCategoryScreenState();
}

class _SouqCategoryScreenState extends State<SouqCategoryScreen> {
  late SearchFilters _filters;
  final _items = <Ad>[];
  int _total = 0;
  int _page = 0;
  bool _loading = true;
  bool _grid = true;
  final _scroll = ScrollController();
  List<String> _makes = [];

  SouqCategory get cat => SouqCatalog.byId(widget.categoryId);

  @override
  void initState() {
    super.initState();
    _filters = SearchFilters(
      categoryId: widget.categoryId,
      attributes: {
        if (widget.make != null) 'make': widget.make,
      },
    );
    _scroll.addListener(() {
      if (_scroll.position.pixels >
          _scroll.position.maxScrollExtent - 420) {
        _more();
      }
    });
    _boot();
  }

  Future<void> _boot() async {
    await SouqController.instance.ensureReady();
    AppAnalytics.instance.category('souq', widget.categoryId);
    _makes = await SouqController.instance.repo.makes();
    await _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _page = 0;
      _items.clear();
    });
    final page = await SouqController.instance.search(_filters, page: 0);
    if (!mounted) return;
    setState(() {
      _items.addAll(page.items);
      _total = page.total;
      _loading = false;
    });
  }

  Future<void> _more() async {
    if (_loading || _items.length >= _total) return;
    _loading = true;
    final next = _page + 1;
    final page = await SouqController.instance.search(_filters, page: next);
    if (!mounted) return;
    setState(() {
      _page = next;
      _items.addAll(page.items);
      _loading = false;
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = SouqL10n.of(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        controller: _scroll,
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 168,
            backgroundColor: cat.gradient.first,
            iconTheme: const IconThemeData(color: AppColors.onDark),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                cat.name(l10n.ar),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.onDark,
                ),
              ),
              background: Hero(
                tag: 'cat-photo-${cat.id}',
                child: Material(
                  type: MaterialType.transparency,
                  child: SouqCategoryBackdrop(category: cat),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat.name(!l10n.ar),
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.adsCount(_total, cat.name(l10n.ar).toLowerCase()),
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: AppFilterChip(
                      selected: _filters.subcategoryId == null,
                      label: 'All',
                      onSelected: (_) {
                        _filters = _filters.copyWith(clearSubcategory: true);
                        _reload();
                      },
                    ),
                  ),
                  for (final sub in cat.subcategories)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: AppFilterChip(
                        selected: _filters.subcategoryId == sub.id,
                        label: sub.name(l10n.ar),
                        onSelected: (on) {
                          _filters = _filters.copyWith(
                            subcategoryId: on ? sub.id : null,
                            clearSubcategory: !on,
                          );
                          _reload();
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (cat.id == SouqCatalog.cars && _makes.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.browseMake,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _makes.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, i) {
                          final make = _makes[i];
                          final selected = _filters.attributes['make'] == make;
                          return MakeAvatar(
                            make: make,
                            selected: selected,
                            onTap: () {
                              final attrs =
                                  Map<String, dynamic>.from(_filters.attributes);
                              if (selected) {
                                attrs.remove('make');
                              } else {
                                attrs['make'] = make;
                              }
                              _filters = _filters.copyWith(attributes: attrs);
                              _reload();
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  PopupMenuButton<AdSort>(
                    initialValue: _filters.sort,
                    onSelected: (s) {
                      _filters = _filters.copyWith(sort: s);
                      _reload();
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(value: AdSort.newest, child: Text(l10n.newest)),
                      PopupMenuItem(value: AdSort.priceAsc, child: Text(l10n.priceUp)),
                      PopupMenuItem(value: AdSort.priceDesc, child: Text(l10n.priceDown)),
                      if (cat.id == SouqCatalog.cars)
                        PopupMenuItem(
                          value: AdSort.mileageDesc,
                          child: Text(l10n.mileageDown),
                        ),
                      if (cat.id == SouqCatalog.cars)
                        PopupMenuItem(
                          value: AdSort.yearDesc,
                          child: Text(l10n.yearDown),
                        ),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.sort_rounded),
                          const SizedBox(width: 6),
                          Text(l10n.sort),
                        ],
                      ),
                    ),
                  ),
                  Badge(
                    isLabelVisible: _filters.activeCount > 0,
                    label: Text('${_filters.activeCount}'),
                    child: IconButton(
                      onPressed: () async {
                        final next = await showSouqFilters(
                          context,
                          current: _filters,
                        );
                        if (next != null) {
                          _filters = next;
                          _reload();
                        }
                      },
                      icon: const Icon(Icons.tune_rounded),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => setState(() => _grid = !_grid),
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      child: Icon(
                        _grid ? Icons.view_list_rounded : Icons.grid_view_rounded,
                        key: ValueKey(_grid),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!_loading && _items.isEmpty)
            SliverToBoxAdapter(
              child: SouqEmpty(
                title: l10n.emptyCat,
                action: l10n.postAd,
                onAction: () => openSouqSell(context, categoryId: cat.id),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              sliver: _grid
                  ? SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        // Cars cards include a specs row — give them a bit more height.
                        childAspectRatio:
                            cat.id == SouqCatalog.cars ? 0.56 : 0.62,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          if (i >= _items.length) {
                            return const SouqShimmerCard();
                          }
                          return SouqAdCard(ad: _items[i], heroPrefix: 'cat');
                        },
                        childCount: _items.length + (_loading ? 2 : 0),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: SouqAdCard(
                              ad: _items[i],
                              wide: true,
                              heroPrefix: 'cat',
                            ),
                          );
                        },
                        childCount: _items.length,
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}
