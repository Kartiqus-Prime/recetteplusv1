import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recipe.dart';
import '../models/product.dart';
import '../models/video.dart';

class SearchResult {
  final List<Recipe> recipes;
  final List<Product> products;
  final List<Video> videos;
  final int totalCount;

  SearchResult({
    required this.recipes,
    required this.products,
    required this.videos,
  }) : totalCount = recipes.length + products.length + videos.length;
}

class SearchService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Recherche globale
  Future<SearchResult> globalSearch(String query) async {
    if (query.trim().isEmpty) {
      return SearchResult(recipes: [], products: [], videos: []);
    }

    try {
      // Recherche parallèle dans toutes les catégories
      final results = await Future.wait([
        _searchRecipes(query),
        _searchProducts(query),
        _searchVideos(query),
      ]);

      return SearchResult(
        recipes: results[0] as List<Recipe>,
        products: results[1] as List<Product>,
        videos: results[2] as List<Video>,
      );
    } catch (e) {
      print('Erreur lors de la recherche globale: $e');
      return SearchResult(recipes: [], products: [], videos: []);
    }
  }

  // Recherche dans les recettes
  Future<List<Recipe>> _searchRecipes(String query) async {
    try {
      final response = await _supabase
          .from('active_recipes')
          .select()
          .or('title.ilike.%${query}%,description.ilike.%${query}%')
          .limit(10);

      final List<Recipe> recipes = [];
      for (final item in response) {
        final recipe = Recipe.fromJson(item);
        
        // Récupérer la catégorie
        if (recipe.categoryId != null) {
          try {
            final categoryResponse = await _supabase
                .from('recipe_categories')
                .select('name')
                .eq('id', recipe.categoryId.toString())
                .single();
            recipe.categoryName = categoryResponse['name'];
          } catch (e) {
            // Ignorer l'erreur de catégorie
          }
        }

        // Récupérer les ingrédients
        final ingredients = await _getRecipeIngredients(recipe.id);
        final recipeWithIngredients = Recipe(
          id: recipe.id,
          title: recipe.title,
          description: recipe.description,
          image: recipe.image,
          prepTime: recipe.prepTime,
          cookTime: recipe.cookTime,
          totalTime: recipe.totalTime,
          difficulty: recipe.difficulty,
          servings: recipe.servings,
          rating: recipe.rating,
          categoryId: recipe.categoryId,
          tags: recipe.tags,
          instructions: recipe.instructions,
          nutrition: recipe.nutrition,
          videoUrl: recipe.videoUrl,
          isFeatured: recipe.isFeatured,
          isPublished: recipe.isPublished,
          slug: recipe.slug,
          createdAt: recipe.createdAt,
          updatedAt: recipe.updatedAt,
          estimatedCost: recipe.estimatedCost,
          complexityLevel: recipe.complexityLevel,
          cuisineType: recipe.cuisineType,
          dietaryRestrictions: recipe.dietaryRestrictions,
          allergens: recipe.allergens,
          ingredients: ingredients,
          relatedProducts: recipe.relatedProducts,
          categoryName: recipe.categoryName,
          defaultServings: recipe.defaultServings,
        );

        recipes.add(recipeWithIngredients);
      }

      return recipes;
    } catch (e) {
      print('Erreur lors de la recherche de recettes: $e');
      return [];
    }
  }

  // Recherche dans les produits
  Future<List<Product>> _searchProducts(String query) async {
    try {
      final response = await _supabase
          .from('active_products')
          .select()
          .or('name.ilike.%${query}%,description.ilike.%${query}%')
          .limit(10);

      return response.map<Product>((item) => Product.fromJson(item)).toList();
    } catch (e) {
      print('Erreur lors de la recherche de produits: $e');
      return [];
    }
  }

  // Recherche dans les vidéos
  Future<List<Video>> _searchVideos(String query) async {
    try {
      final response = await _supabase
          .from('videos')
          .select()
          .or('title.ilike.%${query}%,description.ilike.%${query}%')
          .eq('is_published', true)
          .limit(10);

      return response.map<Video>((item) => Video.fromJson(item)).toList();
    } catch (e) {
      print('Erreur lors de la recherche de vidéos: $e');
      return [];
    }
  }

  // Récupérer les ingrédients d'une recette
  Future<List<RecipeIngredient>> _getRecipeIngredients(String recipeId) async {
    try {
      final response = await _supabase
          .from('recipe_ingredients')
          .select('*, products(*)')
          .eq('recipe_id', recipeId)
          .order('id');

      return response.map<RecipeIngredient>((item) {
        final productName =
            item['products'] != null && item['products']['name'] != null
                ? item['products']['name'].toString()
                : (item['name'] ?? 'Ingrédient').toString();

        final productImage =
            item['products'] != null ? item['products']['image'] : null;
        final productPrice =
            item['products'] != null ? item['products']['price'] : null;

        return RecipeIngredient(
          id: item['id'],
          recipeId: item['recipe_id'],
          productId: item['product_id'],
          name: productName,
          quantity: (item['quantity'] as num?)?.toDouble() ?? 0.0,
          unit: item['unit'] ?? '',
          notes: item['notes'],
          productImage: productImage,
          productPrice:
              productPrice != null ? (productPrice as num).toDouble() : null,
          optional: item['optional'] ?? false,
        );
      }).toList();
    } catch (e) {
      print('Erreur lors de la récupération des ingrédients: $e');
      return [];
    }
  }

  // Suggestions de recherche populaires
  Future<List<String>> getPopularSearches() async {
    // Retourner des suggestions statiques pour le moment
    return [
      'Thieboudienne',
      'Maafe',
      'Fonio',
      'Attieké',
      'Yassa',
      'Bissap',
      'Gingembre',
      'Mil',
      'Sorgho',
      'Baobab',
    ];
  }
}
