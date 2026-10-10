import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../data/activity_repository.dart';
import '../data/app_analytics.dart';
import '../data/healthcare_repository.dart';
import '../data/ksa_activities.dart';
import '../data/life_settings.dart';
import '../data/restaurant_menus.dart';
import '../data/restaurant_repository.dart';
import '../data/school_repository.dart';
import '../data/shop_repository.dart';
import '../models/activity.dart';
import '../models/health_facility.dart';
import '../models/restaurant.dart';
import '../models/school.dart';
import '../models/shop.dart';
import '../theme/app_theme.dart';
import '../widgets/activity_photo.dart';
import '../widgets/motion.dart';
import '../widgets/school_photo.dart';
import 'activity_detail_screen.dart';
import 'healthcare_detail_screen.dart';
import 'restaurant_detail_screen.dart';
import 'school_detail_screen.dart';
import 'shop_category_screen.dart';

InputDecoration _paneSearch(String hint) {
  return InputDecoration(
    hintText: hint,
    isDense: true,
    filled: true,
    fillColor: AppColors.card,
    prefixIcon: const Icon(Icons.search_rounded, size: 18),
    prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 32),
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
  );
}

class _PaneChrome extends StatelessWidget {
  const _PaneChrome({
    required this.search,
    required this.hint,
    required this.onSearch,
    required this.filters,
    this.banner,
    required this.child,
  });

  final TextEditingController search;
  final String hint;
  final ValueChanged<String> onSearch;
  final Widget filters;
  final Widget? banner;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              12,
              MediaQuery.paddingOf(context).top + 8,
              12,
              0,
            ),
            child: TextField(
              controller: search,
              onChanged: onSearch,
              style: const TextStyle(fontSize: 13, height: 1.2),
              decoration: _paneSearch(hint),
            ),
          ),
          const SizedBox(height: 8),
          filters,
          if (banner != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: banner!,
            ),
          ],
          const SizedBox(height: 8),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.greenDeep : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.greenDeep : AppColors.stroke,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 11,
            color: selected ? AppColors.onDark : AppColors.ink,
          ),
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: children.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, index) => children[index],
      ),
    );
  }
}

