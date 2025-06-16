class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String content;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? actionUrl;
  final String? productId;
  final String? recipeId;
  final String? videoId;
  final String? orderId;
  final String? priority;
  final String? icon;
  final String? color;
  final Map<String, dynamic>? metadata;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.type,
    required this.isRead,
    required this.createdAt,
    required this.updatedAt,
    this.actionUrl,
    this.productId,
    this.recipeId,
    this.videoId,
    this.orderId,
    this.priority,
    this.icon,
    this.color,
    this.metadata,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      type: json['type'] as String,
      isRead: json['is_read'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      actionUrl: json['action_url'] as String?,
      productId: json['product_id'] as String?,
      recipeId: json['recipe_id'] as String?,
      videoId: json['video_id'] as String?,
      orderId: json['order_id'] as String?,
      priority: json['priority'] as String?,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'content': content,
      'type': type,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'action_url': actionUrl,
      'product_id': productId,
      'recipe_id': recipeId,
      'video_id': videoId,
      'order_id': orderId,
      'priority': priority,
      'icon': icon,
      'color': color,
      'metadata': metadata,
    };
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? content,
    String? type,
    bool? isRead,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? actionUrl,
    String? productId,
    String? recipeId,
    String? videoId,
    String? orderId,
    String? priority,
    String? icon,
    String? color,
    Map<String, dynamic>? metadata,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      actionUrl: actionUrl ?? this.actionUrl,
      productId: productId ?? this.productId,
      recipeId: recipeId ?? this.recipeId,
      videoId: videoId ?? this.videoId,
      orderId: orderId ?? this.orderId,
      priority: priority ?? this.priority,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      metadata: metadata ?? this.metadata,
    );
  }

  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}min';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}j';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  String get typeDisplayName {
    switch (type) {
      case 'order':
        return 'Commande';
      case 'new_content':
        return 'Nouveau';
      case 'promotion':
        return 'Promo';
      case 'low_stock':
        return 'Stock';
      case 'comment_reply':
        return 'Réponse';
      case 'auth':
        return 'Sécurité';
      case 'rating':
        return 'Avis';
      case 'price_drop':
        return 'Prix';
      case 'test':
        return 'Test';
      default:
        return 'Info';
    }
  }
}
