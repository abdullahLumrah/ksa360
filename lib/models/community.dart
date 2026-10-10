import '../data/app_api_config.dart';

class Community {
  const Community({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.coverImage,
    required this.topic,
    required this.city,
    required this.creatorId,
    required this.creatorName,
    required this.memberCount,
    required this.postCount,
    required this.viewCount,
    required this.status,
    required this.joined,
    required this.role,
    required this.isOwner,
    required this.createdAt,
    this.previewPosts = const [],
    this.isDummy = false,
  });

  final String id;
  final String name;
  final String slug;
  final String description;
  final String coverImage;
  final String topic;
  final String city;
  final String creatorId;
  final String creatorName;
  final int memberCount;
  final int postCount;
  final int viewCount;
  final String status;
  final bool joined;
  final String role;
  final bool isOwner;
  final String createdAt;
  final List<CommunityPost> previewPosts;
  final bool isDummy;

  bool get canModerate => isOwner || role == 'owner' || role == 'admin';

  factory Community.fromJson(Map<String, dynamic> json) {
    final previews = json['previewPosts'];
    return Community(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      coverImage: (json['coverImage'] ?? '').toString(),
      topic: (json['topic'] ?? 'General').toString(),
      city: (json['city'] ?? '').toString(),
      creatorId: (json['creatorId'] ?? '').toString(),
      creatorName: (json['creatorName'] ?? '').toString(),
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
      postCount: (json['postCount'] as num?)?.toInt() ?? 0,
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
      status: (json['status'] ?? 'active').toString(),
      joined: json['joined'] == true,
      role: (json['role'] ?? '').toString(),
      isOwner: json['isOwner'] == true,
      createdAt: (json['createdAt'] ?? '').toString(),
      isDummy: json['isDummy'] == true,
      previewPosts: previews is List
          ? previews
              .whereType<Map>()
              .map((item) => CommunityPost.fromJson(Map<String, dynamic>.from(item)))
              .toList()
          : const [],
    );
  }

  Community copyWith({
    bool? joined,
    String? role,
    bool? isOwner,
    int? memberCount,
    int? viewCount,
    List<CommunityPost>? previewPosts,
  }) {
    return Community(
      id: id,
      name: name,
      slug: slug,
      description: description,
      coverImage: coverImage,
      topic: topic,
      city: city,
      creatorId: creatorId,
      creatorName: creatorName,
      memberCount: memberCount ?? this.memberCount,
      postCount: postCount,
      viewCount: viewCount ?? this.viewCount,
      status: status,
      joined: joined ?? this.joined,
      role: role ?? this.role,
      isOwner: isOwner ?? this.isOwner,
      createdAt: createdAt,
      previewPosts: previewPosts ?? this.previewPosts,
      isDummy: isDummy,
    );
  }
}

class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.communityId,
    required this.communityName,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    required this.body,
    required this.image,
    required this.status,
    required this.likeCount,
    required this.commentCount,
    required this.viewCount,
    required this.liked,
    required this.createdAt,
    this.joined = false,
    this.isOwner = false,
    this.isDummy = false,
  });

  final String id;
  final String communityId;
  final String communityName;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String body;
  final String image;
  final String status;
  final int likeCount;
  final int commentCount;
  final int viewCount;
  final bool liked;
  final String createdAt;
  final bool joined;
  final bool isOwner;
  final bool isDummy;

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: (json['id'] ?? '').toString(),
      communityId: (json['communityId'] ?? '').toString(),
      communityName: (json['communityName'] ?? '').toString(),
      authorId: (json['authorId'] ?? '').toString(),
      authorName: (json['authorName'] ?? 'Member').toString(),
      authorAvatar: (json['authorAvatar'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      image: AppApiConfig.mediaUrl((json['image'] ?? '').toString()),
      status: (json['status'] ?? 'pending').toString(),
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
      liked: json['liked'] == true,
      createdAt: (json['createdAt'] ?? '').toString(),
      joined: json['joined'] == true,
      isOwner: json['isOwner'] == true,
      isDummy: json['isDummy'] == true,
    );
  }

  CommunityPost copyWith({
    int? likeCount,
    int? commentCount,
    int? viewCount,
    bool? liked,
    String? status,
    bool? joined,
    bool? isOwner,
  }) {
    return CommunityPost(
      id: id,
      communityId: communityId,
      communityName: communityName,
      authorId: authorId,
      authorName: authorName,
      authorAvatar: authorAvatar,
      body: body,
      image: image,
      status: status ?? this.status,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      viewCount: viewCount ?? this.viewCount,
      liked: liked ?? this.liked,
      createdAt: createdAt,
      joined: joined ?? this.joined,
      isOwner: isOwner ?? this.isOwner,
      isDummy: isDummy,
    );
  }
}

class CommunityComment {
  const CommunityComment({
    required this.id,
    required this.postId,
    required this.communityId,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    required this.parentId,
    required this.body,
    required this.likeCount,
    required this.liked,
    required this.status,
    required this.createdAt,
    this.replies = const [],
    this.isDummy = false,
  });

  final String id;
  final String postId;
  final String communityId;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String parentId;
  final String body;
  final int likeCount;
  final bool liked;
  final String status;
  final String createdAt;
  final List<CommunityComment> replies;
  final bool isDummy;

  bool get isReply => parentId.isNotEmpty;

  factory CommunityComment.fromJson(Map<String, dynamic> json) {
    final nested = json['replies'];
    return CommunityComment(
      id: (json['id'] ?? '').toString(),
      postId: (json['postId'] ?? '').toString(),
      communityId: (json['communityId'] ?? '').toString(),
      authorId: (json['authorId'] ?? '').toString(),
      authorName: (json['authorName'] ?? 'Member').toString(),
      authorAvatar: (json['authorAvatar'] ?? '').toString(),
      parentId: (json['parentId'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      liked: json['liked'] == true,
      status: (json['status'] ?? 'active').toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
      isDummy: json['isDummy'] == true,
      replies: nested is List
          ? nested
              .whereType<Map>()
              .map((item) => CommunityComment.fromJson(Map<String, dynamic>.from(item)))
              .toList()
          : const [],
    );
  }

  CommunityComment copyWith({
    int? likeCount,
    bool? liked,
    List<CommunityComment>? replies,
  }) {
    return CommunityComment(
      id: id,
      postId: postId,
      communityId: communityId,
      authorId: authorId,
      authorName: authorName,
      authorAvatar: authorAvatar,
      parentId: parentId,
      body: body,
      likeCount: likeCount ?? this.likeCount,
      liked: liked ?? this.liked,
      status: status,
      createdAt: createdAt,
      replies: replies ?? this.replies,
      isDummy: isDummy,
    );
  }
}
