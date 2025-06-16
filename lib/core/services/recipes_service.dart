import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recipe.dart';

class RecipesService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Récupérer toutes les recettes actives
  Future<List<Recipe>> getAllRecipes() async {
    try {
      // Récupérer les recettes sans la jointure directe avec categories
      final response = await _supabase
          .from('active_recipes')
          .select()
          .order('title', ascending: true);

      final List<Recipe> recipes = [];
      for (final item in response) {
        final recipe = Recipe.fromJson(item);

        // Récupérer la catégorie séparément
        await _enrichRecipeWithCategory(recipe);

        // Récupérer les ingrédients pour cette recette
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
          // Champ reviews supprimé
          // Champ author supprimé
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
      print('Erreur lors de la récupération des recettes: $e');
      throw Exception('Erreur lors de la récupération des recettes: $e');
    }
  }

  // Récupérer les recettes favorites de l'utilisateur
  Future<List<Recipe>> getUserFavoriteRecipes() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      final response = await _supabase
          .from('favorites')
          .select('recipe_id')
          .eq('user_id', userId)
          .not('recipe_id', 'is', null); // Filtrer les recipe_id null

      if (response.isEmpty) {
        return [];
      }

      // Filtrer les IDs null ou invalides
      final recipeIds = response
          .map((item) => item['recipe_id'])
          .where((id) => id != null && id.toString().trim().isNotEmpty)
          .toList();

      if (recipeIds.isEmpty) {
        return [];
      }

      // Récupérer les recettes sans la jointure directe avec categories
      final recipesResponse = await _supabase
          .from('active_recipes')
          .select()
          .inFilter('id', recipeIds)
          .order('title', ascending: true);

      final List<Recipe> recipes = [];
      for (final item in recipesResponse) {
        final recipe = Recipe.fromJson(item);

        // Récupérer la catégorie séparément
        await _enrichRecipeWithCategory(recipe);

        // Récupérer les ingrédients pour cette recette
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
          // Champ reviews supprimé
          // Champ author supprimé
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
      print('Erreur lors de la récupération des recettes favorites: $e');
      throw Exception(
          'Erreur lors de la récupération des recettes favorites: $e');
    }
  }

  // Récupérer une recette par son ID
  Future<Recipe> getRecipeById(String id) async {
    try {
      // Récupérer la recette sans la jointure directe avec categories
      final response =
          await _supabase.from('active_recipes').select().eq('id', id).single();

      final recipe = Recipe.fromJson(response);

      // Récupérer la catégorie séparément
      await _enrichRecipeWithCategory(recipe);

      // Récupérer les ingrédients pour cette recette
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
        // Champ reviews supprimé
        // Champ author supprimé
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
        relatedProducts: await _getRecipeProducts(recipe.id),
        categoryName: recipe.categoryName,
        defaultServings: recipe.defaultServings,
      );

      return recipeWithIngredients;
    } catch (e) {
      print('Erreur lors de la récupération de la recette: $e');
      throw Exception('Erreur lors de la récupération de la recette: $e');
    }
  }

  // Rechercher des recettes avec une recherche moins rigoureuse
  Future<List<Recipe>> searchRecipes(String query) async {
    try {
      // Utiliser une recherche plus flexible avec ILIKE pour les correspondances partielles
      final response = await _supabase
          .from('active_recipes')
          .select()
          .or('title.ilike.%${query}%,description.ilike.%${query}%')
          .order('title', ascending: true);

      final List<Recipe> recipes = [];
      for (final item in response) {
        final recipe = Recipe.fromJson(item);

        // Récupérer la catégorie séparément
        await _enrichRecipeWithCategory(recipe);

        // Récupérer les ingrédients pour cette recette
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
          // Champ reviews supprimé
          // Champ author supprimé
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

      // Si aucun résultat direct, essayer de rechercher dans les ingrédients et les tags
      if (recipes.isEmpty) {
        // Rechercher dans les ingrédients - Correction: utiliser select distinct
        final ingredientResponse = await _supabase
            .from('recipe_ingredients')
            .select('recipe_id')
            .ilike('name', '%${query}%');
        
        // Éliminer les doublons côté client
        final Set<String> uniqueRecipeIds = {};
        for (final item in ingredientResponse) {
          if (item['recipe_id'] != null) {
            uniqueRecipeIds.add(item['recipe_id'].toString());
          }
        }
        
        final tagResponse = await _supabase
            .from('active_recipes')
            .select()
            .containedBy('tags', [query])
            .order('title', ascending: true);
        
        // Utiliser les IDs uniques
        final List<String> recipeIds = uniqueRecipeIds.toList();
        
        // Si des recettes ont été trouvées via les ingrédients, les récupérer
        if (recipeIds.isNotEmpty) {
          final ingredientRecipesResponse = await _supabase
              .from('active_recipes')
              .select()
              .inFilter('id', recipeIds)
              .order('title', ascending: true);
          
          for (final item in ingredientRecipesResponse) {
            final recipe = Recipe.fromJson(item);
            await _enrichRecipeWithCategory(recipe);
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
            
            // Vérifier si la recette n'est pas déjà dans la liste
            if (!recipes.any((r) => r.id == recipeWithIngredients.id)) {
              recipes.add(recipeWithIngredients);
            }
          }
        }
        
        // Ajouter les recettes trouvées via les tags
        for (final item in tagResponse) {
          final recipe = Recipe.fromJson(item);
          await _enrichRecipeWithCategory(recipe);
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
          
          // Vérifier si la recette n'est pas déjà dans la liste
          if (!recipes.any((r) => r.id == recipeWithIngredients.id)) {
            recipes.add(recipeWithIngredients);
          }
        }
      }

      return recipes;
    } catch (e) {
      print('Erreur lors de la recherche de recettes: $e');
      throw Exception('Erreur lors de la recherche de recettes: $e');
    }
  }

  // Méthode pour récupérer la catégorie d'une recette
  Future<void> _enrichRecipeWithCategory(Recipe recipe) async {
    try {
      if (recipe.categoryId == null) return;

      // Essayer d'abord avec recipe_categories comme suggéré par l'erreur
      try {
        final categoryResponse = await _supabase
            .from('recipe_categories')
            .select('name')
            .eq('id', recipe.categoryId.toString())
            .single();

        if (categoryResponse != null) {
          recipe.categoryName = categoryResponse['name'];
        }
      } catch (e) {
        print(
            'Erreur lors de la récupération de la catégorie (recipe_categories): $e');

        // Essayer avec la table categories si recipe_categories échoue
        try {
          final categoryResponse = await _supabase
              .from('categories')
              .select('name')
              .eq('id', recipe.categoryId.toString())
              .single();

          if (categoryResponse != null) {
            recipe.categoryName = categoryResponse['name'];
          }
        } catch (e) {
          print(
              'Erreur lors de la récupération de la catégorie (categories): $e');
        }
      }
    } catch (e) {
      print(
          'Erreur lors de l\'enrichissement de la recette avec la catégorie: $e');
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
        // Correction: Utiliser le nom du produit si disponible
        final productName =
            item['products'] != null && item['products']['name'] != null
                ? item['products']['name']
                    .toString() // Correction: Ajout de toString()
                : (item['name'] ?? 'Ingrédient')
                    .toString(); // Correction: Ajout de toString()

        final productImage =
            item['products'] != null ? item['products']['image'] : null;
        final productPrice =
            item['products'] != null ? item['products']['price'] : null;

        return RecipeIngredient(
          id: item['id'],
          recipeId: item['recipe_id'],
          productId: item['product_id'],
          name: productName, // Utiliser le nom du produit
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

  // Récupérer les produits associés à une recette
  Future<List<RecipeProduct>> _getRecipeProducts(String recipeId) async {
    try {
      final response = await _supabase
          .from('recipe_products')
          .select('*, products(*)')
          .eq('recipe_id', recipeId);

      return response.map<RecipeProduct>((item) {
        return RecipeProduct(
          id: item['id'],
          recipeId: item['recipe_id'],
          productId: item['product_id'],
          name: item['products'] != null ? item['products']['name'] : null,
          description:
              item['products'] != null ? item['products']['description'] : null,
          price: item['products'] != null && item['products']['price'] != null
              ? (item['products']['price'] as num).toDouble()
              : null,
          image: item['products'] != null ? item['products']['image'] : null,
          size: item['products'] != null && item['products']['size'] != null
              ? (item['products']['size'] as num).toDouble()
              : null,
          unit: item['products'] != null ? item['products']['unit'] : null,
        );
      }).toList();
    } catch (e) {
      print('Erreur lors de la récupération des produits: $e');
      return [];
    }
  }
}
