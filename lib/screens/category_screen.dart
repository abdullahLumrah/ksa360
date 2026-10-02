import 'package:flutter/material.dart';

import '../data/app_analytics.dart';
import '../data/content_repository.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/category_widgets.dart';
import '../widgets/motion.dart';
import '../widgets/post_cards.dart';
import 'post_detail_screen.dart';
import 'post_list_screen.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key, required this.category});

  final GuideCategory category;

  @override
  Widget build(BuildContext context) {
    final repo = ContentRepository.instance;
    final children = repo.childrenOf(category);
    final ownPosts = repo.postsFor(category, limit: 16);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(category.name),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Text(
              '${category.totalCount} guides in this category',
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (children.isNotEmpty)
            SizedBox(
              height: 42,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: children.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final child = children[index];
                  return ActionChip(
                    label: Text('${child.name}  ${child.totalCount}'),
                    backgroundColor: AppColors.card,
                    side: const BorderSide(color: AppColors.stroke),
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: AppColors.goldSoft,
                    ),
                    onPressed: () {
                      AppAnalytics.instance.category('guides', child.name);
                      openCard(
                        context,
                        CategoryScreen(category: child),
                      );
                    },
                  );
                },
              ),
            ),
          if (children.isEmpty) ...[
            SectionHeader(
              title: 'Topics',
              subtitle: 'Tap a card to read the full guide',
              onSeeAll: ownPosts.length >= 12
                  ? () => _openAll(context, category)
                  : null,
            ),
            HorizontalPostScroller(
              posts: ownPosts,
              onOpen: (post) {
                AppAnalytics.instance.open(
                  section: 'guides',
                  targetId: post.id,
                  title: post.title,
                  category: category.name,
                );
                openCard(context, PostDetailScreen(post: post));
              },
            ),
          ] else ...[
            for (final child in children)
              _TopicSection(category: child, posts: repo.postsFor(child, limit: 12)),
          ],
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  void _openAll(BuildContext context, GuideCategory category) {
    openCard(context, PostListScreen(category: category));
  }
}

class _TopicSection extends StatelessWidget {
  const _TopicSection({
    required this.category,
    required this.posts,
  });

  final GuideCategory category;
  final List<GuidePost> posts;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        children: [
          SectionHeader(
            title: category.name,
            subtitle: '${category.totalCount} topics',
            onSeeAll: () {
              if (category.childIds.isNotEmpty) {
                openCard(context, CategoryScreen(category: category));
              } else {
                openCard(context, PostListScreen(category: category));
              }
            },
          ),
          HorizontalPostScroller(
            posts: posts,
            onOpen: (post) {
              AppAnalytics.instance.open(
                section: 'guides',
                targetId: post.id,
                title: post.title,
                category: category.name,
              );
              openCard(context, PostDetailScreen(post: post));
            },
          ),
        ],
      ),
    );
  }
}
