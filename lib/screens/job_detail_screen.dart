import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/auth_session.dart';
import '../data/job_repository.dart';
import '../models/job.dart';
import '../theme/app_theme.dart';
import 'auth_sheet.dart';

class JobDetailScreen extends StatefulWidget {
  const JobDetailScreen({super.key, required this.id, this.job});

  final String id;
  final Job? job;

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  Job? _job;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _job = widget.job;
    _load();
  }

  Future<void> _load() async {
    try {
      final job = await JobRepository.instance.detail(widget.id);
      if (!mounted) return;
      setState(() {
        _job = job;
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

  Future<void> _apply() async {
    if (!AuthSession.instance.isSignedIn) {
      await showAuthSheet(context);
      if (!AuthSession.instance.isSignedIn) return;
    }
    final link = _job?.applyLink ?? '';
    if (link.isEmpty) return;
    await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final job = _job;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Job')),
      body: _loading && job == null
          ? const Center(child: CircularProgressIndicator())
          : job == null
          ? Center(child: Text(_error ?? 'Job not found'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Text(
                  job.title,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  [
                    if (job.companyName.isNotEmpty) job.companyName,
                    if (job.place.isNotEmpty) job.place,
                  ].join(' · '),
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (job.category.isNotEmpty) _Pill(job.category),
                    if (job.employmentType.isNotEmpty) _Pill(job.employmentType),
                    if (job.workMode.isNotEmpty &&
                        job.workMode != 'Not specified')
                      _Pill(job.workMode),
                    if (job.salaryPosted && job.salaryDisplay.isNotEmpty)
                      _Pill(job.salaryDisplay),
                  ],
                ),
                if (job.experienceRequired.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _Fact('Experience', job.experienceRequired),
                ],
                if (job.educationRequired.isNotEmpty)
                  _Fact('Education', job.educationRequired),
                if (job.deadline.isNotEmpty)
                  _Fact('Applies until', job.deadline),
                const SizedBox(height: 18),
                Text(
                  job.description.isNotEmpty ? job.description : job.summary,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 15,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 22),
                if (job.applyLink.isNotEmpty)
                  FilledButton(
                    onPressed: _apply,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Apply',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.label);
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
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text.rich(
        TextSpan(
          text: '$label  ',
          style: const TextStyle(
            color: AppColors.muted,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          children: [
            TextSpan(
              text: value,
              style: const TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