class DailyKsaPane extends StatelessWidget {
  const DailyKsaPane({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ShopRepository.instance,
      builder: (context, _) {
        final repo = ShopRepository.instance;
        return Scaffold(
          backgroundColor: AppColors.bg,
          body: repo.categories.isEmpty
              ? Center(
                  child: Text(
                    repo.refreshing ? 'Loading shops…' : 'No shops yet.',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsetsDirectional.fromSTEB(
                    12,
                    MediaQuery.paddingOf(context).top + 10,
                    12,
                    96,
                  ),
                  itemCount: repo.categories.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final category = repo.categories[index];
                    return _DailyRow(
                      category: category,
                      brands: repo.previewMerchants(category.id),
                      onTap: () => openCard(
                        context,
                        ShopCategoryScreen(category: category),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

class _DailyRow extends StatelessWidget {
  const _DailyRow({
    required this.category,
    required this.brands,
    required this.onTap,
  });

  final ShopCategory category;
  final List<ShopMerchant> brands;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hero = brands.isNotEmpty ? brands.first : null;
    final extras = brands.skip(1).take(3).toList();
    final thumb = hero?.icon.isNotEmpty == true
        ? hero!.icon
        : (hero?.image.isNotEmpty == true
            ? hero!.image
            : (category.icon.isNotEmpty ? category.icon : category.image));
    return PressableScale(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Row(
          children: [
            _MiniThumb(url: thumb, size: 44),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    [
                      '${category.merchantCount} shops',
                      if (category.couponCount > 0)
                        '${category.couponCount} coupons',
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                  if (extras.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    _DailyBrandCascade(
                      urls: [
                        for (final brand in extras)
                          brand.icon.isNotEmpty ? brand.icon : brand.image,
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyBrandCascade extends StatelessWidget {
  const _DailyBrandCascade({required this.urls});

  final List<String> urls;

  static const _sizes = <double>[22, 17, 13];

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) return const SizedBox.shrink();
    final count = urls.length.clamp(0, _sizes.length);
    final sizes = _sizes.take(count).toList();
    final maxH = sizes.reduce((a, b) => a > b ? a : b);
    final steps = <double>[];
    var x = 0.0;
    for (var i = 0; i < count; i++) {
      steps.add(x);
      if (i < count - 1) x += sizes[i] * 0.56;
    }
    return SizedBox(
      width: steps.last + sizes.last + 2,
      height: maxH + 2,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = count - 1; i >= 0; i--)
            Positioned(
              left: steps[i],
              bottom: (maxH - sizes[i]) / 2,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(sizes[i] * 0.28),
                  border: Border.all(color: AppColors.card, width: 1.2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x181C1915),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: _MiniThumb(url: urls[i], size: sizes[i]),
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniThumb extends StatelessWidget {
  const _MiniThumb({required this.url, required this.size});

  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size > 28 ? 12 : size * 0.28),
      child: url.isEmpty
          ? SizedBox(
              width: size,
              height: size,
              child: ColoredBox(
                color: AppColors.bg,
                child: Icon(
                  Icons.storefront_rounded,
                  color: AppColors.gold,
                  size: size * 0.42,
                ),
              ),
            )
          : CachedNetworkImage(
              imageUrl: url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              memCacheWidth: (size * 3).round(),
              errorWidget: (_, __, ___) => SizedBox(
                width: size,
                height: size,
                child: ColoredBox(
                  color: AppColors.bg,
                  child: Icon(
                    Icons.storefront_rounded,
                    color: AppColors.gold,
                    size: size * 0.42,
                  ),
                ),
              ),
            ),
    );
  }
}

class ClinicsPane extends StatefulWidget {
  const ClinicsPane({super.key});

  @override
  State<ClinicsPane> createState() => _ClinicsPaneState();
}

class _ClinicsPaneState extends State<ClinicsPane> {
  final _search = TextEditingController();
  var _kind = 'clinic';

  static const _filters = [
    ('nearby', 'Nearby'),
    ('clinic', 'Clinics'),
    ('hospital', 'Hospitals'),
    ('health_centre', 'Centres'),
    ('pharmacy', 'Pharmacy'),
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        LifeSettings.instance,
        HealthcareRepository.instance,
      ]),
      builder: (context, _) {
        final settings = LifeSettings.instance;
        final places = _englishFirst(
          HealthcareRepository.instance.nearby(
            lat: settings.prayerLat,
            lng: settings.prayerLng,
            kind: _kind,
            query: _search.text,
            limit: 40,
          ),
        );
        return _PaneChrome(
          search: _search,
          hint: 'Clinic or hospital',
          onSearch: (_) => setState(() {}),
          filters: _FilterRow(
            children: [
              for (final item in _filters)
                _FilterChip(
                  label: item.$2,
                  selected: _kind == item.$1,
                  onTap: () => setState(() => _kind = item.$1),
                ),
            ],
          ),
          banner: const _ClinicNote(),
          child: places.isEmpty
              ? const Center(
                  child: Text(
                    'No clinics in this filter yet.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 96),
                  itemCount: places.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final place = places[index];
                    return _ClinicCard(
                      place: place,
                      onTap: () {
                        AppAnalytics.instance.open(
                          section: 'healthcare',
                          targetId: place.id,
                          title: place.name,
                          category: _kind,
                        );
                        openCard(context, HealthcareDetailScreen(place: place));
                      },
                    );
                  },
                ),
        );
      },
    );
  }
}

bool _hasLatin(String value) {
  for (final code in value.codeUnits) {
    final upper = code >= 65 && code <= 90;
    final lower = code >= 97 && code <= 122;
    if (upper || lower) return true;
  }
  return false;
}

List<HealthFacility> _englishFirst(List<HealthFacility> places) {
  final next = [...places];
  next.sort((a, b) {
    final ae = _hasLatin(a.name) ? 0 : 1;
    final be = _hasLatin(b.name) ? 0 : 1;
    if (ae != be) return ae.compareTo(be);
    return a.km.compareTo(b.km);
  });
  return next;
}

String _clinicName(String name) {
  if (name.contains('|')) {
    final latin = name
        .split('|')
        .map((part) => part.trim())
        .where(_hasLatin)
        .toList();
    if (latin.isNotEmpty) return latin.first;
  }
  return name;
}

class _ClinicNote extends StatelessWidget {
  const _ClinicNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: const Color(0x14B33A2B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.red.withValues(alpha: 0.25)),
      ),
      child: const Text(
        'Emergency? Use 997 or open Emergency in the list.',
        style: TextStyle(
          color: AppColors.redDark,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          height: 1.25,
        ),
      ),
    );
  }
}

class _ClinicCard extends StatelessWidget {
  const _ClinicCard({required this.place, required this.onTap});

  final HealthFacility place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _clinicName(place.name),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      height: 1.2,
                    ),
                  ),
                ),
                if (place.emergency)
                  const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Text(
                      'ER',
                      style: TextStyle(
                        color: AppColors.red,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              [
                healthKindTitle(place.kind),
                if (place.km > 0)
                  '${place.km < 10 ? place.km.toStringAsFixed(1) : place.km.toStringAsFixed(0)} km',
              ].join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
            if (place.city.isNotEmpty || place.phone.isNotEmpty)
              Text(
                [if (place.city.isNotEmpty) place.city, if (place.phone.isNotEmpty) place.phone]
                    .join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
          ],
        ),
      ),
    );
  }
}

class StudyPane extends StatefulWidget {
  const StudyPane({super.key});

  @override
  State<StudyPane> createState() => _StudyPaneState();
}

class _StudyPaneState extends State<StudyPane> {
  final _search = TextEditingController();
  var _curriculum = 'nearby';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        LifeSettings.instance,
        SchoolRepository.instance,
      ]),
      builder: (context, _) {
        final settings = LifeSettings.instance;
        final repo = SchoolRepository.instance;
        final places = repo.nearby(
          lat: settings.prayerLat,
          lng: settings.prayerLng,
          query: _search.text,
          curriculum: _curriculum,
          limit: 40,
        );
        return _PaneChrome(
          search: _search,
          hint: 'School or curriculum',
          onSearch: (_) => setState(() {}),
          filters: _FilterRow(
            children: [
              _FilterChip(
                label: 'Nearby',
                selected: _curriculum == 'nearby',
                onTap: () => setState(() => _curriculum = 'nearby'),
              ),
              for (final filter in repo.curriculums.take(8))
                _FilterChip(
                  label: schoolCurriculumLabel(filter.id),
                  selected: _curriculum == filter.id,
                  onTap: () => setState(() => _curriculum = filter.id),
                ),
            ],
          ),
          child: places.isEmpty
              ? const Center(
                  child: Text(
                    'No schools in this filter yet.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 96),
                  itemCount: places.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final school = places[index];
                    return _StudyCard(
                      school: school,
                      onTap: () {
                        AppAnalytics.instance.open(
                          section: 'schools',
                          targetId: school.id,
                          title: school.name,
                          category: 'nearby',
                        );
                        openCard(context, SchoolDetailScreen(school: school));
                      },
                    );
                  },
                ),
        );
      },
    );
  }
}

