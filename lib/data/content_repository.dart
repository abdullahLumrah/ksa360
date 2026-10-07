import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import 'app_api.dart';
import 'app_api_config.dart';

class ContentRepository extends ChangeNotifier {
  ContentRepository._();
  static final ContentRepository instance = ContentRepository._();

  static const _savedKey = 'saved_post_ids';
  static const _homeOrder = [
    'jawazat-and-moi',
    'driving-in-saudi-arabia',
    'saudi-laws',
    'career',
    'general-information',
    'important',
    'latest-news',
    'social-issues',
    'online-shopping',
  ];

  List<GuideCategory> categories = const [];
  List<GuidePost> posts = const [];
  Map<String, GuideCategory> categoryById = const {};
  Map<String, GuideCategory> categoryByName = const {};
  Map<String, GuidePost> postById = const {};
  final Map<String, List<GuidePost>> _postsByCategoryName = {};
  final Map<String, String> _bodies = {};
  Set<String> savedIds = {};
  bool loaded = false;
  String? loadError;

  Future<void> load() async {
    if (loaded) return;

    final prefs = await SharedPreferences.getInstance();
    savedIds = (prefs.getStringList(_savedKey) ?? const []).toSet();

    try {
      final uri = Uri.parse('${AppApiConfig.baseUrl}/guides');
      final res = await AppApi.get(uri, timeout: const Duration(seconds: 25));
      if (res.statusCode != 200) {
        throw Exception('Guides API ${res.statusCode}');
      }
      final map = jsonDecode(res.body) as Map<String, dynamic>;
      categories = [
        for (final item in map['categories'] as List<dynamic>? ?? const [])
          GuideCategory.fromJson(item as Map<String, dynamic>),
      ];
      posts = [
        for (final item in map['posts'] as List<dynamic>? ?? const [])
          GuidePost.fromJson(_withMedia(item as Map<String, dynamic>)),
      ]..sort((a, b) => b.date.compareTo(a.date));
      loadError = null;
    } catch (e) {
      categories = const [];
      posts = const [];
      loadError = e.toString();
    }

    _index();
    loaded = true;
    notifyListeners();
  }

  void _index() {
    categoryById = {for (final c in categories) c.id: c};
    categoryByName = {for (final c in categories) c.name: c};
    postById = {for (final p in posts) p.id: p};
    _postsByCategoryName.clear();
    for (final post in posts) {
      if (post.body.trim().isNotEmpty) _bodies[post.id] = post.body;
      for (final name in post.categories) {
        _postsByCategoryName.putIfAbsent(name, () => []).add(post);
      }
    }
  }

  List<GuideCategory> get topCategories {
    final tops = categories
        .where((c) => c.isTopLevel && c.totalCount > 0)
        .toList();
    tops.sort((a, b) {
      final ai = _homeOrder.indexOf(a.slug);
      final bi = _homeOrder.indexOf(b.slug);
      final av = ai == -1 ? 99 : ai;
      final bv = bi == -1 ? 99 : bi;
      if (av != bv) return av.compareTo(bv);
      return b.totalCount.compareTo(a.totalCount);
    });
    return tops;
  }

  List<GuideCategory> childrenOf(GuideCategory category) {
    return category.childIds
        .map((id) => categoryById[id])
        .whereType<GuideCategory>()
        .where((c) => c.totalCount > 0)
        .toList()
      ..sort((a, b) => b.totalCount.compareTo(a.totalCount));
  }

  List<GuidePost> postsFor(GuideCategory category, {int? limit}) {
    final names = _descendantNames(category);
    final seen = <String>{};
    final result = <GuidePost>[];
    for (final name in names) {
      for (final post in _postsByCategoryName[name] ?? const <GuidePost>[]) {
        if (seen.add(post.id)) result.add(post);
      }
    }
    result.sort((a, b) => b.date.compareTo(a.date));
    if (limit != null && result.length > limit) {
      return result.sublist(0, limit);
    }
    return result;
  }

  Set<String> _descendantNames(GuideCategory category) {
    final names = <String>{category.name};
    for (final id in category.childIds) {
      final child = categoryById[id];
      if (child != null) names.addAll(_descendantNames(child));
    }
    return names;
  }

  String bodyFor(String id) => _bodies[id] ?? postById[id]?.preview ?? '';

