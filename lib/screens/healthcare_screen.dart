import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../data/app_analytics.dart';
import '../data/healthcare_repository.dart';
import '../data/life_settings.dart';
import '../data/maps_config.dart';
import '../models/health_facility.dart';
import '../theme/app_theme.dart';
import '../widgets/map_pins.dart';
import '../widgets/motion.dart';
import 'healthcare_detail_screen.dart';

class HealthcareScreen extends StatefulWidget {
  const HealthcareScreen({super.key, this.initialKind = 'nearby'});

  final String initialKind;

  @override
  State<HealthcareScreen> createState() => _HealthcareScreenState();
}

class _HealthcareScreenState extends State<HealthcareScreen> {
  final _search = TextEditingController();
  GoogleMapController? _map;
  late String _kind = widget.initialKind;
  bool _mapView = false;
  HealthFacility? _picked;
  Timer? _moveDebounce;
  Timer? _searchDebounce;
  CameraPosition? _camera;
  final Map<String, BitmapDescriptor> _pinOff = {};
  final Map<String, BitmapDescriptor> _pinOn = {};
  BitmapDescriptor? _herePin;
  bool _locating = false;
  bool _didCenter = false;

  double _chromeHeight(BuildContext context) => 126;

  double _aboveTabs(BuildContext context) =>
      MediaQuery.paddingOf(context).bottom + 24;

