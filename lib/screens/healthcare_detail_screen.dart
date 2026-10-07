import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/dial.dart';
import '../data/maps_config.dart';
import '../models/health_facility.dart';
import '../theme/app_theme.dart';
import '../widgets/motion.dart';

class HealthcareDetailScreen extends StatelessWidget {
  const HealthcareDetailScreen({super.key, required this.place});

  final HealthFacility place;

  @override
  Widget build(BuildContext context) {
    final point = LatLng(place.lat, place.lng);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(place.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          if (place.emergency)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFB55242).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFB55242).withValues(alpha: 0.4),
                ),
              ),
              child: const Text(
                'This facility is marked for emergency care. If life is at risk, call 911 or 997 first, then come here.',
                style: TextStyle(height: 1.35, fontWeight: FontWeight.w600),
              ),
            ),
          if (place.emergency) const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: SizedBox(
              height: 180,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(target: point, zoom: 15.2),
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
                    markerId: MarkerId(place.id),
                    position: point,
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      place.emergency
                          ? BitmapDescriptor.hueRed
                          : BitmapDescriptor.hueAzure,
                    ),
                  ),
                },
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            place.name,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            [
              healthKindTitle(place.kind),
              if (place.city.isNotEmpty) place.city,
              if (place.km > 0)
                '${place.km < 10 ? place.km.toStringAsFixed(1) : place.km.toStringAsFixed(0)} km away',
            ].join('  ·  '),
            style: const TextStyle(color: AppColors.muted, height: 1.4),
          ),
          if (place.services.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final service in place.services)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.stroke),
                    ),
                    child: Text(
                      service,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (place.phone.isNotEmpty)
                _Action(
                  label: 'Call ${place.phone}',
                  icon: Icons.call_rounded,
                  onTap: () => callNumber(place.phone),
                ),
              _Action(
                label: 'Directions',
                icon: Icons.directions_rounded,
                onTap: () => openMap(place.lat, place.lng, place.name),
              ),
              if (place.web.isNotEmpty)
                _Action(
                  label: 'Website',
                  icon: Icons.public_rounded,
                  onTap: () => launchUrl(
                    Uri.parse(place.web),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
            ],
          ),
          if (place.hours.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              place.hours,
              style: const TextStyle(color: AppColors.muted, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.gold),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.gold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
