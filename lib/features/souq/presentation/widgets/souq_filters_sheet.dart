import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../data/saudi_cities.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/souq_categories.dart';
import '../../domain/souq_models.dart';
import '../souq_controller.dart';
import '../souq_format.dart';
import '../souq_l10n.dart';
import 'souq_widgets.dart';

Future<SearchFilters?> showSouqFilters(
  BuildContext context, {
  required SearchFilters current,
}) {
  return showModalBottomSheet<SearchFilters>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => SouqFiltersSheet(initial: current),
  );
}

class SouqFiltersSheet extends StatefulWidget {
  const SouqFiltersSheet({super.key, required this.initial});
  final SearchFilters initial;

  @override
  State<SouqFiltersSheet> createState() => _SouqFiltersSheetState();
}

class _SouqFiltersSheetState extends State<SouqFiltersSheet> {
  late SearchFilters _f;
  int _count = 0;
  List<double> _prices = [];
  Timer? _debounce;
  int _shake = 0;

  @override
  void initState() {
    super.initState();
    _f = widget.initial;
    _refreshCount();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _set(SearchFilters next) {
    setState(() => _f = next);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), _refreshCount);
  }

  Future<void> _refreshCount() async {
    final repo = SouqController.instance.repo;
    final n = await repo.count(_f);
    final hist = await repo.priceHistogram(_f);
    if (!mounted) return;
    setState(() {
      _count = n;
      _prices = hist;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = SouqL10n.of(context);
    final cat = _f.categoryId == null ? null : SouqCatalog.byId(_f.categoryId!);
    final maxH = MediaQuery.sizeOf(context).height * 0.9;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: maxH,
          color: AppColors.card.withValues(alpha: 0.96),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.stroke,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                child: Row(
                  children: [
                    Text(
                      l10n.filters,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        if (_f.activeCount == 0) {
                          HapticFeedback.mediumImpact();
                          setState(() => _shake++);
                          return;
                        }
                        _set(SearchFilters(
                          categoryId: _f.categoryId,
                          query: _f.query,
                          sort: _f.sort,
                        ));
                      },
                      child: Text(l10n.reset),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    Text(l10n.price, style: _h),
                    const SizedBox(height: 8),
                    _Histogram(values: _prices),
                    RangeSlider(
                      values: RangeValues(
                        _f.minPrice ?? 0,
                        _f.maxPrice ?? 400000,
                      ),
                      min: 0,
                      max: 400000,
                      divisions: 40,
                      labels: RangeLabels(
                        SouqFormat.compactSar(_f.minPrice ?? 0),
                        SouqFormat.compactSar(_f.maxPrice ?? 400000),
                      ),
                      onChanged: (v) => _set(_f.copyWith(
                        minPrice: v.start <= 0 ? null : v.start,
                        clearMinPrice: v.start <= 0,
                        maxPrice: v.end >= 400000 ? null : v.end,
                        clearMaxPrice: v.end >= 400000,
                      )),
                    ),
                    const SizedBox(height: 12),
                    Text(l10n.city, style: _h),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: SaudiCities.all.take(18).map((c) {
                        final on = _f.cities.contains(c.name);
                        return FilterChip(
                          selected: on,
                          label: Text(c.name),
                          onSelected: (v) {
                            final next = [..._f.cities];
                            if (v) {
                              next.add(c.name);
                            } else {
                              next.remove(c.name);
                            }
                            _set(_f.copyWith(cities: next));
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Text(l10n.condition, style: _h),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: AdCondition.values.map((c) {
                        return ChoiceChip(
                          selected: _f.condition == c,
                          label: Text(SouqFormat.conditionLabel(c, ar: l10n.ar)),
                          onSelected: (v) => _set(_f.copyWith(
                            condition: v ? c : null,
                            clearCondition: !v,
                          )),
                        );
                      }).toList(),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.withPhotos),
                      value: _f.photosOnly,
                      onChanged: (v) => _set(_f.copyWith(photosOnly: v)),
                    ),
                    if (cat != null)
                      for (final field in cat.fields)
                        if (field.type == AttributeType.chips ||
                            field.type == AttributeType.dropdown)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.ar ? field.labelAr : field.labelEn, style: _h),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: field.options.map((o) {
                                    final on = '${_f.attributes[field.key] ?? ''}' == o;
                                    return ChoiceChip(
                                      selected: on,
                                      label: Text(o),
                                      onSelected: (v) {
                                        final attrs = Map<String, dynamic>.from(_f.attributes);
                                        if (v) {
                                          attrs[field.key] = o;
                                        } else {
                                          attrs.remove(field.key);
                                        }
                                        _set(_f.copyWith(attributes: attrs));
                                      },
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                  ],
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.pop(context, _f),
                          child: CountingText(
                            value: _count,
                            builder: (n) => '${l10n.showResults} · $n',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _h = TextStyle(fontWeight: FontWeight.w800, fontSize: 15);
}

class _Histogram extends StatelessWidget {
  const _Histogram({required this.values});
  final List<double> values;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox(height: 36);
    const bins = 16;
    final maxP = 400000.0;
    final counts = List<int>.filled(bins, 0);
    for (final v in values) {
      final i = ((v / maxP) * (bins - 1)).clamp(0, bins - 1).round();
      counts[i]++;
    }
    final peak = counts.reduce((a, b) => a > b ? a : b).clamp(1, 999);
    return SizedBox(
      height: 36,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final c in counts)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: SizedBox(height: 36 * (c / peak)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
