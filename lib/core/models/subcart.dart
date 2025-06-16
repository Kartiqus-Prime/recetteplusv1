class Subcart {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String? sourceType;
  final String? sourceId;
  final String? recipeId;
  final int? servings;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int itemCount;
  final double totalPrice;

  Subcart({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.sourceType,
    this.sourceId,
    this.recipeId,
    this.servings,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.itemCount = 0,
    this.totalPrice = 0.0,
  });

  String get formattedTotalPrice {
    return '${totalPrice.toStringAsFixed(0)} FCFA';
  }

  factory Subcart.fromJson(Map<String, dynamic> json) {
    return Subcart(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      description: json['description'],
      sourceType: json['source_type'],
      sourceId: json['source_id'],
      recipeId: json['recipe_id'],
      servings: json['servings'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.parse(json['created_at']),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'])
          : null,
      itemCount: json['item_count'] ?? 0,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'source_type': sourceType,
      'source_id': sourceId,
      'recipe_id': recipeId,
      'servings': servings,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'item_count': itemCount,
      'total_price': totalPrice,
    };
  }
}
