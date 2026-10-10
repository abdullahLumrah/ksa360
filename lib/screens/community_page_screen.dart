import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/auth_session.dart';
import '../data/community_repository.dart';
import '../models/community.dart';
import '../widgets/community_post_tile.dart';
import 'auth_sheet.dart';
import 'community_compose_screen.dart';
import 'community_post_screen.dart';
import 'community_report_sheet.dart';

/// Local palette for the page detail — slate / ink / soft paper (not green-gold).
class _PageTone {
  static const bg = Color(0xFFF3F1EC);
  static const hero = Color(0xFF1C2230);
  static const heroSoft = Color(0xFF2A3344);
  static const accent = Color(0xFF3D5A80);
  static const paper = Color(0xFFFFFDF9);
  static const ink = Color(0xFF1A1D24);
  static const muted = Color(0xFF6E665C);
  static const line = Color(0xFFE4DED4);
}

class CommunityPageScreen extends StatefulWidget {
  const CommunityPageScreen({super.key, required this.communityId});

  final String communityId;

  @override
  State<CommunityPageScreen> createState() => _CommunityPageScreenState();
}

class _CommunityPageScreenState extends State<CommunityPageScreen> {
  Community? _page;
  List<CommunityPost> _posts = const [];
  List<CommunityPost> _pending = const [];
  bool _loading = true;
  String? _error;
  bool _showPending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // detail() also records a unique page view server-side
      final page = await CommunityRepository.instance.detail(widget.communityId);
      final posts = await CommunityRepository.instance.posts(page.id);
      List<CommunityPost> pending = const [];
      if (page.canModerate) {
        pending = await CommunityRepository.instance.pendingFor(page.id);
      }
      if (!mounted) return;
      setState(() {
        _page = page;
        _posts = posts;
        _pending = pending;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _ensureAuth() async {
    if (AuthSession.instance.isSignedIn) return;
    await showAuthSheet(context);
  }

  Future<void> _toggleJoin() async {
    await _ensureAuth();
    if (!AuthSession.instance.isSignedIn || _page == null) return;
    try {
      final next = _page!.joined
          ? await CommunityRepository.instance.leave(_page!.id)
          : await CommunityRepository.instance.join(_page!.id);
      if (!mounted) return;
      setState(() => _page = next);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _createPost() async {
    await _ensureAuth();
    if (!mounted || !AuthSession.instance.isSignedIn || _page == null) return;
    final post = await openCommunityCompose(
      context,
      communityId: _page!.id,
      communityName: _page!.name,
    );
    if (!mounted || post == null) return;
    if (post.isApproved) {
      setState(() => _posts = [post, ..._posts]);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Posted')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sent for the page owner to approve')),
      );
      await _load();
    }
  }

  Future<void> _openPost(CommunityPost post, {bool openComposer = false}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CommunityPostScreen(
          postId: post.id,
          openComposer: openComposer,
        ),
      ),
    );
    _load();
  }

  Future<void> _approve(CommunityPost post) async {
    await CommunityRepository.instance.approvePost(post.communityId, post.id);
    await _load();
  }

  Future<void> _decline(CommunityPost post) async {
    await CommunityRepository.instance.declinePost(post.communityId, post.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _PageTone.bg,
        body: Center(child: CircularProgressIndicator(color: _PageTone.accent)),
      );
    }
    if (_error != null || _page == null) {
      return Scaffold(
        backgroundColor: _PageTone.bg,
        appBar: AppBar(backgroundColor: _PageTone.bg),
        body: Center(child: Text(_error ?? 'Page not found')),
      );
    }
    final page = _page!;
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: _PageTone.bg,
      body: RefreshIndicator(
        color: _PageTone.accent,
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _HeroHeader(
                topInset: top,
                page: page,
                onBack: () => Navigator.of(context).maybePop(),
                onReport: () => showCommunityReportSheet(
                  context,
                  targetType: 'community',
                  targetId: page.id,
                  communityId: page.id,
                  title: 'Report page',
                ),
                onJoin: page.isOwner ? null : _toggleJoin,
                onReview: page.canModerate && _pending.isNotEmpty
                    ? () => setState(() => _showPending = !_showPending)
                    : null,
                pendingCount: _pending.length,
                showPending: _showPending,
              ),
            ),
            if (_showPending && _pending.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    children: _pending
                        .map(
                          (post) => _PendingCard(
                            post: post,
                            onApprove: () => _approve(post),
                            onDecline: () => _decline(post),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                child: _ComposerCard(
                  onTap: _createPost,
                  userName: AuthSession.instance.user?.name ?? '',
                  userAvatar: AuthSession.instance.user?.avatar ?? '',
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                child: Row(
                  children: [
                    Text(
                      'Posts',
                      style: GoogleFonts.fraunces(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: _PageTone.ink,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8E4DE),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${page.postCount}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: _PageTone.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_posts.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 20, 28, 100),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: _PageTone.line),
                        ),
                        child: const Icon(
                          Icons.edit_note_rounded,
                          size: 34,
                          color: _PageTone.accent,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Start the conversation',
                        style: GoogleFonts.fraunces(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: _PageTone.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Share a tip, question, or update. Members will see it in this feed.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _PageTone.muted, height: 1.45),
                      ),
                      const SizedBox(height: 18),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _PageTone.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _createPost,
                        child: const Text('Write the first post'),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final post = _posts[index];
                    return CommunityPostTile(
                      post: post,
                      onLike: () async {
                        await _ensureAuth();
                        if (!mounted || !AuthSession.instance.isSignedIn) return;
                        final next =
                            await CommunityRepository.instance.togglePostLike(post.id);
                        setState(() {
                          _posts = [
                            for (final item in _posts)
                              if (item.id == next.id) next else item,
                          ];
                        });
                      },
                      onComment: () => _openPost(post, openComposer: true),
                      onMore: () => showCommunityReportSheet(
                        context,
                        targetType: 'post',
                        targetId: post.id,
                        reportedUserId: post.authorId,
                        communityId: post.communityId,
                        title: 'Report post',
                      ),
                    );
                  },
                  childCount: _posts.length,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 48)),
          ],
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.topInset,
    required this.page,
    required this.onBack,
    required this.onReport,
    required this.onJoin,
    required this.onReview,
    required this.pendingCount,
    required this.showPending,
  });

  final double topInset;
  final Community page;
  final VoidCallback onBack;
  final VoidCallback onReport;
  final VoidCallback? onJoin;
  final VoidCallback? onReview;
  final int pendingCount;
  final bool showPending;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_PageTone.hero, _PageTone.heroSoft],
        ),
      ),
      padding: EdgeInsets.fromLTRB(12, topInset + 4, 12, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
              const Spacer(),
              if (onReview != null)
                TextButton.icon(
                  onPressed: onReview,
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  icon: Badge(
                    label: Text('$pendingCount'),
                    child: const Icon(Icons.inbox_outlined, color: Colors.white),
                  ),
                  label: Text(showPending ? 'Hide queue' : 'Review'),
                ),
              IconButton(
                onPressed: onReport,
                icon: const Icon(Icons.more_horiz_rounded, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    [
                      page.topic,
                      if (page.city.isNotEmpty) page.city,
                    ].join(' · '),
                    style: const TextStyle(
                      color: Color(0xFFD7DEEA),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  page.name,
                  style: GoogleFonts.fraunces(
                    color: Colors.white,
                    fontSize: 30,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.6,
                  ),
                ),
                if (page.description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    page.description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      height: 1.45,
                      fontSize: 14.5,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    _StatPill(
                      icon: Icons.groups_2_outlined,
                      label: communityCompactCount(page.memberCount),
                      caption: 'members',
                    ),
                    const SizedBox(width: 8),
                    _StatPill(
                      icon: Icons.article_outlined,
                      label: communityCompactCount(page.postCount),
                      caption: 'posts',
                    ),
                    const SizedBox(width: 8),
                    _StatPill(
                      icon: Icons.visibility_outlined,
                      label: communityCompactCount(page.viewCount),
                      caption: 'views',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (page.isOwner)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Text(
                          'You’re the owner',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    else if (onJoin != null)
                      FilledButton(
                        onPressed: onJoin,
                        style: FilledButton.styleFrom(
                          backgroundColor: page.joined ? Colors.white24 : Colors.white,
                          foregroundColor: page.joined ? Colors.white : _PageTone.hero,
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(page.joined ? 'Joined' : 'Join page'),
                      ),
                    const Spacer(),
                    if (page.creatorName.isNotEmpty)
                      Text(
                        'by ${page.creatorName}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.label,
    required this.caption,
  });

  final IconData icon;
  final String label;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: const Color(0xFFB8C4D6)),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            Text(
              caption,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposerCard extends StatelessWidget {
  const _ComposerCard({
    required this.onTap,
    required this.userName,
    required this.userAvatar,
  });

  final VoidCallback onTap;
  final String userName;
  final String userAvatar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _PageTone.paper,
      elevation: 0,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _PageTone.line),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C1C1915),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Share with the page',
                  style: GoogleFonts.fraunces(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _PageTone.ink,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CommunityAvatar(
                      name: userName.isNotEmpty ? userName : 'You',
                      imageUrl: userAvatar,
                      radius: 22,
                      backgroundColor: _PageTone.accent,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: _PageTone.bg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _PageTone.line),
                        ),
                        child: const Text(
                          'What’s on your mind?',
                          style: TextStyle(
                            color: _PageTone.muted,
                            fontSize: 14.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: onTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: _PageTone.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text('Post'),
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

class _PendingCard extends StatelessWidget {
  const _PendingCard({
    required this.post,
    required this.onApprove,
    required this.onDecline,
  });

  final CommunityPost post;
  final VoidCallback onApprove;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8D4B0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${post.authorName} · waiting for approval',
            style: const TextStyle(
              color: Color(0xFF8A5E2E),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(post.body),
          const SizedBox(height: 10),
          Row(
            children: [
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _PageTone.accent),
                onPressed: onApprove,
                child: const Text('Approve'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: onDecline, child: const Text('Decline')),
            ],
          ),
        ],
      ),
    );
  }
}
