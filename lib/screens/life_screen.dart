import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/app_tabs.dart';
import '../data/life_settings.dart';
import '../data/prayer_service.dart';
import '../theme/app_theme.dart';
import '../widgets/emergency_strip.dart';
import '../widgets/motion.dart';
import 'city_picker_screen.dart';
import 'emergency_screen.dart';
import 'lifestyle_screen.dart';
import 'tools_screens.dart';

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
              title: Text('Prayer & life'),
            ),
            SliverToBoxAdapter(
              child: FadeSlideIn(
                child: _PrayerPanel(settings: settings, prayers: prayers),
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
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.38,
                  children: [
                    _ToolTile(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Salary calculator',
                      subtitle: 'SAR to home currency',
                      onTap: () => openCard(context, const CalculatorScreen()),
                    ),
                    _ToolTile(
                      icon: Icons.translate_rounded,
                      title: 'Arabic phrases',
                      subtitle: 'Police, hospital, Absher',
                      onTap: () => openCard(context, const PhrasesScreen()),
                    ),
                    _ToolTile(
                      icon: Icons.family_restroom_rounded,
                      title: settings.lifestyle == Lifestyle.family
                          ? 'Family mode'
                          : 'Bachelor mode',
                      subtitle: 'Housing, visa, schools',
                      onTap: () => openCard(context, const LifestyleScreen()),
                    ),
                    _ToolTile(
                      icon: Icons.restaurant_rounded,
                      title: 'Restaurants',
                      subtitle: 'Map, cuisines and menus',
                      onTap: () => AppTabs.go(AppTabs.eat),
                    ),
                    _ToolTile(
                      icon: Icons.local_activity_rounded,
                      title: 'Play in KSA',
                      subtitle: 'Dunes, karting, snow, cinema',
                      onTap: () => AppTabs.go(AppTabs.play),
                    ),
                    _ToolTile(
                      icon: Icons.call_rounded,
                      title: 'Embassy & hospitals',
                      subtitle: 'By city and nationality',
                      onTap: () => openCard(context, const EmergencyScreen()),
                    ),
                  ],
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

class _PrayerPanel extends StatelessWidget {
  const _PrayerPanel({required this.settings, required this.prayers});

  final LifeSettings settings;
  final DayPrayers prayers;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.stroke),
          gradient: const LinearGradient(
            colors: [Color(0xFF0B3D2A), Color(0xFF145C3E), Color(0xFF1A6B42)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PressableScale(
              onTap: () => openCard(context, const CityPickerScreen()),
              child: Row(
                children: [
                  const Icon(Icons.place_rounded, color: AppColors.goldBright, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      settings.locationLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    settings.useGps ? 'GPS' : 'Manual',
                    style: const TextStyle(color: AppColors.goldBright, fontSize: 12),
                  ),
                  const Icon(Icons.expand_more, color: AppColors.goldBright),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              prayers.hijri,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              DateFormat.yMMMMEEEEd().format(prayers.gregorian),
              style: const TextStyle(color: Color(0xCCFFFFFF)),
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
                color: AppColors.goldBright,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
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
                              ? AppColors.goldBright
                              : const Color(0xCCFFFFFF),
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
                            ? AppColors.goldBright
                            : Colors.white,
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
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => settings.refreshGps(request: true),
              icon: const Icon(Icons.my_location, color: AppColors.goldBright),
              label: const Text(
                'Use my location',
                style: TextStyle(color: AppColors.goldBright, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x33D4B483),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.goldBright, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.stroke),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.gold),
            const Spacer(),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            Text(
              subtitle,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
