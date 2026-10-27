import 'dart:async';

import 'package:flutter/material.dart';

import '../data/app_analytics.dart';
import '../data/auth_session.dart';
import '../data/block_store.dart';
import '../data/community_repository.dart';
import '../l10n/l10n_ext.dart';
import '../models/community.dart';
import '../theme/app_theme.dart';
import '../widgets/app_filter_chip.dart';
import '../widgets/community_post_tile.dart';
import '../widgets/login_prompt.dart';
import 'community_create_screen.dart';
import 'community_moderation.dart';
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
    BlockStore.instance.addListener(_onRepo);
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
    BlockStore.instance.removeListener(_onRepo);
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
                Text(AppLocalizations.of(ctx).myPages, style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                  AppLocalizations.of(ctx).myPagesSubtitle,
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 14),
                if (owned.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      AppLocalizations.of(ctx).noPagesYet,
                      style: const TextStyle(color: AppColors.muted),
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
                        '${AppLocalizations.of(ctx).topic(page.topic)} · ${AppLocalizations.of(ctx).membersCount(page.memberCount)}',
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
      return ColoredBox(
        color: AppColors.bg,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, pad.top + 24, 20, pad.bottom + 96),
          child: LoginPrompt(
            title: AppLocalizations.of(context).communityLoginTitle,
            body: AppLocalizations.of(context).communityLoginBody,
            buttonLabel: AppLocalizations.of(context).login,
            icon: Icons.groups_rounded,
          ),
        ),
      );
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
                            AppLocalizations.of(context).communityTitle,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.6,
                                ),
                          ),
                        ),
                        IconButton(
                          tooltip: AppLocalizations.of(context).myPages,
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
                          label: Text(AppLocalizations.of(context).createPage),
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
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search_rounded),
                        hintText: AppLocalizations.of(context).searchPagesPosts,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _TopicChip(
                            label: AppLocalizations.of(context).all,
                            selected: _topic.isEmpty,
                            onTap: () {
                              setState(() => _topic = '');
                              _reload();
                            },
                          ),
                          ...repo.topics.map(
                            (topic) => _TopicChip(
                              label: AppLocalizations.of(context).topic(topic),
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
                            ? AppLocalizations.of(context).noPostsMatch
                            : AppLocalizations.of(context).noPostsYet),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final feed = BlockStore.instance.hideUsers(
                      repo.feed,
                      (item) => item.authorId,
                    );
                    if (index >= feed.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: repo.loadingMoreFeed
                              ? const CircularProgressIndicator()
                              : const SizedBox.shrink(),
                        ),
                      );
                    }
                    final post = feed[index];
                    return CommunityPostTile(
                      post: post,
                      showPageName: true,
                      onMore: () => showCommunityPostActions(
                        context,
                        post: post,
                      ),
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
                        AppLocalizations.of(ctx).postsWaitingTitle,
                        style: Theme.of(ctx).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppLocalizations.of(ctx).postsWaitingBody,
                        style: const TextStyle(color: AppColors.muted),
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
                                    child: Text(AppLocalizations.of(ctx).approve),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton(
                                    onPressed: () async {
                                      await CommunityRepository.instance
                                          .declinePost(post.communityId, post.id);
                                      if (ctx.mounted) Navigator.pop(ctx);
                                      await onChanged();
                                    },
                                    child: Text(AppLocalizations.of(ctx).decline),
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
                  AppLocalizations.of(context).postsWaitingBanner(count),
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

