class Product {
  final String id;
  final String name;
  final String? description;
  final String? longDescription;
  final double price;
  final String? image;
  final bool isNew;
  final double? rating;
  final int? reviews;
  final String? origin;
  final String? slug;
  final String? nutritionalInfo;
  final String? conservation;
  final double size; // Maintenant un nombre
  final String unit; // Nouvelle propriété pour l'unité
  final int stock;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? unitType;
  final bool isIngredient;
  final String? categoryId;

  Product({
    required this.id,
    required this.name,
    this.description,
    this.longDescription,
    required this.price,
    this.image,
    this.isNew = false,
    this.rating,
    this.reviews,
    this.origin,
    this.slug,
    this.nutritionalInfo,
    this.conservation,
    required this.size,
    required this.unit,
    this.stock = 0,
    required this.createdAt,
    required this.updatedAt,
    this.unitType,
    this.isIngredient = false,
    this.categoryId,
  });

  String get formattedPrice {
    return '${price.toStringAsFixed(0)} FCFA';
  }

  String get formattedSize {
    if (size == size.toInt()) {
      return '${size.toInt()} $unit';
    }
    return '${size.toStringAsFixed(1)} $unit';
  }

  String get stockStatus {
    if (stock <= 0) return 'Rupture de stock';
    if (stock <= 5) return 'Stock faible ($stock)';
    return 'En stock ($stock)';
  }

  bool get inStock => stock > 0;

  String get category => categoryId ?? 'Non catégorisé';

  int get stockQuantity => stock;

  int get reviewCount => reviews ?? 0;

  String? get imageUrl => image;

  // Calcul du prix pour une quantité donnée
  double calculateTotalPrice(int quantity) {
    return price * quantity;
  }

  // Calcul du poids/volume total pour une quantité donnée
  double calculateTotalSize(int quantity) {
    return size * quantity;
  }

  String getFormattedTotalSize(int quantity) {
    final totalSize = calculateTotalSize(quantity);
    if (totalSize == totalSize.toInt()) {
      return '${totalSize.toInt()} $unit';
    }
    return '${totalSize.toStringAsFixed(1)} $unit';
  }

  Map<String, dynamic>? get specifications {
    Map<String, dynamic> specs = {};
    
    if (origin != null) specs['Origine'] = origin!;
    specs['Taille'] = formattedSize;
    if (unitType != null) specs['Type d\'unité'] = unitType!;
    if (conservation != null) specs['Conservation'] = conservation!;
    if (nutritionalInfo != null) specs['Informations nutritionnelles'] = nutritionalInfo!;
    
    return specs.isEmpty ? null : specs;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      longDescription: json['long_description']?.toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      image: json['image']?.toString(),
      isNew: json['is_new'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble(),
      reviews: json['reviews'] as int?,
      origin: json['origin']?.toString(),
      slug: json['slug']?.toString(),
      nutritionalInfo: json['nutritional_info']?.toString(),
      conservation: json['conservation']?.toString(),
      size: (json['size'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit']?.toString() ?? 'g',
      stock: json['stock'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      unitType: json['unit_type']?.toString(),
      isIngredient: json['is_ingredient'] as bool? ?? false,
      categoryId: json['category_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'long_description': longDescription,
      'price': price,
      'image': image,
      'is_new': isNew,
      'rating': rating,
      'reviews': reviews,
      'origin': origin,
      'slug': slug,
      'nutritional_info': nutritionalInfo,
      'conservation': conservation,
      'size': size,
      'unit': unit,
      'stock': stock,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'unit_type': unitType,
      'is_ingredient': isIngredient,
      'category_id': categoryId,
    };
  }
}
