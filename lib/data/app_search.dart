import '../features/souq/presentation/souq_controller.dart';
import '../features/souq/presentation/souq_format.dart';
import '../models/activity.dart';
import '../models/models.dart';
import 'content_repository.dart';
import 'emergencies.dart';
import 'ksa_activities.dart';
import 'life_settings.dart';
import 'restaurant_repository.dart';

enum AppSearchSection { category, guide, eat, play, life, souq }

class AppSearchHit {
  const AppSearchHit({
    required this.section,
    required this.title,
    required this.subtitle,
    required this.data,
    this.image,
  });

  final AppSearchSection section;
  final String title;
  final String subtitle;
  final String? image;
  final Object data;
}

class AppSearchGroup {
  const AppSearchGroup({required this.section, required this.hits});

  final AppSearchSection section;
  final List<AppSearchHit> hits;

  String get label => switch (section) {
        AppSearchSection.category => 'Categories',
        AppSearchSection.guide => 'Guides',
        AppSearchSection.eat => 'Eat',
        AppSearchSection.play => 'Play',
        AppSearchSection.life => 'Life',
        AppSearchSection.souq => 'Souq',
      };
}

class AppSearch {
  static List<AppSearchGroup> groups(String raw) {
    final q = raw.trim().toLowerCase();
    if (q.length < 2) return const [];

    final settings = LifeSettings.instance;
    final city = settings.city.name;
    final lat = settings.prayerLat;
    final lng = settings.prayerLng;
    final repo = ContentRepository.instance;

    final out = <AppSearchGroup>[
      if (_categories(repo, q) case final hits when hits.isNotEmpty)
        AppSearchGroup(section: AppSearchSection.category, hits: hits),
      if (_guides(repo, q) case final hits when hits.isNotEmpty)
        AppSearchGroup(section: AppSearchSection.guide, hits: hits),
      if (_eat(lat, lng, city, q) case final hits when hits.isNotEmpty)
        AppSearchGroup(section: AppSearchSection.eat, hits: hits),
      if (_play(lat, lng, city, q) case final hits when hits.isNotEmpty)
        AppSearchGroup(section: AppSearchSection.play, hits: hits),
      if (_life(q) case final hits when hits.isNotEmpty)
        AppSearchGroup(section: AppSearchSection.life, hits: hits),
      if (_souq(q) case final hits when hits.isNotEmpty)
        AppSearchGroup(section: AppSearchSection.souq, hits: hits),
    ];
    return out;
  }

  static List<AppSearchHit> _categories(ContentRepository repo, String q) {
    final hits = <AppSearchHit>[];
    for (final category in repo.categories) {
      final blob = '${category.name} ${category.slug}'.toLowerCase();
      if (!blob.contains(q)) continue;
      hits.add(
        AppSearchHit(
          section: AppSearchSection.category,
          title: category.name,
          subtitle: category.isTopLevel
              ? '${category.totalCount} guides'
              : 'Category',
          data: category,
        ),
      );
      if (hits.length >= 6) break;
    }
    return hits;
  }

  static List<AppSearchHit> _guides(ContentRepository repo, String q) {
    final titleHits = <AppSearchHit>[];
    final other = <AppSearchHit>[];
    for (final post in repo.posts) {
      final title = post.title.toLowerCase();
      final extra =
          '${post.excerpt} ${post.preview} ${post.categories.join(' ')} ${post.tags.join(' ')}'
              .toLowerCase();
      if (title.contains(q)) {
        titleHits.add(_guideHit(post));
        if (titleHits.length >= 10) break;
      } else if (other.length < 6 && extra.contains(q)) {
        other.add(_guideHit(post));
      }
    }
    return [...titleHits, ...other].take(12).toList();
  }

  static AppSearchHit _guideHit(GuidePost post) {
    return AppSearchHit(
      section: AppSearchSection.guide,
      title: post.title,
      subtitle: post.primaryCategory,
      image: post.image,
      data: post,
    );
  }

  static List<AppSearchHit> _eat(
    double lat,
    double lng,
    String city,
    String q,
  ) {
    final places = RestaurantRepository.instance.nearby(
      lat: lat,
      lng: lng,
      query: q,
      limit: 24,
      preferCity: city,
    );
    return [
      for (final place in places)
        AppSearchHit(
          section: AppSearchSection.eat,
          title: place.name,
          subtitle: [
            if (place.city.isNotEmpty) place.city,
            if (place.cuisine.isNotEmpty) place.cuisine,
            if (place.km > 0) '${place.km.toStringAsFixed(1)} km',
          ].join(' · '),
          image: place.image.isEmpty ? null : place.image,
          data: place,
        ),
    ];
  }

  static List<AppSearchHit> _play(
    double lat,
    double lng,
    String city,
    String q,
  ) {
    final places = activitiesNear(
      lat,
      lng,
      query: q,
      limit: 8,
      preferCity: city,
    );
    return [
      for (final place in places)
        AppSearchHit(
          section: AppSearchSection.play,
          title: place.name,
          subtitle: [
            place.city,
            kindMeta(place.kind).title,
            place.fromLabel,
          ].join(' · '),
          image: place.image,
          data: place,
        ),
    ];
  }

  static List<AppSearchHit> _life(String q) {
    final hits = <AppSearchHit>[];
    for (final line in EmergencyData.hotlines) {
      final blob = '${line.label} ${line.number} ${line.detail}'.toLowerCase();
      if (!blob.contains(q) && !q.contains(line.number)) continue;
      hits.add(
        AppSearchHit(
          section: AppSearchSection.life,
          title: '${line.label}  ${line.number}',
          subtitle: line.detail,
          data: line,
        ),
      );
    }
    for (final hospital in EmergencyData.hospitals) {
      if (!hospital.name.toLowerCase().contains(q) && q != 'hospital') {
        continue;
      }
      hits.add(
        AppSearchHit(
          section: AppSearchSection.life,
          title: hospital.name,
          subtitle: 'Hospital · ${hospital.phone}',
          data: hospital,
        ),
      );
      if (hits.length >= 10) break;
    }
    var embassyCount = 0;
    for (final embassy in EmergencyData.embassies) {
      if (!embassy.country.toLowerCase().contains(q) &&
          !embassy.city.toLowerCase().contains(q) &&
          q != 'embassy' &&
          q != 'consulate') {
        continue;
      }
      hits.add(
        AppSearchHit(
          section: AppSearchSection.life,
          title: '${embassy.flagEmoji} ${embassy.country}',
          subtitle: '${embassy.kind} · ${embassy.city} · ${embassy.phone}',
          data: embassy,
        ),
      );
      embassyCount++;
      if (embassyCount >= 6) break;
    }
    return hits.take(10).toList();
  }

  static List<AppSearchHit> _souq(String q) {
    final ctrl = SouqController.instance;
    if (!ctrl.ready) return const [];
    final seen = <String>{};
    return ctrl
        .quickSearch(q, limit: 16)
        .where((ad) => seen.add(ad.id))
        .take(8)
        .map(
          (ad) => AppSearchHit(
            section: AppSearchSection.souq,
            title: ad.title,
            subtitle: '${ad.city} · ${SouqFormat.sar(ad.price)}',
            data: ad,
          ),
        )
        .toList();
  }
}
