import 'dart:async';

import 'package:flutter/material.dart';

import '../data/app_analytics.dart';
import '../data/shop_repository.dart';
import '../models/shop.dart';
import '../theme/app_theme.dart';
import '../widgets/shop_merchant_card.dart';

class ShopCategoryScreen extends StatefulWidget {
  const ShopCategoryScreen({super.key, required this.category});

  final ShopCategory category;

  @override
  State<ShopCategoryScreen> createState() => _ShopCategoryScreenState();
}

class _ShopCategoryScreenState extends State<ShopCategoryScreen> {
  final _query = TextEditingController();
  Timer? _debounce;
  List<ShopMerchant> _merchants = const [];
  List<ShopFilter> _filters = const [];
  String _filter = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    AppAnalytics.instance.category('shops', widget.category.id);
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onQuery(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), _load);
    setState(() {});
  }

  Future<void> _load() async {
    if (mounted && (!_loading || _error != null)) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final result = await ShopRepository.instance.search(
        q: _query.text,
        category: widget.category.id,
        filter: _filter,
      );
      if (!mounted) return;
      setState(() {
        _merchants = result.merchants;
        _filters = result.filters;
        _filter = result.filter;
        _loading = false;
        if (result.merchants.isEmpty) {
          _error = 'No shops match this search.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load shops. Check the connection and try again.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(widget.category.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          if (widget.category.blurb.isNotEmpty)
            Text(
              widget.category.blurb,
              style: const TextStyle(color: AppColors.muted, height: 1.4),
            ),
          const SizedBox(height: 12),
          ShopSearchField(
            controller: _query,
            onChanged: _onQuery,
            hint: 'Search ${widget.category.name}',
          ),
          if (_filters.isNotEmpty) ...[
            const SizedBox(height: 12),
            ShopFilterBar(
              filters: _filters,
              onSelected: (id) {
                setState(() => _filter = id);
                _load();
              },
            ),
          ],
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 28),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: AppColors.muted)),
              if (_merchants.isEmpty)
                TextButton(
                  onPressed: _load,
                  child: const Text('Try again'),
                ),
            ],
            const SizedBox(height: 14),
            for (final merchant in _merchants) ...[
              ShopMerchantCard(merchant: merchant),
              const SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
  }
}
