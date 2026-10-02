import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/activity_photos.dart';
import '../data/activity_store.dart';
import '../data/dial.dart';
import '../data/ksa_activities.dart';
import '../data/life_settings.dart';
import '../data/maps_config.dart';
import '../data/activity_clips.dart';
import '../models/activity.dart';
import '../theme/app_theme.dart';
import '../widgets/activity_photo.dart';
import '../widgets/motion.dart';
import '../widgets/short_clip.dart';

class ActivityDetailScreen extends StatelessWidget {
  const ActivityDetailScreen({super.key, required this.activity});

  final KsaActivity activity;

  @override
  Widget build(BuildContext context) {
    final settings = LifeSettings.instance;
    final here = activity.km > 0
        ? activity
        : activity.withDistance(
            KsaActivity.kmBetween(
              settings.prayerLat,
              settings.prayerLng,
              activity.lat,
              activity.lng,
            ),
          );
    final similar = activitiesNear(
      activity.lat,
      activity.lng,
      kind: activity.kind,
      limit: 6,
    ).where((item) => item.id != activity.id).take(4).toList();
    final point = LatLng(activity.lat, activity.lng);
    final meta = kindMeta(activity.kind);
    final clip = activity.video.trim().isNotEmpty
        ? activity.video.trim()
        : clipForActivity(activity.id);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(activity.name),
        actions: [
          ListenableBuilder(
            listenable: ActivityStore.instance,
            builder: (context, _) {
              final saved = ActivityStore.instance.isSaved(activity.id);
              return IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ActivityStore.instance.toggle(activity.id);
                },
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: Icon(
                    saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    key: ValueKey(saved),
                    color: saved ? AppColors.red : AppColors.goldSoft,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          if (clip != null) ...[
            ShortClip(youtubeId: clip),
            const SizedBox(height: 14),
          ] else
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: SizedBox(
                height: 240,
                width: double.infinity,
                child: ActivityPhoto(
                  url: activityPhotoFor(activity),
                  kind: activity.kind,
                  heroTag: 'activity-image-${activity.id}',
                ),
              ),
            ),
          const SizedBox(height: 14),
          Text(
            '${meta.icon}  ${meta.title}  ·  ${activity.city}',
            style: const TextStyle(
              color: AppColors.gold,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            activity.name,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 26,
              letterSpacing: -0.5,
              height: 1.15,
            ),
          ),
          if (activity.area.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(activity.area, style: const TextStyle(color: AppColors.muted)),
          ],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.stroke),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Typical 2026 price',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activity.priceLabel,
                        style: const TextStyle(
                          color: AppColors.green,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                if (here.km > 0)
                  Text(
                    '${here.km < 10 ? here.km.toStringAsFixed(1) : here.km.toStringAsFixed(0)} km',
                    style: const TextStyle(
                      color: AppColors.goldSoft,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            activity.about,
            style: const TextStyle(height: 1.45, color: AppColors.ink),
          ),
          const SizedBox(height: 8),
          Text(
            activity.hours,
            style: const TextStyle(color: AppColors.goldSoft, fontSize: 13),
          ),
          const SizedBox(height: 8),
          const Text(
            'Prices move with season, weekend and promo codes. This is the usual walk-up range in 2026 — confirm on the venue site before you go.',
            style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: SizedBox(
              height: 160,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(target: point, zoom: 13.4),
                style: kGoogleMapsDarkStyle,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                myLocationButtonEnabled: false,
                compassEnabled: false,
                gestureRecognizers: {
                  Factory<OneSequenceGestureRecognizer>(
                    () => EagerGestureRecognizer(),
                  ),
                },
                markers: {
                  Marker(
                    markerId: MarkerId(activity.id),
                    position: point,
                    infoWindow: InfoWindow(title: activity.name),
                  ),
                },
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: PressableScale(
                  onTap: () => openMap(activity.lat, activity.lng, activity.name),
                  child: const _ActionChip(
                    icon: Icons.map_rounded,
                    label: 'Directions',
                  ),
                ),
              ),
              if (activity.phone.isNotEmpty) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: PressableScale(
                    onTap: () => callNumber(activity.phone),
                    child: const _ActionChip(
                      icon: Icons.call_rounded,
                      label: 'Call',
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (activity.web.isNotEmpty) ...[
            const SizedBox(height: 10),
            PressableScale(
              onTap: () => launchUrl(
                Uri.parse(activity.web),
                mode: LaunchMode.externalApplication,
              ),
              child: const _ActionChip(
                icon: Icons.language_rounded,
                label: 'Tickets & site',
              ),
            ),
          ],
          if (similar.isNotEmpty) ...[
            const SizedBox(height: 26),
            const Text(
              'Same vibe nearby',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 10),
            for (final item in similar)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: PressableScale(
                  onTap: () => Navigator.of(context).pushReplacement(
                    SoftPageRoute(page: ActivityDetailScreen(activity: item)),
                  ),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.stroke),
                    ),
                    tileColor: AppColors.card,
                    title: Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(item.priceLabel),
                    trailing: const Icon(Icons.chevron_right_rounded),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.gold, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.goldSoft,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
