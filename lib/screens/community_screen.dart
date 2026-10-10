import 'dart:async';

import 'package:flutter/material.dart';

import '../data/app_analytics.dart';
import '../data/auth_session.dart';
import '../data/community_repository.dart';
import '../models/community.dart';
import '../theme/app_theme.dart';
import '../widgets/app_filter_chip.dart';
import '../widgets/community_post_tile.dart';
import 'auth_sheet.dart';
import 'community_create_screen.dart';
import 'community_page_screen.dart';
import 'community_post_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  String _topic = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    AuthSession.instance.addListener(_onAuth);
    CommunityRepository.instance.addListener(_onRepo);
    AppAnalytics.instance.section('community');
    if (AuthSession.instance.isSignedIn) {
      _reload();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    AuthSession.instance.removeListener(_onAuth);
    CommunityRepository.instance.removeListener(_onRepo);
    super.dispose();
  }

  void _onAuth() {
    if (!mounted) return;
    setState(() {});
    if (AuthSession.instance.isSignedIn) _reload();
  }

  void _onRepo() {
    if (mounted) setState(() {});
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    await CommunityRepository.instance.refresh(
      q: _search.text,
      topic: _topic,
    );
    if (mounted) setState(() => _loading = false);
  }

  void _onQuery(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), _reload);
  }

  Future<void> _signIn() async {
    await showAuthSheet(context);
    if (!mounted) return;
    if (AuthSession.instance.isSignedIn) _reload();
  }

  Future<void> _openPage(String id) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CommunityPageScreen(communityId: id)),
    );
    _reload();
  }

  Future<void> _joinById(String communityId) async {
    try {
      await CommunityRepository.instance.join(communityId);
      CommunityRepository.instance.markFeedJoined(communityId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _openMyPages(BuildContext context, List<Community> owned) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('My pages', style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 6),
                const Text(
                  'Pages you created',
                  style: TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 14),
                if (owned.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'You have not created a page yet.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  )
                else
                  ...owned.map(
                    (page) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: AppColors.greenDeep,
                        child: Text(
                          page.name.isNotEmpty ? page.name[0].toUpperCase() : 'P',
                          style: const TextStyle(
                            color: AppColors.onDark,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      title: Text(page.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(
                        '${page.topic} · ${page.memberCount} members',
                        style: const TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.pop(ctx);
                        _openPage(page.id);
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    if (!AuthSession.instance.isSignedIn) {
      return _Gate(top: pad.top, onSignIn: _signIn);
    }
    final repo = CommunityRepository.instance;
    return ColoredBox(
      color: AppColors.bg,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.extentAfter < 720) {
            CommunityRepository.instance.loadMoreFeed(
              q: _search.text,
              topic: _topic,
            );
          }
          return false;
        },
        child: RefreshIndicator(
        color: AppColors.green,
        onRefresh: _reload,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, pad.top + 12, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Community',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.6,
                                ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'My pages',
                          onPressed: () => _openMyPages(context, repo.owned),
                          icon: Badge(
                            isLabelVisible: repo.owned.isNotEmpty,
                            label: Text('${repo.owned.length}'),
                            child: const Icon(Icons.folder_shared_outlined),
                          ),
                        ),
                        const SizedBox(width: 4),
                        FilledButton.icon(
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const CommunityCreateScreen(),
                              ),
                            );
                            _reload();
                          },
                          icon: const Icon(Icons.add_rounded, size: 20),
                          label: const Text('Create page'),
                        ),
                      ],
                    ),
                    if (repo.pendingCount > 0) ...[
                      const SizedBox(height: 14),
                      _PendingBanner(
                        count: repo.pendingCount,
                        posts: repo.pendingInbox,
                        onChanged: _reload,
                      ),
                    ],
                    const SizedBox(height: 14),
                    TextField(
                      controller: _search,
                      onChanged: _onQuery,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search_rounded),
                        hintText: 'Search pages and posts',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _TopicChip(
                            label: 'All',
                            selected: _topic.isEmpty,
                            onTap: () {
                              setState(() => _topic = '');
                              _reload();
                            },
                          ),
                          ...repo.topics.map(
                            (topic) => _TopicChip(
                              label: topic,
                              selected: _topic == topic,
                              onTap: () {
                                setState(() => _topic = topic);
                                _reload();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_loading && repo.feed.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (repo.feed.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    repo.refreshError ??
                        (_search.text.trim().isNotEmpty
                            ? 'No posts match that search.'
                            : repo.feedCaughtUp
                            ? "You're all caught up. New posts will show up here."
                            : 'No posts yet. Create a page and share the first one.'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= repo.feed.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: repo.loadingMoreFeed
                              ? const CircularProgressIndicator()
                              : const SizedBox.shrink(),
                        ),
                      );
                    }
                    final post = repo.feed[index];
                    return CommunityPostTile(
                      post: post,
                      showPageName: true,
                      onLike: () async {
                        try {
                          final next = await CommunityRepository.instance
                              .togglePostLike(post.id);
                          CommunityRepository.instance.replaceFeedPost(next);
                        } catch (_) {}
                      },
                      onComment: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CommunityPostScreen(postId: post.id),
                          ),
                        );
                        _reload();
                      },
                      onOpenPage: () => _openPage(post.communityId),
                      onJoin: () => _joinById(post.communityId),
                    );
                  },
                  childCount: repo.feed.length + (repo.hasMoreFeed || repo.loadingMoreFeed ? 1 : 0),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
      ),
    );
  }
}

class _PendingBanner extends StatelessWidget {
  const _PendingBanner({
    required this.count,
    required this.posts,
    required this.onChanged,
  });

  final int count;
  final List<CommunityPost> posts;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF6E8),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          await showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: AppColors.card,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            builder: (ctx) {
              return DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.62,
                minChildSize: 0.4,
                maxChildSize: 0.92,
                builder: (_, controller) {
                  return ListView(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                    children: [
                      Text(
                        'Posts waiting for you',
                        style: Theme.of(ctx).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Only you (the page owner) can approve these. They stay hidden until you accept.',
                        style: TextStyle(color: AppColors.muted),
                      ),
                      const SizedBox(height: 14),
                      ...posts.map((post) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.line),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${post.communityName} · ${post.authorName}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(post.body),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  FilledButton(
                                    onPressed: () async {
                                      await CommunityRepository.instance
                                          .approvePost(post.communityId, post.id);
                                      if (ctx.mounted) Navigator.pop(ctx);
                                      await onChanged();
                                    },
                                    child: const Text('Approve'),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton(
                                    onPressed: () async {
                                      await CommunityRepository.instance
                                          .declinePost(post.communityId, post.id);
                                      if (ctx.mounted) Navigator.pop(ctx);
                                      await onChanged();
                                    },
                                    child: const Text('Decline'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  );
                },
              );
            },
          );
          await onChanged();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.inbox_rounded, color: AppColors.goldSoft),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$count post${count == 1 ? '' : 's'} waiting for your approval',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.goldSoft,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.goldSoft),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  const _TopicChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: AppFilterChip(
        label: label,
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _Gate extends StatelessWidget {
  const _Gate({required this.top, required this.onSignIn});

  final double top;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.bg,
      child: Padding(
        padding: EdgeInsets.fromLTRB(28, top + 48, 28, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Community',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Create pages, share posts, like and reply — and if you own a page, approve what others share.',
              style: TextStyle(color: AppColors.muted, height: 1.45),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onSignIn,
                child: const Text('Sign in to continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
