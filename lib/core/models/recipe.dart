import 'dart:convert';

class Recipe {
  final String id;
  final String title;
  final String? description;
  final String? image;
  final String? prepTime;
  final String? cookTime;
  final String? totalTime;
  final String? difficulty;
  final int? servings;
  final double? rating;
  // Champ reviews supprimé
  // Champ author supprimé
  final String? categoryId;
  final List<String>? tags;
  final List<String>? instructions;
  final Map<String, dynamic>? nutrition;
  final String? videoUrl;
  final bool isFeatured;
  final bool isPublished;
  final String? slug;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? estimatedCost;
  final String? complexityLevel;
  final String? cuisineType;
  final List<String>? dietaryRestrictions;
  final List<String>? allergens;
  final List<RecipeIngredient>? ingredients;
  final List<RecipeProduct>? relatedProducts;
  String? categoryName;
  final int? defaultServings;

  Recipe({
    required this.id,
    required this.title,
    this.description,
    this.image,
    this.prepTime,
    this.cookTime,
    this.totalTime,
    this.difficulty,
    this.servings,
    this.rating,
    // Champ reviews supprimé
    // Champ author supprimé
    this.categoryId,
    this.tags,
    this.instructions,
    this.nutrition,
    this.videoUrl,
    this.isFeatured = false,
    this.isPublished = true,
    this.slug,
    required this.createdAt,
    required this.updatedAt,
    this.estimatedCost,
    this.complexityLevel,
    this.cuisineType,
    this.dietaryRestrictions,
    this.allergens,
    this.ingredients,
    this.relatedProducts,
    this.categoryName,
    this.defaultServings,
  });

  String get formattedPrepTime {
    return prepTime ?? 'Non spécifié';
  }

  String get formattedCookTime {
    return cookTime ?? 'Non spécifié';
  }

  String get formattedTotalTime {
    return totalTime ?? 'Non spécifié';
  }

  String get formattedEstimatedCost {
    if (estimatedCost == null) return 'Non spécifié';
    return '${estimatedCost!.toStringAsFixed(0)} FCFA';
  }

  // Calculer le coût total basé sur les ingrédients
  double get calculatedTotalCost {
    if (ingredients == null || ingredients!.isEmpty) {
      return estimatedCost ?? 0.0;
    }
    
    double total = 0.0;
    for (final ingredient in ingredients!) {
      if (ingredient.productPrice != null) {
        total += ingredient.productPrice! * ingredient.quantity;
      }
    }
    
    return total;
  }

  // Coût formaté calculé
  String get formattedCalculatedCost {
    final cost = calculatedTotalCost;
    if (cost <= 0) return 'Coût non disponible';
    return '${cost.toStringAsFixed(0)} FCFA';
  }

  // Coût par portion
  double get costPerServing {
    final totalCost = calculatedTotalCost;
    final portions = servings ?? 1;
    return totalCost / portions;
  }

  // Coût par portion formaté
  String get formattedCostPerServing {
    final cost = costPerServing;
    if (cost <= 0) return 'N/A';
    return '${cost.toStringAsFixed(0)} FCFA/portion';
  }

  // Vérifier si le coût peut être calculé
  bool get canCalculateCost {
    if (ingredients == null || ingredients!.isEmpty) return false;
    return ingredients!.any((ingredient) => ingredient.productPrice != null);
  }

  // Pourcentage d'ingrédients avec prix
  double get ingredientPriceCompleteness {
    if (ingredients == null || ingredients!.isEmpty) return 0.0;
    final withPrice = ingredients!.where((i) => i.productPrice != null).length;
    return (withPrice / ingredients!.length) * 100;
  }

  String get difficultyLevel {
    switch (difficulty?.toLowerCase()) {
      case 'easy':
        return 'Facile';
      case 'medium':
        return 'Moyen';
      case 'hard':
        return 'Difficile';
      default:
        return difficulty ?? 'Non spécifié';
    }
  }

