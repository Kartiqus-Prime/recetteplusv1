class Video {
  final String id;
  final String? title;
  final String? description;
  final String? videoUrl;
  final String? duration;
  final int? views;
  final int? likes;
  final DateTime? publishedAt;
  final String? category;
  final List<String>? tags;
  final String? author;
  final String? slug;
  final bool? featured;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? recipeId;
  final String? thumbnailUrl;
  final bool? isShort;
  final String? authorName;

  Video({
    required this.id,
    this.title,
    this.description,
    this.videoUrl,
    this.duration,
    this.views,
    this.likes,
    this.publishedAt,
    this.category,
    this.tags,
    this.author,
    this.slug,
    this.featured,
    required this.createdAt,
    required this.updatedAt,
    this.recipeId,
    this.thumbnailUrl,
    this.isShort,
    this.authorName,
  });

  String get formattedViews {
    if (views == null || views == 0) return '0 vue';
    if (views! < 1000) return '$views vues';
    if (views! < 1000000) return '${(views! / 1000).toStringAsFixed(1)}K vues';
    return '${(views! / 1000000).toStringAsFixed(1)}M vues';
  }

  String get formattedDuration {
    if (duration == null) return 'Durée inconnue';
    return duration!;
  }

  int get viewCount => views ?? 0;
  int get likeCount => likes ?? 0;
  bool get isPublished => publishedAt != null;
  String get authorId => author ?? '';

  factory Video.fromJson(Map<String, dynamic> json) {
    List<String>? tagsList;
    if (json['tags'] != null) {
      if (json['tags'] is List) {
        tagsList = List<String>.from(json['tags']);
      }
    }

    return Video(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString(),
      description: json['description']?.toString(),
      videoUrl: json['video_url']?.toString(),
      duration: json['duration']?.toString(),
      views: json['views'] as int?,
      likes: json['likes'] as int?,
      publishedAt: json['published_at'] != null 
          ? DateTime.parse(json['published_at']) 
          : null,
      category: json['category']?.toString(),
      tags: tagsList,
      author: json['author']?.toString(),
      slug: json['slug']?.toString(),
      featured: json['featured'] as bool?,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      recipeId: json['recipe_id']?.toString(),
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      isShort: json['is_short'] as bool?,
      authorName: json['author']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'video_url': videoUrl,
      'duration': duration,
      'views': views,
      'likes': likes,
      'published_at': publishedAt?.toIso8601String(),
      'category': category,
      'tags': tags,
      'author': author,
      'slug': slug,
      'featured': featured,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'recipe_id': recipeId,
      'thumbnailUrl': thumbnailUrl,
      'is_short': isShort,
      'author_name': authorName,
    };
  }
}
