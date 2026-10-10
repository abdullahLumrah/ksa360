import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/community.dart';
import 'app_api.dart';

class CommunityRepository extends ChangeNotifier {
  CommunityRepository._();
  static final CommunityRepository instance = CommunityRepository._();

  List<Community> pages = const [];
  List<Community> discoverGroups = const [];
  List<CommunityPost> trending = const [];
  List<CommunityPost> feed = const [];
  List<Community> mine = const [];
  /// Pages the signed-in user created (owner). Empty until they create one.
  List<Community> get owned =>
      mine.where((page) => page.isOwner || page.role == 'owner').toList();
  List<CommunityPost> pendingInbox = const [];
  List<String> topics = const [
    'General',
    'Food',
    'Culture',
    'Expats',
    'Sports',
    'Business',
    'Family',
    'Education',
    'Faith',
    'Neighbourhood',
    'Other',
  ];
  List<String> reportReasons = const [
    'Spam',
    'Harassment',
    'Hate speech',
    'Misinformation',
    'Inappropriate content',
    'Impersonation',
    'Scam / fraud',
    'Other',
  ];
  bool loaded = false;
  bool refreshing = false;
  String? refreshError;
  int total = 0;
  int page = 0;
  bool loadingMore = false;
  bool get hasMore => pages.length < total;
  String? feedCursor;
  bool hasMoreFeed = false;
  bool loadingMoreFeed = false;
  int feedTotal = 0;
  bool feedCaughtUp = false;
  int get pendingCount => pendingInbox.length;

  Future<void> refresh({String q = '', String topic = ''}) async {
    refreshing = true;
    refreshError = null;
    notifyListeners();
    try {
      await Future.wait([
        refreshMeta(),
        refreshFeed(q: q, topic: topic),
        refreshMine(),
        refreshPendingInbox(),
      ]);
      loaded = true;
    } catch (e) {
      refreshError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      refreshing = false;
      notifyListeners();
    }
  }

  Future<void> refreshFeed({String q = '', String topic = ''}) async {
    feedCursor = null;
    hasMoreFeed = false;
    await _fetchFeedPage(q: q, topic: topic, replace: true);
  }

  Future<void> loadMoreFeed({String q = '', String topic = ''}) async {
    if (!hasMoreFeed || loadingMoreFeed || refreshing || feedCursor == null) {
      return;
    }
    loadingMoreFeed = true;
    notifyListeners();
    try {
      await _fetchFeedPage(q: q, topic: topic, replace: false);
    } finally {
      loadingMoreFeed = false;
      notifyListeners();
    }
  }

