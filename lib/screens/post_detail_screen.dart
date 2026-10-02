import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/content_repository.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/motion.dart';
import '../widgets/post_cards.dart';
import 'category_screen.dart';

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({super.key, required this.post});

  final GuidePost post;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late String _body;

  @override
  void initState() {
    super.initState();
    _body = ContentRepository.instance.bodyFor(widget.post.id);
    _loadBody();
  }

  Future<void> _loadBody() async {
    final next = await ContentRepository.instance.ensureBody(widget.post.id);
    if (!mounted || next == _body) return;
    setState(() => _body = next);
  }

  @override
  Widget build(BuildContext context) {
    final repo = ContentRepository.instance;
    final post = widget.post;
    final date = post.publishedAt;
    final related = repo.relatedTo(post);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        actions: [
          ListenableBuilder(
            listenable: repo,
            builder: (context, _) {
              final saved = repo.isSaved(post.id);
              return IconButton(
                onPressed: () => repo.toggleSaved(post.id),
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOutBack,
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: Icon(
                    saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    key: ValueKey(saved),
                    color: saved ? AppColors.red : AppColors.goldSoft,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          if (post.image != null)
            SizedBox(
              height: 240,
              width: double.infinity,
              child: PostImage(
                post: post,
                borderRadius: BorderRadius.zero,
                useHero: true,
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final name in post.categories)
                      GestureDetector(
                        onTap: () {
                          final category = repo.categoryByName[name];
                          if (category != null) {
                            openCard(
                              context,
                              CategoryScreen(category: category),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.stroke),
                          ),
                          child: Text(
                            name,
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  post.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  [
                    if (date != null) DateFormat.yMMMMd().format(date),
                    if (post.wordCount > 0) '${post.wordCount} words',
                    'Scroll to read',
                  ].join('  ·  '),
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 22),
                SelectableText(
                  _body,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.65,
                    fontSize: 16.5,
                    color: AppColors.ink,
                  ),
                ),
                if (related.isNotEmpty) ...[
                  const SizedBox(height: 36),
                  const Text(
                    'More in this topic',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 14),
                  for (final item in related)
                    PostListTileCard(
                      post: item,
                      pad: false,
                      onTap: () => Navigator.of(context).pushReplacement(
                        SoftPageRoute(
                          page: PostDetailScreen(post: item),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
