class Favorite {
  final String id;
  final String userId;
  final String? productId;
  final String? recipeId;
  final String? videoId;
  final DateTime createdAt;
  final String? itemName;
  final String? itemImage;
  final String? itemDescription;
  final double? itemPrice;

  Favorite({
    required this.id,
    required this.userId,
    this.productId,
    this.recipeId,
    this.videoId,
    required this.createdAt,
    this.itemName,
    this.itemImage,
    this.itemDescription,
    this.itemPrice,
  });

  String get itemType {
    if (productId != null) return 'Produit';
    if (recipeId != null) return 'Recette';
    if (videoId != null) return 'Vidéo';
    return 'Inconnu';
  }

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      id: json['id'],
      userId: json['user_id'],
      productId: json['product_id'],
      recipeId: json['recipe_id'],
      videoId: json['video_id'],
      createdAt: DateTime.parse(json['created_at']),
      itemName: json['item_name'],
      itemImage: json['item_image'],
      itemDescription: json['item_description'],
      itemPrice: json['item_price']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'product_id': productId,
      'recipe_id': recipeId,
      'video_id': videoId,
      'created_at': createdAt.toIso8601String(),
      'item_name': itemName,
      'item_image': itemImage,
      'item_description': itemDescription,
      'item_price': itemPrice,
    };
  }
}
