import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/category_style.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'motion.dart';

class PostImage extends StatelessWidget {
  const PostImage({
    super.key,
    required this.post,
    this.borderRadius,
    this.useHero = false,
  });

  final GuidePost post;
  final BorderRadius? borderRadius;
  final bool useHero;

  @override
  Widget build(BuildContext context) {
    final style = CategoryStyle.of('', post.primaryCategory);
    final radius = borderRadius ?? BorderRadius.circular(16);
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          colors: [
            Color.lerp(AppColors.greenDeep, style.color, 0.42)!,
            AppColors.card,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(style.icon, color: AppColors.onDark, size: 36),
      ),
    );

    final image = post.image == null || post.image!.isEmpty
        ? fallback
        : ClipRRect(
            borderRadius: radius,
            child: CachedNetworkImage(
              imageUrl: post.image!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              placeholder: (_, __) => fallback,
              errorWidget: (_, __, ___) => fallback,
            ),
          );

    if (!useHero) return image;
    return Hero(tag: 'post-image-${post.id}', child: image);
  }
}

class HorizontalPostCard extends StatelessWidget {
  const HorizontalPostCard({
    super.key,
    required this.post,
    required this.onTap,
  });

  final GuidePost post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = post.publishedAt;
    return SizedBox(
      width: 292,
      height: 386,
      child: PressableScale(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.stroke),
            boxShadow: AppShadows.card,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 132,
                width: double.infinity,
                child: PostImage(
                  post: post,
                  useHero: true,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.primaryCategory.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        post.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          post.preview,
                          maxLines: 7,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                            height: 1.45,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        [
                          if (date != null) DateFormat.yMMMd().format(date),
                          if (post.wordCount > 0) '${post.wordCount} words',
                        ].join('  ·  '),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
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
}

class PostListTileCard extends StatelessWidget {
  const PostListTileCard({
    super.key,
    required this.post,
    required this.onTap,
    this.pad = true,
  });

  final GuidePost post;
  final VoidCallback onTap;
  final bool pad;

  @override
  Widget build(BuildContext context) {
    final date = post.publishedAt;
    return Padding(
      padding: pad
          ? const EdgeInsets.fromLTRB(16, 0, 16, 12)
          : const EdgeInsets.only(bottom: 12),
      child: PressableScale(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.stroke),
            boxShadow: AppShadows.card,
          ),
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 92,
                height: 92,
                child: PostImage(
                  post: post,
                  useHero: true,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      post.preview,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      [
                        post.primaryCategory,
                        if (date != null) DateFormat.yMMMd().format(date),
                      ].join('  ·  '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
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

class HorizontalPostScroller extends StatelessWidget {
  const HorizontalPostScroller({
    super.key,
    required this.posts,
    required this.onOpen,
  });

  final List<GuidePost> posts;
  final ValueChanged<GuidePost> onOpen;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 402,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        scrollDirection: Axis.horizontal,
        itemCount: posts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final post = posts[index];
          return StaggerIn(
            index: index,
            child: HorizontalPostCard(
              post: post,
              onTap: () => onOpen(post),
            ),
          );
        },
      ),
    );
  }
}
