class GuideCategory {
  const GuideCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.parentId,
    required this.directCount,
    required this.totalCount,
    required this.childIds,
  });

  final String id;
  final String name;
  final String slug;
  final String parentId;
  final int directCount;
  final int totalCount;
  final List<String> childIds;

  bool get isTopLevel => parentId == '0';

  factory GuideCategory.fromJson(Map<String, dynamic> json) {
    return GuideCategory(
      id: json['id'].toString(),
      name: json['name'] as String,
      slug: json['slug'] as String,
      parentId: json['parentId'].toString(),
      directCount: json['directCount'] as int? ?? 0,
      totalCount: json['totalCount'] as int? ?? 0,
      childIds: (json['childIds'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class GuidePost {
  const GuidePost({
    required this.id,
    required this.title,
    required this.slug,
    required this.date,
    required this.excerpt,
    required this.preview,
    required this.categories,
    required this.wordCount,
    this.image,
    this.tags = const [],
    this.source = 'lisa',
    this.sourceLabel = 'Life in Saudi Arabia',
    this.body = '',
  });

  final String id;
  final String title;
  final String slug;
  final String date;
  final String excerpt;
  final String preview;
  final String? image;
  final List<String> categories;
  final List<String> tags;
  final int wordCount;
  final String source;
  final String sourceLabel;
  final String body;

  DateTime? get publishedAt => DateTime.tryParse(date);

  String get primaryCategory =>
      categories.isEmpty ? 'Guide' : categories.first;

  bool get isSaudiExpatriate => source == 'se';

  factory GuidePost.fromJson(Map<String, dynamic> json) {
    return GuidePost(
      id: json['id'].toString(),
      title: json['title'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      date: json['date'] as String? ?? '',
      excerpt: json['excerpt'] as String? ?? '',
      preview: json['preview'] as String? ?? '',
      image: () {
        final value = json['image'] as String?;
        if (value == null || value.trim().isEmpty) return null;
        return value;
      }(),
      categories: (json['categories'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      wordCount: json['wordCount'] as int? ?? 0,
      source: json['source'] as String? ?? 'lisa',
      sourceLabel: json['sourceLabel'] as String? ?? 'Life in Saudi Arabia',
      body: json['body'] as String? ?? '',
    );
  }
}
