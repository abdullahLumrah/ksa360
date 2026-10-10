import 'package:flutter/material.dart';

import '../data/auth_session.dart';
import '../data/community_repository.dart';
import '../models/community.dart';
import '../theme/app_theme.dart';
import '../widgets/community_post_tile.dart';
import 'auth_sheet.dart';
import 'community_page_screen.dart';
import 'community_report_sheet.dart';

/// Matches the community page detail palette (slate, not green/gold).
class _PostTone {
  static const accent = Color(0xFF3D5A80);
  static const bg = Color(0xFFF3F1EC);
  static const paper = Color(0xFFFFFDF9);
  static const muted = Color(0xFF6E665C);
  static const chip = Color(0xFFE8E4DE);
}

/// Facebook-style comments page: post on top, comments + replies below, write box at bottom.
class CommunityPostScreen extends StatefulWidget {
  const CommunityPostScreen({
    super.key,
    required this.postId,
    this.openComposer = false,
  });

  final String postId;
  final bool openComposer;

  @override
  State<CommunityPostScreen> createState() => _CommunityPostScreenState();
}

class _CommunityPostScreenState extends State<CommunityPostScreen> {
  CommunityPost? _post;
  List<CommunityComment> _comments = const [];
  bool _loading = true;
  final _comment = TextEditingController();
  final _focus = FocusNode();
  String? _replyToId;
  String? _replyToName;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load().then((_) {
      if (widget.openComposer && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
      }
    });
  }

  @override
  void dispose() {
    _comment.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final post = await CommunityRepository.instance.postDetail(widget.postId);
      final comments = await CommunityRepository.instance.comments(widget.postId);
      if (!mounted) return;
      setState(() {
        _post = post;
        _comments = comments;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _ensureAuth() async {
    if (!AuthSession.instance.isSignedIn) {
      await showAuthSheet(context);
    }
  }

  Future<void> _togglePostLike() async {
    await _ensureAuth();
    if (!mounted || !AuthSession.instance.isSignedIn || _post == null) return;
    final next = await CommunityRepository.instance.togglePostLike(_post!.id);
    setState(() => _post = next);
  }

  Future<void> _send() async {
    await _ensureAuth();
    if (!mounted || !AuthSession.instance.isSignedIn) return;
    final body = _comment.text.trim();
    if (body.isEmpty || _post == null) return;
    setState(() => _sending = true);
    try {
      if (_replyToId != null) {
        await CommunityRepository.instance.reply(_replyToId!, body);
      } else {
        await CommunityRepository.instance.addComment(_post!.id, body);
      }
      _comment.clear();
      _replyToId = null;
      _replyToName = null;
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _likeComment(CommunityComment comment) async {
    await _ensureAuth();
    if (!mounted || !AuthSession.instance.isSignedIn) return;
    final next = await CommunityRepository.instance.toggleCommentLike(comment.id);
    setState(() {
      _comments = _comments.map((item) {
        if (item.id == next.id) {
          return item.copyWith(likeCount: next.likeCount, liked: next.liked);
        }
        final replies = item.replies
            .map(
              (reply) => reply.id == next.id
                  ? reply.copyWith(likeCount: next.likeCount, liked: next.liked)
                  : reply,
            )
            .toList();
        return item.copyWith(replies: replies);
      }).toList();
    });
  }

  void _startReply(CommunityComment comment) {
    setState(() {
      _replyToId = comment.id;
      _replyToName = comment.authorName;
    });
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _post == null) {
      return const Scaffold(
        backgroundColor: _PostTone.bg,
        body: Center(child: CircularProgressIndicator(color: _PostTone.accent)),
      );
    }
    final post = _post!;
    final me = AuthSession.instance.user?.name ?? '';
    return Scaffold(
      backgroundColor: _PostTone.bg,
      appBar: AppBar(
        backgroundColor: _PostTone.bg,
        foregroundColor: const Color(0xFF1A1D24),
        title: const Text('Comments'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'report_post') {
                showCommunityReportSheet(
                  context,
                  targetType: 'post',
                  targetId: post.id,
                  reportedUserId: post.authorId,
                  communityId: post.communityId,
                  title: 'Report post',
                );
              } else if (value == 'report_user') {
                showCommunityReportSheet(
                  context,
                  targetType: 'user',
                  targetId: post.authorId,
                  reportedUserId: post.authorId,
                  communityId: post.communityId,
                  title: 'Report ${post.authorName}',
                );
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'report_post', child: Text('Report post')),
              PopupMenuItem(value: 'report_user', child: Text('Report user')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 12),
              children: [
                CommunityPostTile(
                  post: post,
                  showPageName: true,
                  margin: EdgeInsets.zero,
                  onLike: _togglePostLike,
                  onComment: () => _focus.requestFocus(),
                  onOpenPage: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CommunityPageScreen(communityId: post.communityId),
                      ),
                    );
                  },
                  onJoin: () async {
                    try {
                      await CommunityRepository.instance.join(post.communityId);
                      await _load();
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            e.toString().replaceFirst('Exception: ', ''),
                          ),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.fromLTRB(14, 4, 14, 10),
                  child: Text(
                    'Comments',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (_comments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(14, 24, 14, 24),
                    child: Text(
                      'No comments yet. Be the first to comment.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  )
                else
                  ..._comments.map(
                    (comment) => _FbComment(
                      comment: comment,
                      post: post,
                      onLike: () => _likeComment(comment),
                      onReply: () => _startReply(comment),
                      onLikeReply: _likeComment,
                      onReplyToReply: (reply) => _startReply(
                        // Reply to the parent thread
                        comment,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_replyToName != null)
            Container(
              width: double.infinity,
              color: _PostTone.chip,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Replying to $_replyToName',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: _PostTone.accent),
                    onPressed: () => setState(() {
                      _replyToId = null;
                      _replyToName = null;
                    }),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          Material(
            color: _PostTone.paper,
            elevation: 8,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    CommunityAvatar(
                      name: me.isEmpty ? '?' : me,
                      radius: 16,
                      backgroundColor: _PostTone.accent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _comment,
                        focusNode: _focus,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        cursorColor: _PostTone.accent,
                        decoration: InputDecoration(
                          hintText: _replyToId == null
                              ? 'Write a comment…'
                              : 'Write a reply…',
                          filled: true,
                          fillColor: _PostTone.chip,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: const BorderSide(color: _PostTone.accent, width: 1.2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton.filled(
                      onPressed: _sending ? null : _send,
                      style: IconButton.styleFrom(
                        backgroundColor: _PostTone.accent,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _PostTone.accent.withValues(alpha: 0.4),
                      ),
                      icon: const Icon(Icons.send_rounded, size: 20),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FbComment extends StatelessWidget {
  const _FbComment({
    required this.comment,
    required this.post,
    required this.onLike,
    required this.onReply,
    required this.onLikeReply,
    required this.onReplyToReply,
  });

  final CommunityComment comment;
  final CommunityPost post;
  final VoidCallback onLike;
  final VoidCallback onReply;
  final Future<void> Function(CommunityComment) onLikeReply;
  final void Function(CommunityComment) onReplyToReply;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Column(
        children: [
          _FbCommentRow(
            comment: comment,
            post: post,
            onLike: onLike,
            onReply: onReply,
          ),
          if (comment.replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 44, top: 8),
              child: Column(
                children: [
                  for (final reply in comment.replies)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _FbCommentRow(
                        comment: reply,
                        post: post,
                        onLike: () => onLikeReply(reply),
                        onReply: () => onReplyToReply(reply),
                        compact: true,
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

class _FbCommentRow extends StatelessWidget {
  const _FbCommentRow({
    required this.comment,
    required this.post,
    required this.onLike,
    required this.onReply,
    this.compact = false,
  });

  final CommunityComment comment;
  final CommunityPost post;
  final VoidCallback onLike;
  final VoidCallback onReply;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommunityAvatar(
          name: comment.authorName,
          imageUrl: comment.authorAvatar,
          radius: compact ? 14 : 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                decoration: BoxDecoration(
                  color: _PostTone.chip,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.authorName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      comment.body,
                      style: const TextStyle(fontSize: 14, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Row(
                  children: [
                    Text(
                      communityRelativeTime(comment.createdAt),
                      style: const TextStyle(color: _PostTone.muted, fontSize: 12),
                    ),
                    const SizedBox(width: 14),
                    GestureDetector(
                      onTap: onLike,
                      child: Text(
                        comment.liked
                            ? 'Liked${comment.likeCount > 0 ? ' · ${comment.likeCount}' : ''}'
                            : 'Like${comment.likeCount > 0 ? ' · ${comment.likeCount}' : ''}',
                        style: TextStyle(
                          color: comment.liked ? _PostTone.accent : _PostTone.muted,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    GestureDetector(
                      onTap: onReply,
                      child: const Text(
                        'Reply',
                        style: TextStyle(
                          color: _PostTone.muted,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    GestureDetector(
                      onTap: () => showCommunityReportSheet(
                        context,
                        targetType: 'comment',
                        targetId: comment.id,
                        reportedUserId: comment.authorId,
                        communityId: comment.communityId.isNotEmpty
                            ? comment.communityId
                            : post.communityId,
                        title: compact ? 'Report reply' : 'Report comment',
                      ),
                      child: const Text(
                        'Report',
                        style: TextStyle(
                          color: _PostTone.muted,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
