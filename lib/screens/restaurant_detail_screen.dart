import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/dial.dart';
import '../data/maps_config.dart';
import '../data/place_videos.dart';
import '../data/restaurant_menus.dart';
import '../data/restaurant_repository.dart';
import '../models/restaurant.dart';
import '../theme/app_theme.dart';
import '../widgets/motion.dart';
import 'place_reel_screen.dart';

class RestaurantDetailScreen extends StatefulWidget {
  const RestaurantDetailScreen({super.key, required this.place});

  final Restaurant place;

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  String? _videoId;
  Restaurant? _place;

  Restaurant get place => _place ?? widget.place;

  @override
  void initState() {
    super.initState();
    _place = widget.place;
    _loadVideo();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    final next = await RestaurantRepository.instance.fetchDetail(widget.place);
    if (!mounted) return;
    setState(() => _place = next);
  }

  Future<void> _loadVideo() async {
    final id = await PlaceVideos.forRestaurant(widget.place);
    if (!mounted || id == null || id.isEmpty) return;
    setState(() => _videoId = id);
  }

  @override
  Widget build(BuildContext context) {
    final place = this.place;
    final dishes = dishesFor(place);
    final point = LatLng(place.lat, place.lng);
    final ownPhoto = foodPhotoFor(place);
    final hasOwnPhoto = ownPhoto.isNotEmpty;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(place.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          if (_videoId != null) ...[
            ReelThumbnail(
              youtubeId: _videoId!,
              onTap: () => openCard(
                context,
                PlaceReelScreen(
                  youtubeId: _videoId!,
                  title: place.name,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (hasOwnPhoto)
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: SizedBox(
                height: _videoId == null ? 210 : 160,
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: ownPhoto,
                  httpHeaders: foodPhotoHeaders(ownPhoto),
                  fit: BoxFit.cover,
                  placeholder: (_, __) => ColoredBox(
                    color: cuisineColor(place.kind).withValues(alpha: 0.22),
                    child: const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => ColoredBox(
                    color: cuisineColor(place.kind).withValues(alpha: 0.4),
                    child: Icon(
                      Icons.restaurant_rounded,
                      color: cuisineColor(place.kind),
                      size: 48,
                    ),
                  ),
                ),
              ),
            )
          else if (_videoId == null)
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: SizedBox(
                height: 210,
                width: double.infinity,
                child: ColoredBox(
                  color: cuisineColor(place.kind).withValues(alpha: 0.4),
                  child: Icon(
                    Icons.restaurant_rounded,
                    color: cuisineColor(place.kind),
                    size: 48,
                  ),
                ),
              ),
            ),
          if (hasOwnPhoto || _videoId == null) const SizedBox(height: 12),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: SizedBox(
              height: 160,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(target: point, zoom: 15.2),
                style: kGoogleMapsDarkStyle,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                myLocationButtonEnabled: false,
                compassEnabled: false,
                liteModeEnabled: false,
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
                      _hueFor(place.kind),
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
              cuisineTitle(place.kind),
              if (place.cuisine.isNotEmpty) place.cuisine.replaceAll('_', ' '),
              if (place.city.isNotEmpty) place.city,
              if (place.rating > 0)
                '★ ${place.rating.toStringAsFixed(1)} (${place.ratings}${place.reviewSource.isNotEmpty ? ' ${place.reviewSource}' : ''})',
              if (place.km > 0)
                '${place.km < 10 ? place.km.toStringAsFixed(1) : place.km.toStringAsFixed(0)} km away',
            ].join('  ·  '),
            style: const TextStyle(color: AppColors.muted, height: 1.4),
          ),
          if (place.hours.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              place.hours,
              style: const TextStyle(color: AppColors.goldSoft, fontSize: 13),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: PressableScale(
                  onTap: () => openMap(place.lat, place.lng, place.name),
                  child: _ActionChip(
                    icon: Icons.map_rounded,
                    label: 'Directions',
                  ),
                ),
              ),
              if (place.phone.isNotEmpty) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: PressableScale(
                    onTap: () => callNumber(place.phone),
                    child: const _ActionChip(
                      icon: Icons.call_rounded,
                      label: 'Call',
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (place.web.isNotEmpty) ...[
            const SizedBox(height: 10),
            PressableScale(
              onTap: () => launchUrl(
                Uri.parse(place.web),
                mode: LaunchMode.externalApplication,
              ),
              child: const _ActionChip(
                icon: Icons.language_rounded,
                label: 'Website',
              ),
            ),
          ],
          const SizedBox(height: 22),
          const Text(
            'Menu',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            _menuNote(place),
            style: const TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 12),
          for (final dish in dishes)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.stroke),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (dish.image.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: dish.image,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dish.name,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dish.detail,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    dish.price,
                    style: const TextStyle(
                      color: AppColors.goldSoft,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _menuNote(Restaurant place) {
    if (place.dishes.isNotEmpty) {
      return 'Menu from HungerStation. Prices are what the listing showed.';
    }
    final n = place.name.toLowerCase();
    if (n.contains('baik') || n.contains('herfy') || n.contains('kudu')) {
      return 'Well-known items at this chain. Prices move by city.';
    }
    return 'Typical dishes for ${cuisineTitle(place.kind).toLowerCase()} kitchens in KSA. Ask in-store for today’s board.';
  }

  double _hueFor(String kind) {
    switch (kind) {
      case 'chinese':
        return BitmapDescriptor.hueRed;
      case 'desi':
        return BitmapDescriptor.hueOrange;
      case 'turkish':
        return BitmapDescriptor.hueRose;
      case 'italian':
        return BitmapDescriptor.hueGreen;
      case 'american':
        return BitmapDescriptor.hueYellow;
      case 'japanese':
        return BitmapDescriptor.hueViolet;
      case 'seafood':
        return BitmapDescriptor.hueCyan;
      case 'cafe':
        return BitmapDescriptor.hueAzure;
      default:
        return BitmapDescriptor.hueOrange;
    }
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
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.gold, size: 18),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
