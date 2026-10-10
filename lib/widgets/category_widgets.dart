import 'package:flutter/material.dart';

import '../data/category_style.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'marquee_text.dart';
import 'motion.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onSeeAll,
    this.compact = false,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onSeeAll;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, compact ? 4 : 8, 8, compact ? 2 : 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: AppColors.navy,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
              ],
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: const Text(
                'See all',
                style: TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CategoryTile extends StatelessWidget {
  const CategoryTile({
    super.key,
    required this.category,
    required this.onTap,
  });

  final GuideCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = CategoryStyle.of(category.slug, category.name);
    final color = Color.lerp(style.color, AppColors.goldSoft, 0.08)!;
    return PressableScale(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 58,
            width: 58,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withValues(alpha: 0.28)),
            ),
            child: Icon(style.icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            category.name,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// Photo card for the home categories grid: bundled still-life with the
/// name set on a soft green scrim.
class CategoryPhotoTile extends StatelessWidget {
  const CategoryPhotoTile({
    super.key,
    required this.category,
    required this.onTap,
    this.cover,
  });

  final GuideCategory category;
  final VoidCallback onTap;
  /// Photo to use when the category has no bundled image of its own.
  final String? cover;

  @override
  Widget build(BuildContext context) {
    final image = CategoryStyle.imageFor(category.slug) ?? cover;
    final style = CategoryStyle.of(category.slug, category.name);
    final accent = CategoryStyle.accentFor(category.slug);
    final radius = BorderRadius.circular(20);
    return PressableScale(
      borderRadius: radius,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: AppColors.stroke),
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (image != null)
                Image.asset(image, fit: BoxFit.cover, cacheWidth: 360)
              else
                ColoredBox(
                  color: style.color.withValues(alpha: 0.14),
                  child: Icon(style.icon, color: style.color, size: 34),
                ),
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
                left: 10,
                right: 8,
                bottom: 9,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MarqueeText(
                      text: category.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        height: 1.15,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${category.totalCount} guides',
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExploreCategoryCard extends StatelessWidget {
  const ExploreCategoryCard({
    super.key,
    required this.category,
    required this.onTap,
  });

  final GuideCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = CategoryStyle.of(category.slug, category.name);
    final color = Color.lerp(style.color, AppColors.goldSoft, 0.08)!;
    return PressableScale(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.stroke),
          boxShadow: AppShadows.card,
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            if (CategoryStyle.imageFor(category.slug) case final image?)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  image,
                  height: 48,
                  width: 48,
                  fit: BoxFit.cover,
                  cacheWidth: 144,
                ),
              )
            else
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withValues(alpha: 0.28)),
                ),
                child: Icon(style.icon, color: color),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '${category.totalCount} topics',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}
