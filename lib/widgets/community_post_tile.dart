import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/community.dart';
import '../theme/app_theme.dart';

String communityRelativeTime(String raw) {
  final at = DateTime.tryParse(raw.replaceFirst(' ', 'T'));
  if (at == null) return raw;
  final diff = DateTime.now().difference(at.toLocal());
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return '${at.day}/${at.month}/${at.year}';
}

String communityCompactCount(int value) {
  if (value >= 1000000) {
    final n = value / 1000000;
    return '${n.toStringAsFixed(n >= 10 ? 0 : 1)}M';
  }
  if (value >= 1000) {
    final n = value / 1000;
    return '${n.toStringAsFixed(n >= 10 ? 0 : 1)}K';
  }
  return '$value';
}

class CommunityAvatar extends StatelessWidget {
  const CommunityAvatar({
    super.key,
    required this.name,
    this.imageUrl = '',
    this.radius = 20,
    this.backgroundColor,
  });

  final String name;
  final String imageUrl;
  final double radius;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    if (imageUrl.startsWith('http')) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? AppColors.chip,
        backgroundImage: NetworkImage(imageUrl),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? const Color(0xFF2C3340),
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: radius * 0.85,
        ),
      ),
    );
  }
}

/// Feed post: avatar + name + date → body → stats → Like / Comment / Views.
class CommunityPostTile extends StatelessWidget {
  const CommunityPostTile({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
    this.onMore,
    this.onJoin,
    this.onOpenPage,
    this.showPageName = false,
    this.margin = const EdgeInsets.fromLTRB(16, 0, 16, 12),
    this.elevated = true,
  });

  final CommunityPost post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback? onMore;
  final VoidCallback? onJoin;
  final VoidCallback? onOpenPage;
  final bool showPageName;
  final EdgeInsetsGeometry margin;
  final bool elevated;

  bool get _canJoin => onJoin != null && !post.joined && !post.isOwner;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: elevated ? Colors.white : AppColors.card,
        borderRadius: BorderRadius.circular(elevated ? 20 : 0),
        border: Border.all(color: const Color(0xFFE8E4DE)),
        boxShadow: elevated
            ? const [
                BoxShadow(
                  color: Color(0x0F1C1915),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onComment,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 6, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CommunityAvatar(
                        name: post.authorName,
                        imageUrl: post.authorAvatar,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    post.authorName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: Color(0xFF1A1D24),
                                    ),
                                  ),
                                ),
                                const Text(
                                  ' · ',
                                  style: TextStyle(
                                    color: Color(0xFF7A746C),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  communityRelativeTime(post.createdAt),
                                  style: const TextStyle(
                                    color: Color(0xFF7A746C),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            if (showPageName && post.communityName.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              GestureDetector(
                                onTap: onOpenPage,
                                child: Text(
                                  post.communityName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: onOpenPage != null
                                        ? const Color(0xFF3D5A80)
                                        : const Color(0xFF7A746C),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (onMore != null)
                        IconButton(
                          onPressed: onMore,
                          icon: const Icon(Icons.more_horiz_rounded),
                          color: const Color(0xFF7A746C),
                        ),
                    ],
                  ),
                ),
                if (post.body.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Text(
                      post.body,
                      style: const TextStyle(
                        fontSize: 15.5,
                        height: 1.5,
                        color: Color(0xFF2A2E36),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 8),
                if (post.image.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: post.body.isEmpty ? 12 : 4),
                    child: CachedNetworkImage(
                      imageUrl: post.image,
                      width: double.infinity,
                      height: 240,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const SizedBox(
                        height: 240,
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Row(
              children: [
                if (post.likeCount > 0)
                  Text(
                    '${communityCompactCount(post.likeCount)} like${post.likeCount == 1 ? '' : 's'}',
                    style: const TextStyle(color: Color(0xFF7A746C), fontSize: 12.5),
                  ),
                if (post.likeCount > 0 && post.commentCount > 0)
                  const Text('  ·  ', style: TextStyle(color: Color(0xFF7A746C))),
                if (post.commentCount > 0)
                  GestureDetector(
                    onTap: onComment,
                    child: Text(
                      '${communityCompactCount(post.commentCount)} comment${post.commentCount == 1 ? '' : 's'}',
                      style: const TextStyle(color: Color(0xFF7A746C), fontSize: 12.5),
                    ),
                  ),
                const Spacer(),
                Icon(
                  Icons.visibility_outlined,
                  size: 15,
                  color: const Color(0xFF7A746C).withValues(alpha: 0.9),
                ),
                const SizedBox(width: 4),
                Text(
                  communityCompactCount(post.viewCount),
                  style: const TextStyle(
                    color: Color(0xFF7A746C),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEDE8E0)),
          SizedBox(
            height: 46,
            child: Row(
              children: [
                Expanded(
                  child: _Action(
                    icon: post.liked ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
                    label: 'Like',
                    active: post.liked,
                    onTap: onLike,
                  ),
                ),
                Expanded(
                  child: _Action(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Comment',
                    onTap: onComment,
                  ),
                ),
                Expanded(
                  child: _canJoin
                      ? _Action(
                          icon: Icons.group_add_outlined,
                          label: 'Join',
                          active: true,
                          onTap: onJoin!,
                        )
                      : _Action(
                          icon: Icons.groups_outlined,
                          label: 'Page',
                          onTap: onOpenPage ?? onComment,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF3D5A80) : const Color(0xFF6E665C);
    return InkWell(
      onTap: onTap,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