  Future<String> ensureBody(String id) async {
    final cached = _bodies[id];
    if (cached != null && cached.trim().isNotEmpty) return cached;
    try {
      final uri = Uri.parse('${AppApiConfig.baseUrl}/guides/posts/$id');
      final res = await AppApi.get(uri);
      if (res.statusCode == 200) {
        final map = _withMedia(jsonDecode(res.body) as Map<String, dynamic>);
        final body = (map['body'] as String?)?.trim() ?? '';
        if (body.isNotEmpty) {
          _bodies[id] = body;
          notifyListeners();
          return body;
        }
      }
    } catch (_) {}
    return bodyFor(id);
  }

  List<GuidePost> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];

    final titleHits = posts
        .where((p) => p.title.toLowerCase().contains(q))
        .toList();
    if (titleHits.isNotEmpty) return titleHits;

    return posts.where((p) {
      if (p.preview.toLowerCase().contains(q)) return true;
      if (p.excerpt.toLowerCase().contains(q)) return true;
      if (p.categories.any((c) => c.toLowerCase().contains(q))) return true;
      if (p.tags.any((t) => t.toLowerCase().contains(q))) return true;
      final body = _bodies[p.id];
      return body != null && body.toLowerCase().contains(q);
    }).toList();
  }

  List<GuidePost> relatedTo(GuidePost post, {int limit = 8}) {
    final related = <GuidePost>[];
    final seen = {post.id};
    for (final name in post.categories) {
      for (final other in _postsByCategoryName[name] ?? const <GuidePost>[]) {
        if (seen.add(other.id)) related.add(other);
      }
    }
    related.sort((a, b) => b.date.compareTo(a.date));
    return related.take(limit).toList();
  }

  List<GuidePost> get savedPosts {
    return savedIds.map((id) => postById[id]).whereType<GuidePost>().toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  bool isSaved(String id) => savedIds.contains(id);

  static const _familyNeedles = [
    'family',
    'visit visa',
    'newly born',
    'education',
    'school',
    'marriage',
    'married',
    'health',
    'housing',
    'domestic',
    'hajj',
    'umrah',
    'places to visit',
  ];

  static const _bachelorNeedles = [
    'job',
    'work visa',
    'work environment',
    'transfer',
    'huroob',
    'labor',
    'iqama for newcomers',
    'traffic',
    'bank',
    'mobile',
    'career',
  ];

  List<GuidePost> guidesForLifestyle(String mode, {int limit = 12}) {
    final needles = mode == 'bachelor' ? _bachelorNeedles : _familyNeedles;
    final hits = posts.where((p) {
      final hay = '${p.title} ${p.categories.join(' ')} ${p.preview}'.toLowerCase();
      return needles.any((n) => hay.contains(n));
    }).toList();
    if (hits.length > limit) return hits.sublist(0, limit);
    return hits;
  }

  static Map<String, dynamic> _withMedia(Map<String, dynamic> json) {
    final image = '${json['image'] ?? ''}'.trim();
    if (image.startsWith('/uploads/')) {
      return {...json, 'image': '${AppApiConfig.baseUrl}$image'};
    }
    return json;
  }

  Future<GuidePost> submitPost({
    required String title,
    required String description,
    String? imagePath,
  }) async {
    final files = <http.MultipartFile>[];
    if (imagePath != null && imagePath.isNotEmpty) {
      final file = File(imagePath);
      if (file.existsSync()) {
        files.add(await http.MultipartFile.fromPath('image', file.path));
      }
    }
    final res = await AppApi.postMultipart(
      AppApi.uri('/guides/posts'),
      fields: {
        'title': title.trim(),
        'description': description.trim(),
      },
      files: files,
    );
    if (res.statusCode >= 400) {
      var message = 'Could not send this guide';
      try {
        final map = jsonDecode(res.body);
        if (map is Map && map['error'] != null) message = '${map['error']}';
      } catch (_) {}
      throw Exception(message);
    }
    return GuidePost.fromJson(_withMedia(jsonDecode(res.body) as Map<String, dynamic>));
  }

  Future<void> toggleSaved(String id) async {
    if (savedIds.contains(id)) {
      savedIds.remove(id);
    } else {
      savedIds.add(id);
    }
    savedIds = {...savedIds};
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_savedKey, savedIds.toList());
  }
}