  Future<void> _fetchFeedPage({
    required String q,
    required String topic,
    required bool replace,
  }) async {
    final res = await AppApi.get(
      AppApi.uri('/communities/feed', {
        if (q.trim().isNotEmpty) 'q': q.trim(),
        if (topic.isNotEmpty) 'topic': topic,
        'limit': '20',
        if (!replace && feedCursor != null && feedCursor!.isNotEmpty)
          'cursor': feedCursor!,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('Could not load posts.');
    }
    final body = jsonDecode(res.body);
    if (body is! Map) {
      if (replace) feed = const [];
      hasMoreFeed = false;
      feedCursor = null;
      return;
    }
    final items = (body['items'] as List? ?? [])
        .whereType<Map>()
        .map((item) => CommunityPost.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    feed = replace ? items : [...feed, ...items];
    feedCursor = (body['nextCursor'] ?? '').toString();
    if (feedCursor != null && feedCursor!.isEmpty) feedCursor = null;
    hasMoreFeed = body['hasMore'] == true && feedCursor != null;
    if (body['total'] is num) {
      feedTotal = (body['total'] as num).toInt();
    }
    if (replace) {
      feedCaughtUp = body['caughtUp'] == true;
    }
    if (items.isNotEmpty) {
      unawaited(_ackFeedSeen(items.map((post) => post.id)));
    }
  }

  Future<void> _ackFeedSeen(Iterable<String> ids) async {
    final list = ids.where((id) => id.isNotEmpty).take(50).toList();
    if (list.isEmpty) return;
    try {
      await AppApi.post(
        AppApi.uri('/communities/feed/seen'),
        body: jsonEncode({'ids': list}),
      );
    } catch (_) {
      // Feed already marks seen server-side; this is a client confirm.
    }
  }

  Future<void> refreshDiscover({String q = '', String topic = ''}) async {
    final res = await AppApi.get(
      AppApi.uri('/communities/discover', {
        if (q.trim().isNotEmpty) 'q': q.trim(),
        if (topic.isNotEmpty) 'topic': topic,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('Could not load communities.');
    }
    final body = jsonDecode(res.body);
    if (body is! Map) {
      discoverGroups = const [];
      trending = const [];
      pages = const [];
      total = 0;
      return;
    }
    trending = (body['trending'] as List? ?? [])
        .whereType<Map>()
        .map((item) => CommunityPost.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    discoverGroups = (body['groups'] as List? ?? [])
        .whereType<Map>()
        .map((item) => Community.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    pages = discoverGroups;
    total = discoverGroups.length;
    page = 0;
  }

  Future<void> refreshMeta() async {
    final res = await AppApi.get(AppApi.uri('/communities/topics'));
    if (res.statusCode != 200) return;
    final body = jsonDecode(res.body);
    if (body is! Map) return;
    final nextTopics = (body['topics'] as List? ?? [])
        .map((item) => item.toString())
        .where((item) => item.isNotEmpty)
        .toList();
    final nextReasons = (body['reportReasons'] as List? ?? [])
        .map((item) => item.toString())
        .where((item) => item.isNotEmpty)
        .toList();
    if (nextTopics.isNotEmpty) topics = nextTopics;
    if (nextReasons.isNotEmpty) reportReasons = nextReasons;
  }

  Future<void> refreshMine() async {
    final res = await AppApi.get(AppApi.uri('/communities/mine'));
    if (res.statusCode != 200) {
      mine = const [];
      return;
    }
    final body = jsonDecode(res.body);
    if (body is! Map) return;
    mine = (body['items'] as List? ?? [])
        .whereType<Map>()
        .map((item) => Community.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> refreshPendingInbox() async {
    final res = await AppApi.get(AppApi.uri('/communities/pending-inbox'));
    if (res.statusCode != 200) {
      pendingInbox = const [];
      return;
    }
    final body = jsonDecode(res.body);
    if (body is! Map) return;
    pendingInbox = (body['items'] as List? ?? [])
        .whereType<Map>()
        .map((item) => CommunityPost.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> loadMore({String q = '', String topic = ''}) async {
    if (!hasMore || loadingMore) return;
    loadingMore = true;
    notifyListeners();
    try {
      final next = page + 1;
      final res = await AppApi.get(
        AppApi.uri('/communities', {
          'page': '$next',
          'limit': '24',
          if (q.trim().isNotEmpty) 'q': q.trim(),
          if (topic.isNotEmpty) 'topic': topic,
        }),
      );
      if (res.statusCode != 200) return;
      final body = jsonDecode(res.body);
      if (body is! Map) return;
      final items = (body['items'] as List? ?? [])
          .whereType<Map>()
          .map((item) => Community.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      pages = [...pages, ...items];
      page = next;
      total = (body['total'] as num?)?.toInt() ?? total;
    } finally {
      loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> _loadPage({String q = '', String topic = ''}) async {
    final res = await AppApi.get(
      AppApi.uri('/communities', {
        'page': '0',
        'limit': '24',
        if (q.trim().isNotEmpty) 'q': q.trim(),
        if (topic.isNotEmpty) 'topic': topic,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('Could not load communities.');
    }
    final body = jsonDecode(res.body);
    if (body is! Map) {
      pages = const [];
      total = 0;
      page = 0;
      return;
    }
    pages = (body['items'] as List? ?? [])
        .whereType<Map>()
        .map((item) => Community.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    total = (body['total'] as num?)?.toInt() ?? pages.length;
    page = 0;
  }

  Future<Community> detail(String id) async {
    final res = await AppApi.get(AppApi.uri('/communities/$id'));
    if (res.statusCode != 200) throw Exception('Could not open this page.');
    final body = jsonDecode(res.body);
    if (body is! Map) throw Exception('Could not open this page.');
    return Community.fromJson(Map<String, dynamic>.from(body));
  }

  Future<Community> create({
    required String name,
    required String description,
    required String topic,
    String city = '',
  }) async {
    final trimmed = name.trim();
    if (trimmed.length < 3) {
      throw Exception('Give the page a clear name (at least 3 characters).');
    }
    final res = await AppApi.post(
      AppApi.uri('/communities'),
      body: jsonEncode({
        'name': trimmed,
        'description': description,
        'topic': topic,
        'city': city,
      }),
    );
    if (res.statusCode == 401) {
      throw Exception('Sign in to create a page.');
    }
    if (res.statusCode != 201) {
      dynamic body;
      try {
        body = jsonDecode(res.body);
      } catch (_) {
        body = null;
      }
      throw Exception(
        body is Map
            ? (body['error'] ?? 'Could not create page.')
            : 'Could not create page (${res.statusCode}).',
      );
    }
    final body = jsonDecode(res.body);
    final created = Community.fromJson(Map<String, dynamic>.from(body as Map));
    pages = [created, ...pages.where((item) => item.id != created.id)];
    mine = [created, ...mine.where((item) => item.id != created.id)];
    total += 1;
    notifyListeners();
    return created;
  }

  void replaceFeedPost(CommunityPost next) {
    feed = [
      for (final item in feed)
        if (item.id == next.id)
          next.copyWith(joined: item.joined, isOwner: item.isOwner)
        else
          item,
    ];
    notifyListeners();
  }

  void markFeedJoined(String communityId) {
    feed = [
      for (final item in feed)
        if (item.communityId == communityId) item.copyWith(joined: true) else item,
    ];
    notifyListeners();
  }

  Future<Community> join(String id) async {
    final res = await AppApi.post(AppApi.uri('/communities/$id/join'));
    if (res.statusCode != 200) throw Exception('Could not join this page.');
    final body = jsonDecode(res.body);
    final next = Community.fromJson(Map<String, dynamic>.from(body as Map));
    _replacePage(next);
    await refreshMine();
    notifyListeners();
    return next;
  }

  Future<Community> leave(String id) async {
    final res = await AppApi.delete(AppApi.uri('/communities/$id/leave'));
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(
        body is Map ? (body['error'] ?? 'Could not leave.') : 'Could not leave.',
      );
    }
    final body = jsonDecode(res.body);
    final next = Community.fromJson(Map<String, dynamic>.from(body as Map));
    _replacePage(next);
    await refreshMine();
    notifyListeners();
    return next;
  }

  Future<List<CommunityPost>> posts(String communityId, {String status = 'approved'}) async {
    final res = await AppApi.get(
      AppApi.uri('/communities/$communityId/posts', {'status': status, 'limit': '40'}),
    );
    if (res.statusCode != 200) throw Exception('Could not load posts.');
    final body = jsonDecode(res.body);
    if (body is! Map) return const [];
    return (body['items'] as List? ?? [])
        .whereType<Map>()
        .map((item) => CommunityPost.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<CommunityPost>> pendingFor(String communityId) async {
    final res = await AppApi.get(AppApi.uri('/communities/$communityId/pending'));
    if (res.statusCode != 200) throw Exception('Could not load pending posts.');
    final body = jsonDecode(res.body);
    if (body is! Map) return const [];
    return (body['items'] as List? ?? [])
        .whereType<Map>()
        .map((item) => CommunityPost.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<CommunityPost> createPost(
    String communityId, {
    required String body,
    String? imagePath,
  }) async {
    final http.Response res;
    final file = imagePath != null && imagePath.isNotEmpty ? File(imagePath) : null;
    if (file != null && file.existsSync()) {
      res = await AppApi.postMultipart(
        AppApi.uri('/communities/$communityId/posts'),
        fields: {'body': body},
        files: [await http.MultipartFile.fromPath('image', file.path)],
      );
    } else {
      res = await AppApi.post(
        AppApi.uri('/communities/$communityId/posts'),
        body: jsonEncode({'body': body}),
      );
    }
    if (res.statusCode != 201) {
      final decoded = jsonDecode(res.body);
      throw Exception(
        decoded is Map ? (decoded['error'] ?? 'Could not post.') : 'Could not post.',
      );
    }
    final decoded = jsonDecode(res.body);
    final post = CommunityPost.fromJson(Map<String, dynamic>.from(decoded as Map));
    await refreshPendingInbox();
    notifyListeners();
    return post;
  }

  Future<CommunityPost> approvePost(String communityId, String postId) async {
    final res = await AppApi.post(
      AppApi.uri('/communities/$communityId/posts/$postId/approve'),
    );
    if (res.statusCode != 200) throw Exception('Could not approve this post.');
    final body = jsonDecode(res.body);
    final post = CommunityPost.fromJson(Map<String, dynamic>.from(body as Map));
    pendingInbox = pendingInbox.where((item) => item.id != postId).toList();
    notifyListeners();
    return post;
  }

  Future<CommunityPost> declinePost(String communityId, String postId) async {
    final res = await AppApi.post(
      AppApi.uri('/communities/$communityId/posts/$postId/decline'),
    );
    if (res.statusCode != 200) throw Exception('Could not decline this post.');
    final body = jsonDecode(res.body);
    final post = CommunityPost.fromJson(Map<String, dynamic>.from(body as Map));
    pendingInbox = pendingInbox.where((item) => item.id != postId).toList();
    notifyListeners();
    return post;
  }

  Future<CommunityPost> postDetail(String postId) async {
    final res = await AppApi.get(AppApi.uri('/communities/posts/$postId'));
    if (res.statusCode != 200) throw Exception('Could not open this post.');
    final body = jsonDecode(res.body);
    return CommunityPost.fromJson(Map<String, dynamic>.from(body as Map));
  }

  Future<CommunityPost> togglePostLike(String postId) async {
    final res = await AppApi.post(AppApi.uri('/communities/posts/$postId/like'));
    if (res.statusCode != 200) throw Exception('Could not update like.');
    final body = jsonDecode(res.body);
    return CommunityPost.fromJson(Map<String, dynamic>.from(body as Map));
  }

  Future<List<CommunityComment>> comments(String postId) async {
    final res = await AppApi.get(AppApi.uri('/communities/posts/$postId/comments'));
    if (res.statusCode != 200) throw Exception('Could not load comments.');
    final body = jsonDecode(res.body);
    if (body is! Map) return const [];
    return (body['items'] as List? ?? [])
        .whereType<Map>()
        .map((item) => CommunityComment.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<CommunityComment> addComment(String postId, String body) async {
    final res = await AppApi.post(
      AppApi.uri('/communities/posts/$postId/comments'),
      body: jsonEncode({'body': body}),
    );
    if (res.statusCode != 201) throw Exception('Could not comment.');
    final decoded = jsonDecode(res.body);
    return CommunityComment.fromJson(Map<String, dynamic>.from(decoded as Map));
  }

  Future<CommunityComment> reply(String commentId, String body) async {
    final res = await AppApi.post(
      AppApi.uri('/communities/comments/$commentId/replies'),
      body: jsonEncode({'body': body}),
    );
    if (res.statusCode != 201) throw Exception('Could not reply.');
    final decoded = jsonDecode(res.body);
    return CommunityComment.fromJson(Map<String, dynamic>.from(decoded as Map));
  }

  Future<CommunityComment> toggleCommentLike(String commentId) async {
    final res = await AppApi.post(AppApi.uri('/communities/comments/$commentId/like'));
    if (res.statusCode != 200) throw Exception('Could not update like.');
    final body = jsonDecode(res.body);
    return CommunityComment.fromJson(Map<String, dynamic>.from(body as Map));
  }

  Future<void> report({
    required String targetType,
    required String targetId,
    required String reason,
    String details = '',
    String reportedUserId = '',
    String communityId = '',
  }) async {
    final res = await AppApi.post(
      AppApi.uri('/communities/reports'),
      body: jsonEncode({
        'targetType': targetType,
        'targetId': targetId,
        'reason': reason,
        'details': details,
        if (reportedUserId.isNotEmpty) 'reportedUserId': reportedUserId,
        if (communityId.isNotEmpty) 'communityId': communityId,
      }),
    );
    if (res.statusCode != 201) {
      final body = jsonDecode(res.body);
      throw Exception(
        body is Map ? (body['error'] ?? 'Could not send report.') : 'Could not send report.',
      );
    }
  }

  void _replacePage(Community next) {
    pages = pages.map((item) => item.id == next.id ? next : item).toList();
    mine = mine.map((item) => item.id == next.id ? next : item).toList();
  }
}
