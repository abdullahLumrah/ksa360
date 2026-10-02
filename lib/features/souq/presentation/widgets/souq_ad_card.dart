import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../theme/app_theme.dart';
import '../../../../widgets/motion.dart';
import '../../domain/souq_categories.dart';
import '../../domain/souq_models.dart';
import '../souq_controller.dart';
import '../souq_format.dart';
import '../souq_l10n.dart';
import '../souq_motion.dart';
import '../souq_sell.dart';
import '../screens/souq_ad_details_screen.dart';

class SouqAdCard extends StatefulWidget {
  const SouqAdCard({
    super.key,
    required this.ad,
    this.wide = false,
    this.heroPrefix = 'ad',
  });

  final Ad ad;
  final bool wide;
  final String heroPrefix;

  @override
  State<SouqAdCard> createState() => _SouqAdCardState();
}

class _SouqAdCardState extends State<SouqAdCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _heart;
  bool _burst = false;

  @override
  void initState() {
    super.initState();
    _heart = AnimationController(vsync: this, duration: SouqMotion.favorite);
  }

  @override
  void dispose() {
    _heart.dispose();
    super.dispose();
  }

  Future<void> _fav({bool fromImage = false}) async {
    HapticFeedback.lightImpact();
    await toggleSouqFavorite(context, widget.ad.id);
    if (!mounted) return;
    if (fromImage && SouqController.instance.isFavorite(widget.ad.id)) {
      setState(() => _burst = true);
      _heart.forward(from: 0);
      Future<void>.delayed(const Duration(milliseconds: 700), () {
        if (mounted) setState(() => _burst = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SouqController.instance,
      builder: (context, _) {
        final l10n = SouqL10n.of(context);
        final ad = widget.ad;
    final fav = SouqController.instance.isFavorite(ad.id);
    final sold = ad.isSold;

    return PressableScale(
      scale: 0.97,
      onTap: () => openCard(
        context,
        SouqAdDetailsScreen(adId: ad.id, heroTag: '${widget.heroPrefix}-${ad.id}'),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.stroke),
          boxShadow: AppShadows.card,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: widget.wide ? 168 : 132,
                child: GestureDetector(
                  onDoubleTap: () => _fav(fromImage: true),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: '${widget.heroPrefix}-${ad.id}',
                        child: ColorFiltered(
                          colorFilter: sold
                              ? const ColorFilter.matrix(<double>[
                                  0.33, 0.33, 0.33, 0, 0,
                                  0.33, 0.33, 0.33, 0, 0,
                                  0.33, 0.33, 0.33, 0, 0,
                                  0, 0, 0, 1, 0,
                                ])
                              : const ColorFilter.mode(
                                  Colors.transparent,
                                  BlendMode.dst,
                                ),
                          child: SouqCover(ad: ad),
                        ),
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0x99000000)],
                          ),
                        ),
                      ),
                      PositionedDirectional(
                        top: 8,
                        start: 8,
                        child: Wrap(
                          spacing: 6,
                          children: [
                            if (ad.isFeatured)
                              const _Badge(
                                text: 'Featured',
                                colors: [Color(0xFFF59E0B), Color(0xFF8A5E2E)],
                              ),
                            if (ad.isHaraj)
                              _Badge(
                                text: l10n.haraj,
                                colors: const [Color(0xFF1E7A4C), Color(0xFF143D2C)],
                              ),
                            if (ad.isExpat)
                              _Badge(
                                text: l10n.expatriates,
                                colors: const [Color(0xFF0F4C5C), Color(0xFF2DD4BF)],
                              ),
                          ],
                        ),
                      ),
                      PositionedDirectional(
                        top: 4,
                        end: 4,
                        child: IconButton(
                          onPressed: _fav,
                          iconSize: 26,
                          style: IconButton.styleFrom(
                            minimumSize: const Size(48, 48),
                          ),
                          icon: AnimatedScale(
                            scale: fav ? 1.08 : 1,
                            duration: SouqMotion.favorite,
                            curve: Curves.elasticOut,
                            child: Icon(
                              fav
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: fav ? const Color(0xFFEF4444) : Colors.white,
                            ),
                          ),
                        ),
                      ),
                      if (sold)
                        const Align(
                          alignment: Alignment.center,
                          child: _SoldRibbon(),
                        ),
                      if (_burst)
                        FadeTransition(
                          opacity: Tween(begin: 1.0, end: 0.0).animate(_heart),
                          child: const Center(
                            child: Icon(
                              Icons.favorite_rounded,
                              color: Colors.white,
                              size: 64,
                            ),
                          ),
                        ),
                      PositionedDirectional(
                        start: 12,
                        end: 12,
                        bottom: 10,
                        child: Text(
                          SouqFormat.sar(
                            ad.price,
                            ar: l10n.ar,
                            negotiable: ad.isNegotiable,
                          ),
                          style: const TextStyle(
                            color: Color(0xFFE4C48A),
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ad.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        height: 1.25,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${ad.city} · ${SouqFormat.relativeTime(ad.createdAt, ar: l10n.ar)}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    if (ad.categoryId == SouqCatalog.cars) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (ad.year != null) _SpecChip('${ad.year}'),
                          if (ad.mileage != null) _SpecChip(SouqFormat.km(ad.mileage)),
                          if (ad.transmission != null) _SpecChip(ad.transmission!),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
        );
      },
    );
  }
}

class SouqCover extends StatelessWidget {
  const SouqCover({super.key, required this.ad});
  final Ad ad;

  @override
  Widget build(BuildContext context) {
    if (ad.images.isNotEmpty) {
      final path = ad.images.first;
      if (path.startsWith('http')) {
        return Image.network(path, fit: BoxFit.cover);
      }
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    }
    final color = SouqCatalog.colorForMake(ad.make);
    final letter = (ad.make ?? ad.title).characters.first.toUpperCase();
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.72)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              child: Text(
                letter,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                ad.make ?? ad.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpecChip extends StatelessWidget {
  const _SpecChip(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.chip,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: const TextStyle(fontSize: 11, color: AppColors.ink)),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.colors});
  final String text;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SoldRibbon extends StatelessWidget {
  const _SoldRibbon();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.45,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 6),
        color: const Color(0xCCB33A2B),
        child: const Text(
          'SOLD',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}

class SouqShimmerCard extends StatefulWidget {
  const SouqShimmerCard({super.key});

  @override
  State<SouqShimmerCard> createState() => _SouqShimmerCardState();
}

class _SouqShimmerCardState extends State<SouqShimmerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.stroke),
          ),
          child: Column(
            children: [
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-1 + _c.value * 2, 0),
                      end: Alignment(_c.value * 2, 0),
                      colors: const [
                        Color(0xFFEBE4D8),
                        Color(0xFFF7F2E8),
                        Color(0xFFEBE4D8),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 72),
            ],
          ),
        );
      },
    );
  }
}
