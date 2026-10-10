import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../data/app_analytics.dart';
import '../data/life_settings.dart';
import '../data/maps_config.dart';
import '../data/restaurant_menus.dart';
import '../data/restaurant_repository.dart';
import '../models/restaurant.dart';
import '../theme/app_theme.dart';
import '../widgets/map_pins.dart';
import '../widgets/motion.dart';
import 'restaurant_detail_screen.dart';

class EatScreen extends StatefulWidget {
  const EatScreen({super.key});

  @override
  State<EatScreen> createState() => _EatScreenState();
}

class _EatScreenState extends State<EatScreen> {
  final _search = TextEditingController();
  GoogleMapController? _map;
  String _kind = 'nearby';
  bool _mapView = false;
  Restaurant? _picked;
  Timer? _moveDebounce;
  Timer? _searchDebounce;
  CameraPosition? _camera;
  final Map<String, BitmapDescriptor> _pinOff = {};
  final Map<String, BitmapDescriptor> _pinOn = {};
  BitmapDescriptor? _herePin;

  double _chromeHeight(BuildContext context) =>
      MediaQuery.paddingOf(context).top + 118;

  double _aboveTabs(BuildContext context) =>
      MediaQuery.paddingOf(context).bottom + 76;

  @override
  void initState() {
    super.initState();
    final settings = LifeSettings.instance;
    _camera = CameraPosition(
      target: LatLng(settings.prayerLat, settings.prayerLng),
      zoom: 13.2,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      RestaurantRepository.instance.refreshAround(
        settings.prayerLat,
        settings.prayerLng,
      );
    });
    _warmPins();
  }

  Future<void> _warmPins() async {
    final colors = {
      for (final kind in cuisineKinds)
        if (kind.id != 'nearby') cuisineColor(kind.id),
      cuisineColor('arab'),
      cuisineColor('thai'),
      AppColors.green,
    };
    await MapPins.warm(colors);
    if (!mounted) return;
    final off = <String, BitmapDescriptor>{};
    final on = <String, BitmapDescriptor>{};
    for (final kind in [
      'arab',
      'chinese',
      'desi',
      'turkish',
      'italian',
      'american',
      'japanese',
      'seafood',
      'cafe',
      'thai',
      'korean',
    ]) {
      off[kind] = await MapPins.of(cuisineColor(kind), selected: false);
      on[kind] = await MapPins.of(cuisineColor(kind), selected: true);
    }
    final here = await MapPins.of(AppColors.green, selected: true);
    if (!mounted) return;
    setState(() {
      _pinOff.addAll(off);
      _pinOn.addAll(on);
      _herePin = here;
    });
  }

  @override
  void dispose() {
    _moveDebounce?.cancel();
    _searchDebounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _open(Restaurant place) {
    AppAnalytics.instance.open(
      section: 'eat',
      targetId: place.id,
      title: place.name,
      category: _kind,
    );
    openCard(context, RestaurantDetailScreen(place: place));
  }

  Future<void> _onIdle() async {
    final camera = _camera;
    if (camera == null) return;
    if (!mounted) return;
    setState(() {});
    RestaurantRepository.instance.refreshAround(
      camera.target.latitude,
      camera.target.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = LifeSettings.instance;
    final repo = RestaurantRepository.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([settings, repo]),
      builder: (context, _) {
        final lat = settings.prayerLat;
        final lng = settings.prayerLng;
        final here = LatLng(lat, lng);
        final origin = _camera?.target ?? here;
        final places = repo.nearby(
          lat: origin.latitude,
          lng: origin.longitude,
          kind: _kind,
          query: _search.text,
          preferCity: settings.city.name,
        );
        final zoom = _camera?.zoom ?? 13.2;
        final radiusKm = zoom >= 14.2
            ? 6.0
            : zoom >= 13
                ? 12.0
                : zoom >= 12
                    ? 22.0
                    : 45.0;
        final pins = _search.text.trim().isEmpty
            ? [
                for (final place in places)
                  if (place.km <= radiusKm) place,
              ]
            : places.take(40).toList();

        return Scaffold(
          backgroundColor: AppColors.bg,
          extendBody: true,
          body: Stack(
            children: [
            Positioned.fill(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(target: here, zoom: 13.2),
                style: kGoogleMapsDarkStyle,
                compassEnabled: false,
                mapToolbarEnabled: false,
                zoomControlsEnabled: false,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                buildingsEnabled: false,
                indoorViewEnabled: false,
                padding: EdgeInsets.only(
                  top: _chromeHeight(context),
                  bottom: _picked == null
                      ? _aboveTabs(context) + 56
                      : _aboveTabs(context) + 160,
                ),
                onMapCreated: (controller) {
                  _map = controller;
                },
                onCameraMove: (position) => _camera = position,
                onCameraIdle: () {
                  _moveDebounce?.cancel();
                  _moveDebounce = Timer(const Duration(milliseconds: 500), () {
                    if (mounted) _onIdle();
                  });
                },
                onTap: (_) => setState(() => _picked = null),
                markers: {
                  Marker(
                    markerId: const MarkerId('here'),
                    position: here,
                    zIndexInt: 10000,
                    icon: _herePin ??
                        BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueCyan,
                        ),
                    infoWindow: const InfoWindow(title: 'You'),
                  ),
                  for (final place in pins)
                    Marker(
                      markerId: MarkerId(place.id),
                      position: LatLng(place.lat, place.lng),
                      zIndexInt: _picked?.id == place.id ? 9999 : 1,
                      icon: (_picked?.id == place.id
                              ? _pinOn[place.kind]
                              : _pinOff[place.kind]) ??
                          BitmapDescriptor.defaultMarkerWithHue(
                            _hueFor(place.kind),
                          ),
                      onTap: () => setState(() => _picked = place),
                    ),
                },
              ),
            ),
            if (!_mapView)
              Positioned.fill(
                child: ColoredBox(
                  color: AppColors.bg,
                  child: places.isEmpty
                      ? const Center(
                          child: Text(
                            'No places in this filter yet.',
                            style: TextStyle(color: AppColors.muted),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            _chromeHeight(context),
                            16,
                            _aboveTabs(context) + 64,
                          ),
                          itemCount: places.length,
                          itemBuilder: (context, index) {
                            return _PlaceTile(
                              place: places[index],
                              onTap: () => _open(places[index]),
                            );
                          },
                        ),
                ),
              ),
            Positioned(
              left: 16,
              right: 16,
              top: MediaQuery.paddingOf(context).top + 8,
              child: Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: TextField(
                    controller: _search,
                    onChanged: (value) {
                      setState(() {});
                      _searchDebounce?.cancel();
                      _searchDebounce = Timer(
                        const Duration(milliseconds: 550),
                        () {
                          RestaurantRepository.instance.searchRemote(
                            value,
                            origin.latitude,
                            origin.longitude,
                          );
                        },
                      );
                    },
                    decoration: const InputDecoration(
                      hintText: 'Search a restaurant…',
                      prefixIcon: Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: AppColors.card,
                    ),
                  ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: cuisineKinds.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final kind = cuisineKinds[index];
                        final selected = _kind == kind.id;
                        return PressableScale(
                          onTap: () {
                            setState(() => _kind = kind.id);
                            AppAnalytics.instance.category('eat', kind.id);
                            if (_mapView) {
                              _map?.animateCamera(
                                CameraUpdate.newLatLngZoom(
                                  here,
                                  kind.id == 'nearby' ? 13.2 : 12.6,
                                ),
                              );
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected
                                  ? cuisineColor(
                                        kind.id == 'nearby' ? 'arab' : kind.id,
                                      ).withValues(alpha: 0.22)
                                  : AppColors.card,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected
                                    ? cuisineColor(
                                        kind.id == 'nearby' ? 'arab' : kind.id,
                                      )
                                    : AppColors.stroke,
                              ),
                            ),
                            child: Text(
                              '${kind.icon}  ${kind.title}',
                              style: TextStyle(
                                color: selected ? AppColors.navy : AppColors.muted,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (_mapView && _picked != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: _aboveTabs(context) + 58,
                child: PressableScale(
                  onTap: () => _open(_picked!),
                  child: _MapCard(place: _picked!),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: _aboveTabs(context),
              child: Center(
                child: _ModeButton(
                  mapView: _mapView,
                  onTap: () => setState(() {
                    _mapView = !_mapView;
                    _picked = null;
                  }),
                ),
              ),
            ),
            ],
          ),
        );
      },
    );
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

class _ModeButton extends StatelessWidget {
  const _ModeButton({required this.mapView, required this.onTap});

  final bool mapView;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = mapView ? Icons.view_list_rounded : Icons.location_on_rounded;
    final label = mapView ? 'List' : 'Map';
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.gold, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.goldSoft,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlacePhoto extends StatelessWidget {
  const _PlacePhoto({required this.place, this.height = 86, this.width = 86});

  final Restaurant place;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    final url = foodPhotoFor(place);
    final fallback = cuisineFallbackPhoto(place);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: height,
        width: width,
        child: CachedNetworkImage(
          imageUrl: url,
          httpHeaders: foodPhotoHeaders(url),
          fit: BoxFit.cover,
          placeholder: (_, __) => _PhotoLoader(
            color: cuisineColor(place.kind),
            size: width < 70 ? 16 : 22,
          ),
          errorWidget: (_, __, ___) {
            if (url == fallback) {
              return ColoredBox(
                color: cuisineColor(place.kind).withValues(alpha: 0.4),
                child: Icon(Icons.restaurant_rounded, color: cuisineColor(place.kind)),
              );
            }
            return CachedNetworkImage(
              imageUrl: fallback,
              httpHeaders: foodPhotoHeaders(fallback),
              fit: BoxFit.cover,
              placeholder: (_, __) => _PhotoLoader(
                color: cuisineColor(place.kind),
                size: width < 70 ? 16 : 22,
              ),
              errorWidget: (_, __, ___) => ColoredBox(
                color: cuisineColor(place.kind).withValues(alpha: 0.4),
                child: Icon(Icons.restaurant_rounded, color: cuisineColor(place.kind)),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PhotoLoader extends StatelessWidget {
  const _PhotoLoader({required this.color, this.size = 22});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: color.withValues(alpha: 0.22),
      child: Center(
        child: SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: size < 18 ? 2 : 2.4,
            color: AppColors.gold,
          ),
        ),
      ),
    );
  }
}

class _PlaceTile extends StatelessWidget {
  const _PlaceTile({required this.place, required this.onTap});

  final Restaurant place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PressableScale(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.stroke),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              _PlacePhoto(place: place, height: 92, width: 92),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          cuisineTitle(place.kind),
                          if (place.city.isNotEmpty) place.city,
                          if (place.rating > 0)
                            '★ ${place.rating.toStringAsFixed(1)}',
                          if (place.km > 0)
                            '${place.km < 10 ? place.km.toStringAsFixed(1) : place.km.toStringAsFixed(0)} km',
                        ].join('  ·  '),
                        style: const TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  const _MapCard({required this.place});

  final Restaurant place;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cuisineColor(place.kind).withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          _PlacePhoto(place: place, height: 92, width: 104),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    place.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      cuisineTitle(place.kind),
                      if (place.rating > 0)
                        '★ ${place.rating.toStringAsFixed(1)}',
                      'tap for menu',
                    ].join('  ·  '),
                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
