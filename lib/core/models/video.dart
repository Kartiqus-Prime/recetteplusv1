class Video {
  final String id;
  final String title;
  final String? description;
  final String? videoUrl;
  final String? thumbnailUrl;
  final String? category;
  final String? authorName;
  final int views;
  final int likes;
  final String? duration;
  final List<String>? tags;
  final String? recipeId;
  final bool isPublished;
  final bool isShort;
  final bool userHasLiked;
  final DateTime createdAt;
  final DateTime updatedAt;

  Video({
    required this.id,
    required this.title,
    this.description,
    this.videoUrl,
    this.thumbnailUrl,
    this.category,
    this.authorName,
    this.views = 0,
    this.likes = 0,
    this.duration,
    this.tags,
    this.recipeId,
    this.isPublished = false,
    this.isShort = false,
    this.userHasLiked = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Titre non disponible',
      description: json['description'] as String?,
      videoUrl: json['video_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      category: json['category'] as String?,
      authorName: json['author_name'] as String?,
      views: json['views'] as int? ?? 0,
      likes: json['likes'] as int? ?? 0,
      duration: json['duration'] as String?,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      recipeId: json['recipe_id'] as String?,
      isPublished: json['is_published'] as bool? ?? false,
      isShort: json['is_short'] as bool? ?? false,
      userHasLiked: json['user_has_liked'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'video_url': videoUrl,
      'thumbnail_url': thumbnailUrl,
      'category': category,
      'author_name': authorName,
      'views': views,
      'likes': likes,
      'duration': duration,
      'tags': tags,
      'recipe_id': recipeId,
      'is_published': isPublished,
      'is_short': isShort,
      'user_has_liked': userHasLiked,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get formattedViews {
    if (views == 0) return '0 vue';
    if (views < 1000) return '$views vues';
    if (views < 1000000) return '${(views / 1000).toStringAsFixed(1)}K vues';
    return '${(views / 1000000).toStringAsFixed(1)}M vues';
  }

  String get formattedDuration => duration ?? '00:00';
}
