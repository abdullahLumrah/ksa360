import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
import '../souq_sell.dart';
import '../../domain/souq_categories.dart';
import '../../domain/souq_models.dart';
import '../souq_controller.dart';
import '../souq_format.dart';
import '../souq_l10n.dart';
import '../widgets/souq_ad_card.dart';

class SouqSearchScreen extends StatefulWidget {
  const SouqSearchScreen({super.key});

  @override
  State<SouqSearchScreen> createState() => _SouqSearchScreenState();
}

class _SouqSearchScreenState extends State<SouqSearchScreen> {
  final _ctrl = TextEditingController();
  final _recent = <String>[];
  List<String> _suggest = [];
  List<Ad> _results = [];
  Timer? _debounce;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    SouqController.instance.ensureReady();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _run(q));
  }

  Future<void> _run(String q) async {
    setState(() => _loading = true);
    final repo = SouqController.instance.repo;
    final suggest = await repo.suggest(q);
    final page = await repo.search(SearchFilters(query: q), pageSize: 40);
    if (!mounted) return;
    setState(() {
      _suggest = suggest;
      _results = page.items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = SouqL10n.of(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l10n.searchHint,
            border: InputBorder.none,
          ),
          onChanged: _onChanged,
          onSubmitted: (q) {
            if (q.trim().isEmpty) return;
            _recent.remove(q);
            _recent.insert(0, q);
            _run(q);
          },
        ),
        actions: [
          TextButton.icon(
            onPressed: () => openSouqSell(context),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(l10n.placeAd),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (_ctrl.text.isEmpty) ...[
            const Text('Recent', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            if (_recent.isEmpty)
              const Text('Start typing to search cars and local ads.',
                  style: TextStyle(color: AppColors.muted))
            else
              Wrap(
                spacing: 8,
                children: _recent
                    .map(
                      (r) => ActionChip(
                        label: Text(r),
                        onPressed: () {
                          _ctrl.text = r;
                          _run(r);
                        },
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 18),
            const Text('Trending makes',
                style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['Toyota', 'Lexus', 'Hyundai', 'Ford', 'Kia']
                  .map(
                    (m) => ActionChip(
                      label: Text(m),
                      onPressed: () {
                        _ctrl.text = m;
                        _run(m);
                      },
                    ),
                  )
                  .toList(),
            ),
          ],
          if (_suggest.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final s in _suggest)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.search_rounded),
                title: _highlight(s, _ctrl.text),
                onTap: () {
                  _ctrl.text = s;
                  _run(s);
                },
              ),
          ],
          if (_loading) const LinearProgressIndicator(),
          if (_results.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final ad in _results)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      SouqCatalog.byId(ad.categoryId).name(l10n.ar),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SouqAdCard(ad: ad, wide: true, heroPrefix: 'search'),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _highlight(String text, String q) {
    if (q.isEmpty) return Text(text);
    final nText = SouqFormat.normalizeSearch(text);
    final nQ = SouqFormat.normalizeSearch(q);
    final i = nText.indexOf(nQ);
    if (i < 0) return Text(text);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: text.substring(0, i.clamp(0, text.length))),
          TextSpan(
            text: text.substring(i, (i + q.length).clamp(0, text.length)),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.green,
            ),
          ),
          TextSpan(text: text.substring((i + q.length).clamp(0, text.length))),
        ],
      ),
    );
  }
}
