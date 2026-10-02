import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
import '../../../../widgets/motion.dart';
import '../../domain/souq_categories.dart';
import '../../domain/souq_models.dart';
import '../souq_l10n.dart';

class SouqCategoryTile extends StatelessWidget {
  const SouqCategoryTile({
    super.key,
    required this.category,
    required this.onTap,
    this.selected = false,
    this.compact = false,
    this.featured = false,
    this.useHero = true,
  });

  final SouqCategory category;
  final VoidCallback onTap;
  final bool selected;
  final bool compact;
  final bool featured;
  final bool useHero;

  @override
  Widget build(BuildContext context) {
    final l10n = SouqL10n.of(context);
    final radius = BorderRadius.circular(20);
    final primary = category.name(l10n.ar);
    final secondary = featured
        ? (l10n.ar
            ? '${category.nameEn} · ${l10n.haraj}'
            : '${category.nameAr} · ${l10n.haraj}')
        : category.name(!l10n.ar);
    final photo = Image.asset(
      category.imageAsset,
      fit: BoxFit.cover,
      cacheWidth: featured ? 720 : 360,
      errorBuilder: (_, __, ___) => ColoredBox(
        color: category.gradient.first.withValues(alpha: 0.18),
        child: Icon(category.icon, color: category.accent, size: 34),
      ),
    );
    return Semantics(
      button: true,
      selected: selected,
      label: '$primary. $secondary',
      child: PressableScale(
        borderRadius: radius,
        scale: 0.97,
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: selected ? AppColors.goldBright : AppColors.stroke,
              width: selected ? 2 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(
              fit: StackFit.expand,
              children: [
                useHero
                    ? Hero(
                        tag: 'cat-photo-${category.id}',
                        child: Material(
                          type: MaterialType.transparency,
                          child: photo,
                        ),
                      )
                    : photo,
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.42, 1],
                      colors: [Color(0x00111114), Color(0xCC1A1520)],
                    ),
                  ),
                ),
                Positioned(
                  left: featured ? 16 : 10,
                  right: featured ? 14 : 8,
                  bottom: featured ? 14 : 9,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        primary,
                        maxLines: featured ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: featured
                              ? 26
                              : compact
                                  ? 12
                                  : 13,
                          height: 1.15,
                          letterSpacing: featured ? -0.4 : -0.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        secondary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: category.accent,
                          fontWeight: FontWeight.w700,
                          fontSize: featured ? 13 : 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared photo language for Souq category tiles and category-screen heroes.
class SouqCategoryBackdrop extends StatelessWidget {
  const SouqCategoryBackdrop({
    super.key,
    required this.category,
    this.intensity = 1,
  });

  final SouqCategory category;
  final double intensity;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          category.imageAsset,
          fit: BoxFit.cover,
          cacheWidth: 720,
          errorBuilder: (_, __, ___) => DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: category.gradient,
              ),
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.28, 1],
              colors: [
                const Color(0x00111114),
                Color(0xCC1A1520).withValues(alpha: 0.72 * intensity.clamp(0, 1)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class SouqEmpty extends StatelessWidget {
  const SouqEmpty({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.storefront_rounded, size: 56, color: AppColors.gold),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: AppColors.navy,
            ),
          ),
          if (action != null && onAction != null) ...[
            const SizedBox(height: 16),
            FilledButton(onPressed: onAction, child: Text(action!)),
          ],
        ],
      ),
    );
  }
}

class WormDots extends StatelessWidget {
  const WormDots({super.key, required this.count, required this.index});
  final int count;
  final double index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            height: 7,
            width: (1 - (index - i).abs()).clamp(0.0, 1.0) > 0.5 ? 22 : 7,
            decoration: BoxDecoration(
              color: AppColors.green.withValues(
                alpha: 0.35 + (1 - (index - i).abs()).clamp(0.0, 1.0) * 0.65,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
      ],
    );
  }
}

class GlassBar extends StatelessWidget {
  const GlassBar({super.key, required this.child, this.padding});
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xE6FFFCF7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.stroke),
          ),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(10),
            child: child,
          ),
        ),
      ),
    );
  }
}

class CountingText extends StatelessWidget {
  const CountingText({
    super.key,
    required this.value,
    required this.builder,
  });
  final int value;
  final String Function(int) builder;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 480),
      builder: (context, v, _) => Text(builder(v.round())),
    );
  }
}

class MakeAvatar extends StatelessWidget {
  const MakeAvatar({super.key, required this.make, this.selected = false, this.onTap});
  final String make;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = SouqCatalog.colorForMake(make);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AppColors.gold : Colors.transparent,
                width: 2,
              ),
            ),
            child: Text(
              make.characters.take(2).toString().toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 64,
            child: Text(
              make,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
