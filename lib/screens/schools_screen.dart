import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../data/app_analytics.dart';
import '../data/life_settings.dart';
import '../data/maps_config.dart';
import '../data/school_photos.dart';
import '../data/school_repository.dart';
import '../models/school.dart';
import '../theme/app_theme.dart';
import '../widgets/map_pins.dart';
import '../widgets/motion.dart';
import '../widgets/school_photo.dart';
import 'school_detail_screen.dart';

class SchoolsScreen extends StatefulWidget {
  const SchoolsScreen({super.key});

  @override
  State<SchoolsScreen> createState() => _SchoolsScreenState();
}

class _SchoolsScreenState extends State<SchoolsScreen> {
  final _search = TextEditingController();
  GoogleMapController? _map;
  String _curriculum = 'nearby';
  bool _mapView = false;
  School? _picked;
  Timer? _moveDebounce;
  Timer? _searchDebounce;
  CameraPosition? _camera;
  final Map<String, BitmapDescriptor> _pinOff = {};
  final Map<String, BitmapDescriptor> _pinOn = {};
  BitmapDescriptor? _herePin;
  bool _locating = false;

  double _chromeHeight(BuildContext context) => 126;

  double _aboveTabs(BuildContext context) =>
      MediaQuery.paddingOf(context).bottom + 24;

  @override
  void initState() {
    super.initState();
    final settings = LifeSettings.instance;
    _camera = CameraPosition(
      target: LatLng(settings.prayerLat, settings.prayerLng),
      zoom: 13.2,
    );
    final repo = SchoolRepository.instance;
    repo.refreshAround(settings.prayerLat, settings.prayerLng);
    repo.refreshCatalog();
    repo.refreshFilters();
    AppAnalytics.instance.section('schools');
    _warmPins();
  }

