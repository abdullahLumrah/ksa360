import 'package:flutter/material.dart';

import '../data/content_repository.dart';
import '../models/models.dart';
import '../widgets/post_cards.dart';
import '../widgets/motion.dart';
import 'post_detail_screen.dart';

class PostListScreen extends StatelessWidget {
  const PostListScreen({super.key, required this.category});

  final GuideCategory category;

  @override
  Widget build(BuildContext context) {
    final posts = ContentRepository.instance.postsFor(category);
    return Scaffold(
      appBar: AppBar(title: Text(category.name)),
      body: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return PostListTileCard(
            post: post,
            onTap: () => openCard(context, PostDetailScreen(post: post)),
          );
        },
      ),
    );
  }
}
