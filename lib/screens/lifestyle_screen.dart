import 'package:flutter/material.dart';

import '../data/content_repository.dart';
import '../data/life_settings.dart';
import '../theme/app_theme.dart';
import '../widgets/motion.dart';
import '../widgets/post_cards.dart';
import 'post_detail_screen.dart';

class LifestyleScreen extends StatelessWidget {
  const LifestyleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = LifeSettings.instance;
    final repo = ContentRepository.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Family or bachelor')),
      body: ListenableBuilder(
        listenable: settings,
        builder: (context, _) {
          final family = settings.lifestyle == Lifestyle.family;
          final guides = repo.guidesForLifestyle(
            family ? 'family' : 'bachelor',
            limit: 16,
          );
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _ModeChip(
                      title: 'Family',
                      selected: family,
                      onTap: () => settings.setLifestyle(Lifestyle.family),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ModeChip(
                      title: 'Bachelor',
                      selected: !family,
                      onTap: () => settings.setLifestyle(Lifestyle.bachelor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                family
                    ? 'Family mode highlights visas, schools, health, housing and Hajj.'
                    : 'Bachelor mode highlights jobs, work visa, iqama transfer, traffic and banks.',
                style: const TextStyle(color: AppColors.muted, height: 1.4),
              ),
              const SizedBox(height: 16),
              for (final tip in family ? _familyTips : _bachelorTips)
                _TipCard(title: tip.$1, body: tip.$2),
              const SizedBox(height: 12),
              const Text(
                'Guides for you',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 10),
              for (final post in guides)
                PostListTileCard(
                  post: post,
                  pad: false,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PostDetailScreen(post: post),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.greenDeep : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.gold : AppColors.stroke,
            width: selected ? 1.2 : 1,
          ),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? AppColors.onDark : AppColors.navy,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(body, style: const TextStyle(color: AppColors.muted, height: 1.4)),
        ],
      ),
    );
  }
}

const _familyTips = <(String, String)>[
  (
    'Housing',
    'Family compounds and closed apartments are easier than shared bachelor housing. Ejar the contract in Absher before you pay a big deposit.',
  ),
  (
    'Visas',
    'Family visit and permanent family visa both need iqama, salary, and housing proof. Start the visit visa in Absher before school term.',
  ),
  (
    'Schools',
    'International seats fill early in Riyadh, Jeddah and Khobar. Ask HR about education allowance before you sign.',
  ),
];

const _bachelorTips = <(String, String)>[
  (
    'Housing',
    'Company accommodation or a shared flat is the usual start. Keep your lease and iqama address matching Absher.',
  ),
  (
    'Work visa & iqama',
    'Your first months are medical, iqama, Absher and bank. Do not travel without exit/re-entry once the iqama is issued.',
  ),
  (
    'Job change',
    'Sponsorship transfer needs Qiwa + the current employer. Huroob status is serious — get HR letters in writing.',
  ),
];
