import 'dart:async';

import 'package:flutter/material.dart';

import '../data/app_analytics.dart';
import '../data/auth_session.dart';
import '../data/job_repository.dart';
import '../models/job.dart';
import '../theme/app_theme.dart';
import '../widgets/app_filter_chip.dart';
import '../widgets/motion.dart';
import 'auth_sheet.dart';
import 'job_detail_screen.dart';
import 'job_post_screen.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  String _category = '';
  String _city = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    AuthSession.instance.addListener(_onAuth);
    JobRepository.instance.addListener(_onJobs);
    AppAnalytics.instance.section('jobs');
    if (AuthSession.instance.isSignedIn) _reload();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    AuthSession.instance.removeListener(_onAuth);
    JobRepository.instance.removeListener(_onJobs);
    super.dispose();
  }

  void _onAuth() {
    if (!mounted) return;
    setState(() {});
    if (AuthSession.instance.isSignedIn) _reload();
  }

  void _onJobs() {
    if (mounted) setState(() {});
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    await JobRepository.instance.refresh(
      q: _search.text,
      category: _category,
      city: _city,
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

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    if (!AuthSession.instance.isSignedIn) {
      return _JobsGate(top: pad.top, onSignIn: _signIn);
    }
    final repo = JobRepository.instance;
    return ColoredBox(
      color: AppColors.bg,
      child: RefreshIndicator(
        color: AppColors.green,
        onRefresh: _reload,
        child: NotificationListener<ScrollNotification>(
          onNotification: (notice) {
            if (notice.metrics.extentAfter < 400 &&
                JobRepository.instance.hasMore &&
                !JobRepository.instance.loadingMore) {
              JobRepository.instance.loadMore(
                q: _search.text,
                category: _category,
                city: _city,
              );
            }
            return false;
          },
          child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, pad.top + 10, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Jobs',
                            style: TextStyle(
                              color: AppColors.navy,
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                              height: 1.1,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Work in Saudi Arabia',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () async {
                        await openCard(context, const JobPostScreen());
                        if (mounted) _reload();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text(
                        'Post a job',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Material(
                  color: AppColors.card,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.stroke),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: TextField(
                      controller: _search,
                      onChanged: _onQuery,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Search jobs',
                        icon: Icon(Icons.search_rounded, size: 18),
                        hintStyle: TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      style: const TextStyle(fontSize: 13, height: 1.1),
                    ),
                  ),
                ),
              ),
            ),
            if (repo.categories.isNotEmpty)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    children: [
                      _FilterChip(
                        label: 'All',
                        selected: _category.isEmpty,
                        onTap: () {
                          setState(() => _category = '');
                          _reload();
                        },
                      ),
                      for (final item in repo.categories)
                        _FilterChip(
                          label: item.name,
                          selected: _category == item.name,
                          onTap: () {
                            setState(() => _category = item.name);
                            _reload();
                          },
                        ),
                    ],
                  ),
                ),
              ),
            if (repo.cities.isNotEmpty)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                    children: [
                      _FilterChip(
                        label: 'Any city',
                        selected: _city.isEmpty,
                        compact: true,
                        onTap: () {
                          setState(() => _city = '');
                          _reload();
                        },
                      ),
                      for (final item in repo.cities)
                        _FilterChip(
                          label: item.name,
                          selected: _city == item.name,
                          compact: true,
                          onTap: () {
                            setState(() => _city = item.name);
                            _reload();
                          },
                        ),
                    ],
                  ),
                ),
              ),
            if (repo.refreshError != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(repo.refreshError!),
                ),
              )
            else if (_loading && repo.jobs.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (repo.jobs.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Text(
                    'No jobs match these filters.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, pad.bottom + 96),
                sliver: SliverList.separated(
                  itemCount: repo.jobs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final job = repo.jobs[index];
                    return _JobCard(
                      job: job,
                      onTap: () => openCard(context, JobDetailScreen(id: job.id)),
                    );
                  },
                ),
              ),
          ],
        ),
        ),
      ),
    );
  }
}

class _JobsGate extends StatelessWidget {
  const _JobsGate({required this.top, required this.onSignIn});

  final double top;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.bg,
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, top + 28, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Jobs',
              style: TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w800,
                fontSize: 28,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sign in to browse Saudi roles, apply on the listing, or post a job for review.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 15,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: onSignIn,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Sign in to continue',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 6),
      child: AppFilterChip(
        label: label,
        selected: selected,
        compact: compact,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.job, required this.onTap});

  final Job job;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.stroke),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                job.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                [
                  if (job.companyName.isNotEmpty) job.companyName,
                  if (job.place.isNotEmpty) job.place,
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (job.category.isNotEmpty) _Meta(job.category),
                  if (job.employmentType.isNotEmpty) _Meta(job.employmentType),
                  if (job.salaryPosted && job.salaryDisplay.isNotEmpty)
                    _Meta(job.salaryDisplay),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.chip,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      ),
    );
  }
}