  Future<void> _warmPins() async {
    final colors = {
      schoolPinColor(const School(id: '', name: '', curriculumTags: ['american'])),
      schoolPinColor(const School(id: '', name: '', curriculumTags: ['british'])),
      schoolPinColor(const School(id: '', name: '', curriculumTags: ['ib'])),
      schoolPinColor(const School(id: '', name: '', curriculumTags: ['indian'])),
      schoolPinColor(const School(id: '', name: '', curriculumTags: ['french'])),
      AppColors.greenDeep,
      AppColors.green,
    };
    await MapPins.warm(colors);
    if (!mounted) return;
    final tags = ['american', 'british', 'ib', 'indian', 'french', 'filipino', 'pakistani', ''];
    final off = <String, BitmapDescriptor>{};
    final on = <String, BitmapDescriptor>{};
    for (final tag in tags) {
      final color = schoolPinColor(School(id: '', name: '', curriculumTags: [tag]));
      off[tag] = await MapPins.of(color, selected: false);
      on[tag] = await MapPins.of(color, selected: true);
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

  void _open(School school) {
    AppAnalytics.instance.open(
      section: 'schools',
      targetId: school.id,
      title: school.name,
      category: _curriculum,
    );
    openCard(context, SchoolDetailScreen(school: school));
  }

  Future<void> _onIdle() async {
    final camera = _camera;
    if (camera == null) return;
    if (!mounted) return;
    setState(() {});
    SchoolRepository.instance.refreshAround(
      camera.target.latitude,
      camera.target.longitude,
    );
  }

  Future<void> _locate() async {
    if (_locating) return;
    setState(() => _locating = true);
    await LifeSettings.instance.refreshGps(request: true);
    if (!mounted) return;
    final settings = LifeSettings.instance;
    final here = LatLng(settings.prayerLat, settings.prayerLng);
    _camera = CameraPosition(target: here, zoom: 13.4);
    await _map?.animateCamera(CameraUpdate.newLatLngZoom(here, 13.4));
    await SchoolRepository.instance.refreshAround(here.latitude, here.longitude);
    if (!mounted) return;
    setState(() => _locating = false);
  }

  String _pinKey(School school) {
    return school.curriculumTags.isEmpty
        ? ''
        : school.curriculumTags.first.toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final settings = LifeSettings.instance;
    final repo = SchoolRepository.instance;
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
          query: _search.text,
          curriculum: _curriculum,
          limit: 600,
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
                for (final school in places)
                  if (school.hasPin && school.km <= radiusKm) school,
              ]
            : places.where((school) => school.hasPin).take(40).toList();

        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(title: const Text('International schools')),
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
                        : _aboveTabs(context) + 168,
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
                    for (final school in pins)
                      Marker(
                        markerId: MarkerId(school.id),
                        position: LatLng(school.lat, school.lng),
                        zIndexInt: _picked?.id == school.id ? 9999 : 1,
                        icon: (_picked?.id == school.id
                                ? _pinOn[_pinKey(school)]
                                : _pinOff[_pinKey(school)]) ??
                            BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueAzure,
                            ),
                        onTap: () => setState(() => _picked = school),
                      ),
                  },
                ),
              ),
              if (!_mapView)
                Positioned.fill(
                  child: ColoredBox(
                    color: AppColors.bg,
                    child: places.isEmpty
                        ? Center(
                            child: Text(
                              repo.refreshing
                                  ? 'Loading schools…'
                                  : 'No international schools in this filter yet.',
                              style: const TextStyle(color: AppColors.muted),
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
                              return _SchoolTile(
                                school: places[index],
                                onTap: () => _open(places[index]),
                              );
                            },
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
                            const Duration(milliseconds: 450),
                            () {
                              SchoolRepository.instance.searchRemote(
                                value,
                                origin.latitude,
                                origin.longitude,
                              );
                              SchoolRepository.instance.refreshCatalog(
                                query: value,
                              );
                            },
                          );
                        },
                        decoration: const InputDecoration(
                          hintText: 'Search a school, district, curriculum…',
                          prefixIcon: Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: AppColors.card,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _Chip(
                            label: 'Nearby',
                            selected: _curriculum == 'nearby',
                            onTap: () => setState(() => _curriculum = 'nearby'),
                          ),
                          for (final filter in repo.curriculums)
                            _Chip(
                              label:
                                  '${schoolCurriculumLabel(filter.id)}  ${filter.count}',
                              selected: _curriculum == filter.id,
                              onTap: () =>
                                  setState(() => _curriculum = filter.id),
                            ),
                        ],
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
                    child: _MapCard(school: _picked!),
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
                      onTap: _locate,
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

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: PressableScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.greenDeep : AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.greenDeep : AppColors.stroke,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: selected ? AppColors.onDark : AppColors.ink,
            ),
          ),
        ),
      ),
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

class _SchoolTile extends StatelessWidget {
  const _SchoolTile({required this.school, required this.onTap});

  final School school;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.stroke),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SchoolPhoto(school: school, width: 92, height: 108, radius: 0),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      school.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (school.district.isNotEmpty) school.district,
                        if (school.city.isNotEmpty) school.city,
                        if (school.km > 0)
                          '${school.km < 10 ? school.km.toStringAsFixed(1) : school.km.toStringAsFixed(0)} km',
                      ].join('  ·  '),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final tag in school.curriculumTags.take(3))
                          _MiniChip(schoolCurriculumLabel(tag)),
                        if (schoolGenderLabel(school).isNotEmpty)
                          _MiniChip(schoolGenderLabel(school)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      schoolFeeLabel(school),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.gold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  const _MapCard({required this.school});

  final School school;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: schoolPinColor(school).withValues(alpha: 0.6),
        ),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          SchoolPhoto(school: school, width: 104, height: 102, radius: 0),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    school.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (school.curriculumTags.isNotEmpty)
                        school.curriculumTags
                            .take(2)
                            .map(schoolCurriculumLabel)
                            .join(' · '),
                      schoolFeeLabel(school),
                    ].join('  ·  '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tap for fees and admission',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
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

class _MiniChip extends StatelessWidget {
  const _MiniChip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.chip,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