class _StudyCard extends StatelessWidget {
  const _StudyCard({required this.school, required this.onTap});

  final School school;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.stroke),
        ),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: 88,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SchoolPhoto(school: school, width: 80, height: 88, radius: 0),
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      school.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (school.city.isNotEmpty) school.city,
                        if (school.km > 0)
                          '${school.km < 10 ? school.km.toStringAsFixed(1) : school.km.toStringAsFixed(0)} km',
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                    Text(
                      schoolFeeLabel(school),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
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

class EatPane extends StatefulWidget {
  const EatPane({super.key});

  @override
  State<EatPane> createState() => _EatPaneState();
}

class _EatPaneState extends State<EatPane> {
  final _search = TextEditingController();
  var _kind = 'nearby';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        LifeSettings.instance,
        RestaurantRepository.instance,
      ]),
      builder: (context, _) {
        final settings = LifeSettings.instance;
        final places = RestaurantRepository.instance.nearby(
          lat: settings.prayerLat,
          lng: settings.prayerLng,
          kind: _kind,
          query: _search.text,
          preferCity: settings.city.name,
          limit: 40,
        );
        return _PaneChrome(
          search: _search,
          hint: 'Restaurant or cuisine',
          onSearch: (_) => setState(() {}),
          filters: _FilterRow(
            children: [
              for (final kind in cuisineKinds)
                _FilterChip(
                  label: kind.title,
                  selected: _kind == kind.id,
                  onTap: () => setState(() => _kind = kind.id),
                ),
            ],
          ),
          child: places.isEmpty
              ? const Center(
                  child: Text(
                    'No restaurants in this filter yet.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 96),
                  itemCount: places.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final place = places[index];
                    return _EatCard(
                      place: place,
                      onTap: () {
                        AppAnalytics.instance.open(
                          section: 'eat',
                          targetId: place.id,
                          title: place.name,
                          category: _kind,
                        );
                        openCard(context, RestaurantDetailScreen(place: place));
                      },
                    );
                  },
                ),
        );
      },
    );
  }
}

