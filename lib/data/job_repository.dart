import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/job.dart';
import 'app_api.dart';

class JobListPage {
  const JobListPage({
    required this.items,
    required this.total,
    required this.page,
  });

  final List<Job> items;
  final int total;
  final int page;
}

class JobRepository extends ChangeNotifier {
  JobRepository._();
  static final JobRepository instance = JobRepository._();

  List<Job> jobs = const [];
  List<JobFilter> categories = const [];
  List<String> postCategories = const [];
  List<JobFilter> cities = const [];
  List<JobFilter> employmentTypes = const [];
  List<JobFilter> workModes = const [];
  bool loaded = false;
  bool refreshing = false;
  String? refreshError;
  int total = 0;
  int page = 0;
  bool loadingMore = false;
  bool get hasMore => jobs.length < total;

  Future<void> load() async {
    if (loaded) return;
    await refresh();
    loaded = true;
  }

  Future<void> refresh({
    String q = '',
    String category = '',
    String city = '',
    String employmentType = '',
    String workMode = '',
  }) async {
    refreshing = true;
    refreshError = null;
    notifyListeners();
    try {
      await Future.wait([
        refreshFilters(),
        _loadPage(
          q: q,
          category: category,
          city: city,
          employmentType: employmentType,
          workMode: workMode,
        ),
      ]);
    } catch (e) {
      refreshError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      refreshing = false;
      notifyListeners();
    }
  }

  Future<void> refreshFilters() async {
    final res = await AppApi.get(AppApi.uri('/jobs/filters'));
    if (res.statusCode != 200) {
      throw Exception('Could not load job filters.');
    }
    final body = jsonDecode(res.body);
    if (body is! Map) return;
    categories = _filters(body['categories']);
    cities = _filters(body['cities']);
    employmentTypes = _filters(body['employmentTypes']);
    workModes = _filters(body['workModes']);
    postCategories = (body['postCategories'] as List? ?? [])
        .map((item) => item.toString())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  Future<JobListPage> list({
    String q = '',
    String category = '',
    String city = '',
    String employmentType = '',
    String workMode = '',
    int page = 0,
    int limit = 40,
  }) async {
    final query = <String, String>{
      'page': '$page',
      'limit': '$limit',
      if (q.trim().isNotEmpty) 'q': q.trim(),
      if (category.isNotEmpty) 'category': category,
      if (city.isNotEmpty) 'city': city,
      if (employmentType.isNotEmpty) 'employmentType': employmentType,
      if (workMode.isNotEmpty) 'workMode': workMode,
    };
    final res = await AppApi.get(AppApi.uri('/jobs', query));
    if (res.statusCode != 200) {
      throw Exception('Could not load jobs.');
    }
    final body = jsonDecode(res.body);
    if (body is! Map) return const JobListPage(items: [], total: 0, page: 0);
    final items = (body['items'] as List? ?? [])
        .whereType<Map>()
        .map((item) => Job.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    return JobListPage(
      items: items,
      total: (body['total'] as num?)?.toInt() ?? items.length,
      page: (body['page'] as num?)?.toInt() ?? page,
    );
  }

  Future<Job> detail(String id) async {
    final res = await AppApi.get(AppApi.uri('/jobs/$id'));
    if (res.statusCode != 200) {
      throw Exception('Could not open this job.');
    }
    final body = jsonDecode(res.body);
    if (body is! Map) throw Exception('Could not open this job.');
    return Job.fromJson(Map<String, dynamic>.from(body));
  }

  Future<Job> submit({
    required String title,
    required String companyName,
    required String category,
    required String city,
    required String description,
    String employmentType = 'Full Time',
    String workMode = 'Not specified',
    String salaryDisplay = '',
    String applyUrl = '',
    String contactEmail = '',
    String experienceRequired = '',
    String educationRequired = '',
  }) async {
    final res = await AppApi.post(
      AppApi.uri('/jobs'),
      body: jsonEncode({
        'title': title,
        'companyName': companyName,
        'category': category,
        'city': city,
        'description': description,
        'employmentType': employmentType,
        'workMode': workMode,
        'salaryDisplay': salaryDisplay,
        'applyUrl': applyUrl,
        'contactEmail': contactEmail,
        'experienceRequired': experienceRequired,
        'educationRequired': educationRequired,
      }),
    );
    if (res.statusCode != 201) {
      final body = jsonDecode(res.body);
      throw Exception(
        body is Map ? (body['error'] ?? 'Could not post this job.') : 'Could not post this job.',
      );
    }
    final body = jsonDecode(res.body);
    return Job.fromJson(Map<String, dynamic>.from(body as Map));
  }

  Future<void> _loadPage({
    String q = '',
    String category = '',
    String city = '',
    String employmentType = '',
    String workMode = '',
  }) async {
    final result = await list(
      q: q,
      category: category,
      city: city,
      employmentType: employmentType,
      workMode: workMode,
    );
    jobs = result.items;
    total = result.total;
    page = result.page;
  }

  Future<void> loadMore({
    String q = '',
    String category = '',
    String city = '',
    String employmentType = '',
    String workMode = '',
  }) async {
    if (loadingMore || !hasMore) return;
    loadingMore = true;
    notifyListeners();
    try {
      final next = await list(
        q: q,
        category: category,
        city: city,
        employmentType: employmentType,
        workMode: workMode,
        page: page + 1,
      );
      jobs = [...jobs, ...next.items];
      total = next.total;
      page = next.page;
    } finally {
      loadingMore = false;
      notifyListeners();
    }
  }

  List<JobFilter> _filters(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => JobFilter.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.name.isNotEmpty)
        .toList();
  }
}