  @override
  void initState() {
    super.initState();
    final settings = LifeSettings.instance;
    _camera = CameraPosition(
      target: LatLng(settings.prayerLat, settings.prayerLng),
      zoom: 14.2,
    );
    settings.addListener(_onSettings);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _locate(request: true);
    });
    _warmPins();
    AppAnalytics.instance.section('healthcare');
  }

  void _onSettings() {
    if (!mounted) return;
    final settings = LifeSettings.instance;
    if (settings.gpsLat == null) return;
    final here = LatLng(settings.prayerLat, settings.prayerLng);
    if (!_didCenter) {
      _didCenter = true;
      _camera = CameraPosition(target: here, zoom: 14.2);
      _map?.animateCamera(CameraUpdate.newLatLngZoom(here, 14.2));
    }
    HealthcareRepository.instance.refreshAround(here.latitude, here.longitude);
    setState(() {});
  }

  Future<void> _locate({bool request = true}) async {
    if (_locating) return;
    setState(() => _locating = true);
    await LifeSettings.instance.refreshGps(request: request);
    if (!mounted) return;
    final settings = LifeSettings.instance;
    final here = LatLng(settings.prayerLat, settings.prayerLng);
    _didCenter = true;
    _camera = CameraPosition(target: here, zoom: 14.2);
    await _map?.animateCamera(CameraUpdate.newLatLngZoom(here, 14.2));
    await HealthcareRepository.instance.refreshAround(
      here.latitude,
      here.longitude,
    );
    await HealthcareRepository.instance.refreshEmergency();
    if (!mounted) return;
    setState(() => _locating = false);
  }

  Future<void> _warmPins() async {
    await MapPins.warm({
      AppColors.green,
      AppColors.gold,
      const Color(0xFF3D6A94),
      const Color(0xFFB55242),
      const Color(0xFF2C7A68),
    });
    if (!mounted) return;
    final colors = {
      'hospital': const Color(0xFFB55242),
      'clinic': const Color(0xFF3D6A94),
      'health_centre': const Color(0xFF2C7A68),
      'doctors': const Color(0xFF6E5688),
      'pharmacy': AppColors.green,
    };
    final off = <String, BitmapDescriptor>{};
    final on = <String, BitmapDescriptor>{};
    for (final entry in colors.entries) {
      off[entry.key] = await MapPins.of(entry.value, selected: false);
      on[entry.key] = await MapPins.of(entry.value, selected: true);
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
    LifeSettings.instance.removeListener(_onSettings);
    super.dispose();
  }

  void _open(HealthFacility place) {
    AppAnalytics.instance.open(
      section: 'healthcare',
      targetId: place.id,
      title: place.name,
      category: _kind,
    );
    openCard(context, HealthcareDetailScreen(place: place));
  }

  Future<void> _onIdle() async {
    final camera = _camera;
    if (camera == null) return;
    if (!mounted) return;
    setState(() {});
    HealthcareRepository.instance.refreshAround(
      camera.target.latitude,
      camera.target.longitude,
    );
  }

  Color _colorFor(String kind) {
    switch (kind) {
      case 'hospital':
        return const Color(0xFFB55242);
      case 'clinic':
        return const Color(0xFF3D6A94);
      case 'health_centre':
        return const Color(0xFF2C7A68);
      case 'doctors':
        return const Color(0xFF6E5688);
      default:
        return AppColors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = LifeSettings.instance;
    final repo = HealthcareRepository.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([settings, repo]),
      builder: (context, _) {
        final lat = settings.prayerLat;
        final lng = settings.prayerLng;
        final here = LatLng(lat, lng);
        final origin = _mapView ? (_camera?.target ?? here) : here;
        final places = repo.nearby(
          lat: origin.latitude,
          lng: origin.longitude,
          kind: _kind,
          query: _search.text,
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
          appBar: AppBar(title: const Text('Healthcare')),
          body: Stack(
            children: [
              Positioned.fill(
                child: GoogleMap(
                  initialCameraPosition:
                      CameraPosition(target: here, zoom: 13.2),
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
                  onMapCreated: (controller) => _map = controller,
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
                              BitmapDescriptor.hueRed,
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
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        _chromeHeight(context),
                        16,
                        _aboveTabs(context) + 64,
                      ),
                      children: [
                        if (repo.steps.isNotEmpty) ...[
                          const Text(
                            'If this is an emergency',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          for (final step in repo.steps.take(3))
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                '• ${step.title}',
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          const SizedBox(height: 6),
                        ],
                        if (places.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 24),
                            child: Text(
                              'No places in this filter yet.',
                              style: TextStyle(color: AppColors.muted),
                            ),
                          )
                        else
                          for (final place in places)
                            _PlaceTile(
                              place: place,
                              color: _colorFor(place.kind),
                              onTap: () => _open(place),
                            ),
                      ],
                    ),
                  ),
                ),
              Positioned(
                left: 16,
                right: 16,
                top: 8,
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
                              HealthcareRepository.instance.searchRemote(
                                value,
                                origin.latitude,
                                origin.longitude,
                              );
                            },
                          );
                        },
                    decoration: const InputDecoration(
                      hintText: 'Search a hospital or clinic…',
                      prefixIcon: Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: AppColors.card,
                    ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        settings.gpsLat != null
                            ? 'From your GPS · ${settings.locationLabel}'
                            : (settings.locationError ??
                                'Using ${settings.city.name} until GPS is ready'),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: healthKinds.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final kind = healthKinds[index];
                          final selected = _kind == kind.id;
                          final color = _colorFor(
                            kind.id == 'nearby' ? 'hospital' : kind.id,
                          );
                          return PressableScale(
                            onTap: () {
                              setState(() => _kind = kind.id);
                              AppAnalytics.instance.category(
                                'healthcare',
                                kind.id,
                              );
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: selected
                                    ? color.withValues(alpha: 0.22)
                                    : AppColors.card,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: selected ? color : AppColors.stroke,
                                ),
                              ),
                              child: Text(
                                '${kind.icon}  ${kind.title}',
                                style: TextStyle(
                                  color: selected
                                      ? AppColors.navy
                                      : AppColors.muted,
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
                    child: _MapCard(
                      place: _picked!,
                      color: _colorFor(_picked!.kind),
                    ),
                  ),
                ),
              Positioned(
                left: 16,
                right: 16,
                bottom: _aboveTabs(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _LocateButton(
                      busy: _locating,
                      onTap: () => _locate(request: true),
                    ),
                    const SizedBox(width: 10),
                    _ModeButton(
                      mapView: _mapView,
                      onTap: () => setState(() {
                        _mapView = !_mapView;
                        _picked = null;
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LocateButton extends StatelessWidget {
  const _LocateButton({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: busy ? () {} : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (busy)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(Icons.my_location_rounded, color: AppColors.gold, size: 20),
            const SizedBox(width: 8),
            const Text(
              'My location',
              style: TextStyle(
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

class _PlaceTile extends StatelessWidget {
  const _PlaceTile({
    required this.place,
    required this.color,
    required this.onTap,
  });

  final HealthFacility place;
  final Color color;
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
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  place.emergency
                      ? Icons.local_hospital_rounded
                      : Icons.medical_services_outlined,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
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
                        healthKindTitle(place.kind),
                        if (place.emergency) 'ER',
                        if (place.city.isNotEmpty) place.city,
                        if (place.km > 0)
                          '${place.km < 10 ? place.km.toStringAsFixed(1) : place.km.toStringAsFixed(0)} km',
                      ].join('  ·  '),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
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
  const _MapCard({required this.place, required this.color});

  final HealthFacility place;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
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
              healthKindTitle(place.kind),
              if (place.emergency) 'emergency',
              if (place.phone.isNotEmpty) place.phone,
            ].join('  ·  '),
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
