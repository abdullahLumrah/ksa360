import 'package:flutter/material.dart';

import '../data/dial.dart';
import '../data/emergencies.dart';
import '../data/healthcare_repository.dart';
import '../data/life_settings.dart';
import '../models/health_facility.dart';
import '../theme/app_theme.dart';
import '../widgets/motion.dart';
import 'embassy_directory_screen.dart';
import 'healthcare_detail_screen.dart';
import 'healthcare_screen.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = LifeSettings.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency')),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          settings,
          HealthcareRepository.instance,
        ]),
        builder: (context, _) {
          final health = HealthcareRepository.instance;
          final hotlines = health.hotlines.isNotEmpty
              ? health.hotlines
              : [
                  for (final line in EmergencyData.hotlines)
                    HealthHotline(
                      id: line.number,
                      label: line.label,
                      number: line.number,
                      detail: line.detail,
                    ),
                ];
          final nearby = health.nearby(
            lat: settings.prayerLat,
            lng: settings.prayerLng,
            emergencyOnly: true,
            limit: 8,
          );
          final hospitals = nearby.isNotEmpty
              ? nearby
              : const <HealthFacility>[];
          final posts = EmergencyData.embassiesFor(settings.nationality);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              const Text(
                'Tap to call. 911 works in every region of Saudi Arabia.',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              for (final line in hotlines)
                _CallTile(
                  title: '${line.label}  ·  ${line.number}',
                  subtitle: line.detail,
                  number: line.number,
                  highlight: line.number == '911',
                ),
              if (health.steps.isNotEmpty) ...[
                const SizedBox(height: 18),
                const Text(
                  'What to do',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 8),
                for (final step in health.steps)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${step.title}\n${step.detail}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        height: 1.35,
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Hospitals near ${settings.gpsLat != null ? settings.locationLabel : settings.city.name}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        openCard(context, const HealthcareScreen()),
                    child: const Text('Map'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (hospitals.isNotEmpty)
                for (final h in hospitals)
                  _CallTile(
                    title: h.name,
                    subtitle: [
                      if (h.phone.isNotEmpty) h.phone,
                      healthKindTitle(h.kind),
                      if (h.km > 0)
                        '${h.km < 10 ? h.km.toStringAsFixed(1) : h.km.toStringAsFixed(0)} km',
                    ].join('  ·  '),
                    number: h.phone,
                    onOpen: () =>
                        openCard(context, HealthcareDetailScreen(place: h)),
                  )
              else
                for (final h in EmergencyData.hospitalsNear(settings.cityId))
                  _CallTile(title: h.name, subtitle: h.phone, number: h.phone),
              const SizedBox(height: 18),
              const Text(
                'Embassy / consulate',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 8),
              _AllEmbassiesTile(
                countries: EmergencyData.nationalities.length,
                missions: EmergencyData.embassies.length,
              ),
              const SizedBox(height: 10),
              const Text(
                'Your country',
                style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const SizedBox(height: 6),
              InputDecorator(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.card,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.stroke),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.gold, width: 1.2),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    menuMaxHeight: 440,
                    value: EmergencyData.nationalities.any((n) => n.id == settings.nationality)
                        ? settings.nationality
                        : null,
                    hint: const Text('Choose your country'),
                    items: [
                      for (final n in EmergencyData.nationalities)
                        DropdownMenuItem(
                          value: n.id,
                          child: Text(
                            '${EmergencyData.embassies.firstWhere((e) => e.nationalityId == n.id).flagEmoji}  ${n.name}',
                          ),
                        ),
                    ],
                    onChanged: (id) {
                      if (id != null) settings.setNationality(id);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (posts.isEmpty)
                const Text(
                  'No embassy listing for this nationality yet.',
                  style: TextStyle(color: AppColors.muted),
                )
              else
                for (final e in posts)
                  _CallTile(
                    title: '${e.flagEmoji}  ${e.kind} · ${e.city}',
                    subtitle: [
                      formatSaudiPhone(e.phone),
                      if (e.altPhone != null) formatSaudiPhone(e.altPhone!),
                    ].join('  ·  '),
                    number: e.phone,
                  ),
              const SizedBox(height: 12),
              const Text(
                'Numbers can change. Confirm on the mission’s website if you cannot get through.',
                style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AllEmbassiesTile extends StatelessWidget {
  const _AllEmbassiesTile({required this.countries, required this.missions});

  final int countries;
  final int missions;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: () => openCard(context, const EmbassyDirectoryScreen()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.greenDeep, Color(0xFF1B5E40)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const Icon(Icons.public_rounded, color: AppColors.goldBright, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'All embassies & consulates',
                    style: TextStyle(
                      color: AppColors.onDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    '$countries countries · $missions missions in Riyadh and Jeddah',
                    style: const TextStyle(color: AppColors.goldBright, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.onDark),
          ],
        ),
      ),
    );
  }
}

class _CallTile extends StatelessWidget {
  const _CallTile({
    required this.title,
    required this.subtitle,
    required this.number,
    this.highlight = false,
    this.onOpen,
  });

  final String title;
  final String subtitle;
  final String number;
  final bool highlight;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PressableScale(
        onTap: () {
          if (number.trim().isNotEmpty) {
            callNumber(number);
          } else {
            onOpen?.call();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: highlight ? const Color(0x22B42318) : AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: highlight ? AppColors.red.withValues(alpha: 0.55) : AppColors.stroke,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.call_rounded,
                color: highlight ? AppColors.red : AppColors.gold,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(
                      subtitle,
                      style: const TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