class _EatCard extends StatelessWidget {
  const _EatCard({required this.place, required this.onTap});

  final Restaurant place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final photo = foodPhotoFor(place);
    return PressableScale(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.stroke),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            CachedNetworkImage(
              imageUrl: photo,
              httpHeaders: foodPhotoHeaders(photo),
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => ColoredBox(
                color: cuisineColor(place.kind).withValues(alpha: 0.2),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: Icon(Icons.restaurant_rounded, color: cuisineColor(place.kind)),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        cuisineTitle(place.kind),
                        if (place.km > 0)
                          '${place.km < 10 ? place.km.toStringAsFixed(1) : place.km.toStringAsFixed(0)} km',
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                    if (place.city.isNotEmpty)
                      Text(
                        place.city,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.muted, fontSize: 11),
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

class ActivitiesPane extends StatefulWidget {
  const ActivitiesPane({super.key});

  @override
  State<ActivitiesPane> createState() => _ActivitiesPaneState();
}

class _ActivitiesPaneState extends State<ActivitiesPane> {
  final _search = TextEditingController();
  var _kind = 'all';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        LifeSettings.instance,
        ActivityRepository.instance,
      ]),
      builder: (context, _) {
        final settings = LifeSettings.instance;
        final places = activitiesNear(
          settings.prayerLat,
          settings.prayerLng,
          kind: _kind,
          query: _search.text,
          preferCity: settings.city.name,
          limit: 40,
        );
        return _PaneChrome(
          search: _search,
          hint: 'Movies, dunes, karting…',
          onSearch: (_) => setState(() {}),
          filters: _FilterRow(
            children: [
              _FilterChip(
                label: 'All',
                selected: _kind == 'all',
                onTap: () => setState(() => _kind = 'all'),
              ),
              for (final kind in activityKinds)
                _FilterChip(
                  label: kind.title,
                  selected: _kind == kind.id,
                  onTap: () => setState(() => _kind = kind.id),
                ),
            ],
          ),
          child: places.isEmpty
              ? const Center(
                  child: Text(
                    'No activities in this filter yet.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 96),
                  itemCount: places.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = places[index];
                    return _ActivityCard(
                      item: item,
                      onTap: () {
                        AppAnalytics.instance.open(
                          section: 'play',
                          targetId: item.id,
                          title: item.name,
                          category: item.kind,
                        );
                        openCard(context, ActivityDetailScreen(activity: item));
                      },
                    );
                  },
                ),
        );
      },
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.item, required this.onTap});

  final KsaActivity item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.stroke),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: ActivityPhoto(url: item.image, kind: item.kind),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        kindMeta(item.kind).title,
                        if (item.km > 0)
                          '${item.km < 10 ? item.km.toStringAsFixed(1) : item.km.toStringAsFixed(0)} km',
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                    if (item.city.isNotEmpty)
                      Text(
                        item.city,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.muted, fontSize: 11),
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
