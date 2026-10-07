import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../data/app_analytics.dart';
import '../data/shop_repository.dart';
import '../models/shop.dart';
import '../theme/app_theme.dart';
import '../widgets/category_widgets.dart';
import '../widgets/motion.dart';
import '../widgets/shop_merchant_card.dart';
import 'shop_category_screen.dart';

class ShopHomeScreen extends StatefulWidget {
  const ShopHomeScreen({super.key});

  @override
  State<ShopHomeScreen> createState() => _ShopHomeScreenState();
}

class _ShopHomeScreenState extends State<ShopHomeScreen> {
  final _query = TextEditingController();
  Timer? _debounce;
  List<ShopMerchant> _results = const [];
  List<ShopFilter> _filters = const [];
  String _filter = '';
  bool _searching = false;
  String? _searchError;

  bool get _showResults => _query.text.trim().isNotEmpty || _filter.isNotEmpty;

  @override
  void initState() {
    super.initState();
    ShopRepository.instance.refresh();
    AppAnalytics.instance.section('shops');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onQuery(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), _search);
    setState(() {});
  }

  Future<void> _search() async {
    if (!_showResults) {
      setState(() {
        _results = const [];
        _filters = const [];
        _searching = false;
        _searchError = null;
      });
      return;
    }
    setState(() {
      _searching = true;
      _searchError = null;
    });
    try {
      final result = await ShopRepository.instance.search(
        q: _query.text,
        filter: _filter,
      );
      if (!mounted) return;
      setState(() {
        _results = result.merchants;
        _filters = result.filters;
        _filter = result.filter;
        _searching = false;
        if (result.merchants.isEmpty) {
          _searchError = 'No shops match this search.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _searchError = 'Could not search shops. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ShopRepository.instance;
    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(title: const Text('Daily in KSA · Coupons & brands')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              const Text(
                'Shop apps used in Saudi Arabia. Open a shop for coupons. App opens Play Store on Android and the App Store on iPhone.',
                style: TextStyle(color: AppColors.muted, height: 1.4),
              ),
              const SizedBox(height: 12),
              ShopSearchField(
                controller: _query,
                onChanged: _onQuery,
                hint: 'Search all shops',
              ),
              if (_showResults) ...[
                if (_filters.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ShopFilterBar(
                    filters: _filters,
                    onSelected: (id) {
                      setState(() => _filter = id);
                      _search();
                    },
                  ),
                ],
                if (_searching)
                  const Padding(
                    padding: EdgeInsets.only(top: 28),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  if (_searchError != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _searchError!,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                  const SizedBox(height: 14),
                  for (final merchant in _results) ...[
                    ShopMerchantCard(merchant: merchant),
                    const SizedBox(height: 10),
                  ],
                ],
              ] else ...[
                const SizedBox(height: 16),
                const SectionHeader(
                  title: 'Shopping',
                  subtitle: 'Tap a category, then get a coupon',
                ),
                if (repo.categories.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      repo.refreshing
                          ? 'Loading shops…'
                          : repo.refreshError ?? 'No shopping categories yet.',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: repo.categories.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      mainAxisExtent: 132,
                    ),
                    itemBuilder: (context, index) {
                      final category = repo.categories[index];
                      return SizedBox.expand(
                        child: _ShopCategoryTile(
                          category: category,
                          onTap: () => openCard(
                            context,
                            ShopCategoryScreen(category: category),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class ShopCategoryTile extends StatelessWidget {
  const ShopCategoryTile({super.key, required this.category, required this.onTap});

  final ShopCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _ShopCategoryTile(category: category, onTap: onTap);
}

class _ShopCategoryTile extends StatelessWidget {
  const _ShopCategoryTile({required this.category, required this.onTap});

  final ShopCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final thumb = category.icon.isNotEmpty ? category.icon : category.image;
    return PressableScale(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: SizedBox.expand(
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.stroke),
          ),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: thumb.isEmpty
                      ? const ColoredBox(
                          color: AppColors.bg,
                          child: Icon(
                            Icons.storefront_rounded,
                            color: AppColors.gold,
                            size: 20,
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: thumb,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          memCacheWidth: 80,
                          errorWidget: (_, __, ___) => const ColoredBox(
                            color: AppColors.bg,
                            child: Icon(
                              Icons.storefront_rounded,
                              color: AppColors.gold,
                              size: 20,
                            ),
                          ),
                        ),
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 34,
                child: Text(
                  category.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    height: 1.15,
                  ),
                ),
              ),
              Text(
                [
                  '${category.merchantCount} shops',
                  if (category.couponCount > 0) '${category.couponCount} coupons',
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
