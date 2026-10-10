import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/life_settings.dart';
import '../data/prayer_service.dart';
import '../theme/app_theme.dart';
import '../widgets/emergency_strip.dart';
import '../widgets/motion.dart';
import 'city_picker_screen.dart';
import 'emergency_screen.dart';

class LifeScreen extends StatefulWidget {
  const LifeScreen({super.key});

  @override
  State<LifeScreen> createState() => _LifeScreenState();
}

class _LifeScreenState extends State<LifeScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = LifeSettings.instance;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final prayers = PrayerService.forLocation(
          settings.prayerLat,
          settings.prayerLng,
        );
        return Scaffold(
          backgroundColor: AppColors.bg,
          body: CustomScrollView(
            slivers: [
              const SliverAppBar(
                pinned: true,
                title: Text('Prayer times'),
              ),
              SliverToBoxAdapter(
                child: FadeSlideIn(
                  child: PrayerTimesPanel(settings: settings, prayers: prayers),
                ),
              ),
              SliverToBoxAdapter(
                child: FadeSlideIn(
                  delay: const Duration(milliseconds: 80),
                  child: EmergencyStrip(
                    onSeeAll: () => openCard(context, const EmergencyScreen()),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          ),
        );
      },
    );
  }
}

/// Prayer times + emergency contacts — used on the Profile tab.
class PrayerLifeBody extends StatefulWidget {
  const PrayerLifeBody({super.key});

  @override
  State<PrayerLifeBody> createState() => _PrayerLifeBodyState();
}

class _PrayerLifeBodyState extends State<PrayerLifeBody> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = LifeSettings.instance;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final prayers = PrayerService.forLocation(
          settings.prayerLat,
          settings.prayerLng,
        );
        return Column(
          children: [
            FadeSlideIn(
              child: PrayerTimesPanel(
                settings: settings,
                prayers: prayers,
                compact: true,
              ),
            ),
            FadeSlideIn(
              delay: const Duration(milliseconds: 80),
              child: EmergencyStrip(
                onSeeAll: () => openCard(context, const EmergencyScreen()),
              ),
            ),
          ],
        );
      },
    );
  }
}

class PrayerTimesPanel extends StatelessWidget {
  const PrayerTimesPanel({
    required this.settings,
    required this.prayers,
    this.compact = false,
  });

  final LifeSettings settings;
  final DayPrayers prayers;
  final bool compact;

  static const _accents = [
    Color(0xFFC9842A),
    Color(0xFFC45C4A),
    Color(0xFF2F6F8F),
    Color(0xFF6B4C9A),
    Color(0xFF1E7A4C),
    Color(0xFF8A5E2E),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: compact
              ? () => openCard(context, const LifeScreen())
              : null,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.stroke),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 5,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFE8B84A),
                        Color(0xFFC45C4A),
                        Color(0xFF4C8DFF),
                        Color(0xFF2BB673),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 14, 16, compact ? 14 : 12),
                  child: compact ? _compact(context) : _full(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _compact(BuildContext context) {
    final slots = prayers.slots.where((s) => s.key != 'Sunrise').toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF4E4C4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.wb_twilight_rounded,
                color: Color(0xFF8A5E2E),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next ${prayers.nextName}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    'in ${PrayerService.countdown(prayers.nextTime)} · ${settings.locationLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (var i = 0; i < slots.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: _TimeChip(
                  name: slots[i].key,
                  time: DateFormat('h:mm').format(slots[i].value),
                  active: slots[i].key == prayers.nextName,
                  accent: _accents[i % _accents.length],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _full(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PressableScale(
          onTap: () => openCard(context, const CityPickerScreen()),
          child: Row(
            children: [
              const Icon(Icons.place_rounded, color: AppColors.gold, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  settings.locationLabel,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                settings.useGps ? 'GPS' : 'Manual',
                style: const TextStyle(color: AppColors.gold, fontSize: 12),
              ),
              const Icon(Icons.expand_more, color: AppColors.gold),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          prayers.hijri,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        Text(
          DateFormat.yMMMMEEEEd().format(prayers.gregorian),
          style: const TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            if (prayers.isRamadan) _pill('Ramadan'),
            if (prayers.isWeekend) _pill('Weekend (Fri–Sat)'),
            _pill('Umm Al-Qura'),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Next ${prayers.nextName} in ${PrayerService.countdown(prayers.nextTime)}',
          style: const TextStyle(
            color: AppColors.gold,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        for (final slot in prayers.slots)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 78,
                  child: Text(
                    slot.key,
                    style: TextStyle(
                      color: slot.key == prayers.nextName
                          ? AppColors.gold
                          : AppColors.muted,
                      fontWeight: slot.key == prayers.nextName
                          ? FontWeight.w800
                          : FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  PrayerService.formatTime(slot.value),
                  style: TextStyle(
                    color: slot.key == prayers.nextName
                        ? AppColors.navy
                        : AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        if (settings.locationError != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              settings.locationError!,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ),
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: () => settings.refreshGps(request: true),
          icon: const Icon(Icons.my_location, color: AppColors.gold),
          label: const Text(
            'Use my location',
            style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x14C9842A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.gold,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({
    required this.name,
    required this.time,
    required this.active,
    required this.accent,
  });

  final String name;
  final String time;
  final bool active;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      decoration: BoxDecoration(
        color: active ? accent.withValues(alpha: 0.14) : AppColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? accent.withValues(alpha: 0.45) : AppColors.stroke,
        ),
      ),
      child: Column(
        children: [
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: active ? accent : AppColors.muted,
              fontWeight: FontWeight.w800,
              fontSize: 9.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            time,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: active ? AppColors.navy : AppColors.ink,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