  factory Recipe.fromJson(Map<String, dynamic> json) {
    List<String>? tagsList;
    if (json['tags'] != null) {
      if (json['tags'] is List) {
        tagsList = List<String>.from(json['tags']);
      } else if (json['tags'] is String) {
        // Si c'est une chaîne JSON, essayer de la parser
        try {
          final parsed = json['tags'].toString().replaceAll("'", '"');
          if (parsed.startsWith('[') && parsed.endsWith(']')) {
            final List<dynamic> parsedList = jsonDecode(parsed);
            tagsList = parsedList.map((e) => e.toString()).toList();
          } else {
            tagsList = [json['tags']];
          }
        } catch (e) {
          tagsList = [json['tags']];
        }
      }
    }

    List<String>? instructionsList;
    if (json['instructions'] != null) {
      if (json['instructions'] is List) {
        instructionsList = List<String>.from(json['instructions']);
      } else if (json['instructions'] is String) {
        // Si c'est une chaîne JSON, essayer de la parser
        try {
          final parsed = json['instructions'].toString().replaceAll("'", '"');
          if (parsed.startsWith('[') && parsed.endsWith(']')) {
            final List<dynamic> parsedList = jsonDecode(parsed);
            instructionsList = parsedList.map((e) => e.toString()).toList();
          } else {
            instructionsList = [json['instructions']];
          }
        } catch (e) {
          instructionsList = [json['instructions']];
        }
      }
    }

    List<String>? dietaryList;
    if (json['dietary_restrictions'] != null) {
      if (json['dietary_restrictions'] is List) {
        dietaryList = List<String>.from(json['dietary_restrictions']);
      } else if (json['dietary_restrictions'] is String) {
        try {
          final parsed =
              json['dietary_restrictions'].toString().replaceAll("'", '"');
          if (parsed.startsWith('[') && parsed.endsWith(']')) {
            final List<dynamic> parsedList = jsonDecode(parsed);
            dietaryList = parsedList.map((e) => e.toString()).toList();
          } else {
            dietaryList = [json['dietary_restrictions']];
          }
        } catch (e) {
          dietaryList = [json['dietary_restrictions']];
        }
      }
    }

    List<String>? allergensList;
    if (json['allergens'] != null) {
      if (json['allergens'] is List) {
        allergensList = List<String>.from(json['allergens']);
      } else if (json['allergens'] is String) {
        try {
          final parsed = json['allergens'].toString().replaceAll("'", '"');
          if (parsed.startsWith('[') && parsed.endsWith(']')) {
            final List<dynamic> parsedList = jsonDecode(parsed);
            allergensList = parsedList.map((e) => e.toString()).toList();
          } else {
            allergensList = [json['allergens']];
          }
        } catch (e) {
          allergensList = [json['allergens']];
        }
      }
    }

    // Parse nutrition
    Map<String, dynamic>? nutritionMap;
    if (json['nutrition'] != null) {
      if (json['nutrition'] is Map) {
        nutritionMap = Map<String, dynamic>.from(json['nutrition']);
      } else if (json['nutrition'] is String) {
        try {
          final parsed = json['nutrition'].toString().replaceAll("'", '"');
          if (parsed.startsWith('{') && parsed.endsWith('}')) {
            nutritionMap = jsonDecode(parsed);
          }
        } catch (e) {
          // Ignorer l'erreur
        }
      }
    }

    // Parse ingredients
    List<RecipeIngredient>? ingredientsList;
    if (json['ingredients'] != null && json['ingredients'] is List) {
      ingredientsList = (json['ingredients'] as List)
          .map((item) => RecipeIngredient.fromJson(item))
          .toList();
    }

    // Parse related products
    List<RecipeProduct>? productsList;
    if (json['related_products'] != null && json['related_products'] is List) {
      productsList = (json['related_products'] as List)
          .map((item) => RecipeProduct.fromJson(item))
          .toList();
    }

    return Recipe(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      image: json['image'],
      prepTime: json['prep_time']?.toString(),
      cookTime: json['cook_time']?.toString(),
      totalTime: json['total_time']?.toString(),
      difficulty: json['difficulty'],
      servings: json['servings'] is String
          ? int.tryParse(json['servings'])
          : json['servings'],
      rating: json['rating'] is String
          ? double.tryParse(json['rating'])
          : json['rating']?.toDouble(),
      // Champ reviews supprimé
      // Champ author supprimé
      categoryId: json['category_id']?.toString(),
      tags: tagsList,
      instructions: instructionsList,
      nutrition: nutritionMap,
      videoUrl: json['video_url'],
      isFeatured: json['is_featured'] ?? false,
      isPublished: json['is_published'] ?? true,
      slug: json['slug'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      estimatedCost: json['estimated_cost'] is String
          ? double.tryParse(json['estimated_cost'])
          : json['estimated_cost']?.toDouble(),
      complexityLevel: json['complexity_level'],
      cuisineType: json['cuisine_type'],
      dietaryRestrictions: dietaryList,
      allergens: allergensList,
      ingredients: ingredientsList,
      relatedProducts: productsList,
      categoryName: json['category_name'],
      defaultServings: json['default_servings'] is String
          ? int.tryParse(json['default_servings'])
          : json['default_servings'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'image': image,
      'prep_time': prepTime,
      'cook_time': cookTime,
      'total_time': totalTime,
      'difficulty': difficulty,
      'servings': servings,
      'rating': rating,
      // Champ reviews supprimé
      // Champ author supprimé
      'category_id': categoryId,
      'tags': tags,
      'instructions': instructions,
      'nutrition': nutrition,
      'video_url': videoUrl,
      'is_featured': isFeatured,
      'is_published': isPublished,
      'slug': slug,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'estimated_cost': estimatedCost,
      'complexity_level': complexityLevel,
      'cuisine_type': cuisineType,
      'dietary_restrictions': dietaryRestrictions,
      'allergens': allergens,
      'ingredients': ingredients?.map((e) => e.toJson()).toList(),
      'related_products': relatedProducts?.map((e) => e.toJson()).toList(),
      'category_name': categoryName,
      'default_servings': defaultServings,
    };
  }
}

class RecipeIngredient {
  final String id;
  final String recipeId;
  final String? productId;
  final String name;
  final double quantity;
  final String unit;
  final String? notes;
  final String? productImage;
  final double? productPrice;
  final bool? optional;

  RecipeIngredient({
    required this.id,
    required this.recipeId,
    this.productId,
    required this.name,
    required this.quantity,
    required this.unit,
    this.notes,
    this.productImage,
    this.productPrice,
    this.optional,
  });

  String get formattedQuantity {
    if (quantity == quantity.toInt()) {
      return '${quantity.toInt()} $unit';
    }
    return '${quantity.toStringAsFixed(1)} $unit';
  }

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      id: json['id'],
      recipeId: json['recipe_id'],
      productId: json['product_id'],
      name: json['name'] ?? 'Ingrédient',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] ?? '',
      notes: json['notes'],
      productImage: json['product_image'],
      productPrice: (json['product_price'] as num?)?.toDouble(),
      optional: json['optional'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipe_id': recipeId,
      'product_id': productId,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'notes': notes,
      'product_image': productImage,
      'product_price': productPrice,
      'optional': optional,
    };
  }
}

class RecipeProduct {
  final String id;
  final String recipeId;
  final String productId;
  final String? name;
  final String? description;
  final double? price;
  final String? image;
  final double? size;
  final String? unit;

  RecipeProduct({
    required this.id,
    required this.recipeId,
    required this.productId,
    this.name,
    this.description,
    this.price,
    this.image,
    this.size,
    this.unit,
  });

  String get formattedPrice {
    if (price == null) return 'Prix non disponible';
    return '${price!.toStringAsFixed(0)} FCFA';
  }

  String get formattedSize {
    if (size == null || unit == null) return '';
    if (size == size!.toInt()) {
      return '${size!.toInt()} $unit';
    }
    return '${size!.toStringAsFixed(1)} $unit';
  }

  factory RecipeProduct.fromJson(Map<String, dynamic> json) {
    return RecipeProduct(
      id: json['id'],
      recipeId: json['recipe_id'],
      productId: json['product_id'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] as num?)?.toDouble(),
      image: json['image'],
      size: (json['size'] as num?)?.toDouble(),
      unit: json['unit'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipe_id': recipeId,
      'product_id': productId,
      'name': name,
      'description': description,
      'price': price,
      'image': image,
      'size': size,
      'unit': unit,
    };
  }
}
