import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/favorite.dart';
import '../../main.dart';

class FavoritesService {
  Future<List<Favorite>> getUserFavorites() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        print('FavoritesService: Utilisateur non connecté');
        throw Exception('Utilisateur non connecté');
      }

      print('FavoritesService: Récupération des favoris pour user_id: $userId');

      // D'abord, récupérer les favoris de base
      final favoritesResponse = await supabase
          .from('favorites')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      print(
          'FavoritesService: Favoris bruts récupérés: ${favoritesResponse.length}');

      List<Favorite> favorites = [];

      for (var favoriteJson in favoritesResponse) {
        print('FavoritesService: Traitement du favori: $favoriteJson');

        String? itemName;
        String? itemImage;
        String? itemDescription;
        double? itemPrice;

        // Si c'est un produit
        if (favoriteJson['product_id'] != null) {
          try {
            final productResponse = await supabase
                .from('products')
                .select('name, image, description, price')
                .eq('id', favoriteJson['product_id'])
                .maybeSingle();

            if (productResponse != null) {
              itemName = productResponse['name'];
              itemImage = productResponse['image'];
              itemDescription = productResponse['description'];
              itemPrice = productResponse['price']?.toDouble();
            }
          } catch (e) {
            print(
                'FavoritesService: Erreur lors de la récupération du produit: $e');
          }
        }

        // Si c'est une recette
        else if (favoriteJson['recipe_id'] != null) {
          try {
            final recipeResponse = await supabase
                .from('recipes')
                .select('title, image, description, estimated_cost')
                .eq('id', favoriteJson['recipe_id'])
                .maybeSingle();

            if (recipeResponse != null) {
              itemName = recipeResponse['title'];
              itemImage = recipeResponse['image'];
              itemDescription = recipeResponse['description'];
              itemPrice = recipeResponse['estimated_cost']?.toDouble();
            }
          } catch (e) {
            print(
                'FavoritesService: Erreur lors de la récupération de la recette: $e');
          }
        }

        // Si c'est une vidéo
        else if (favoriteJson['video_id'] != null) {
          try {
            final videoResponse = await supabase
                .from('videos')
                .select('title, thumbnail_url, description')
                .eq('id', favoriteJson['video_id'])
                .maybeSingle();

            if (videoResponse != null) {
              itemName = videoResponse['title'];
              itemImage = videoResponse['thumbnail_url'];
              itemDescription = videoResponse['description'];
            }
          } catch (e) {
            print(
                'FavoritesService: Erreur lors de la récupération de la vidéo: $e');
          }
        }

        favorites.add(Favorite(
          id: favoriteJson['id'],
          userId: favoriteJson['user_id'],
          productId: favoriteJson['product_id'],
          recipeId: favoriteJson['recipe_id'],
          videoId: favoriteJson['video_id'],
          createdAt: DateTime.parse(favoriteJson['created_at']),
          itemName: itemName,
          itemImage: itemImage,
          itemDescription: itemDescription,
          itemPrice: itemPrice,
        ));
      }

      print('FavoritesService: Favoris traités: ${favorites.length}');
      return favorites;
    } catch (e) {
      print('FavoritesService: Erreur lors de la récupération des favoris: $e');
      throw Exception('Impossible de charger les favoris');
    }
  }

  Future<void> removeFavorite(String favoriteId) async {
    try {
      await supabase.from('favorites').delete().eq('id', favoriteId);
    } catch (e) {
      print('Erreur lors de la suppression du favori: $e');
      throw Exception('Impossible de supprimer le favori');
    }
  }

  Future<bool> toggleFavorite({
    String? productId,
    String? recipeId,
    String? videoId,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Utilisateur non connecté');

      // Construire la requête de base
      var query = supabase
          .from('favorites')
          .select('id')
          .eq('user_id', userId)
          .filter('deleted_at', 'is', null);

      // Ajouter les filtres selon le type
      if (productId != null) {
        query = query.eq('product_id', productId);
      } else {
        query = query.filter('product_id', 'is', null);
      }

      if (recipeId != null) {
        query = query.eq('recipe_id', recipeId);
      } else {
        query = query.filter('recipe_id', 'is', null);
      }

      if (videoId != null) {
        query = query.eq('video_id', videoId);
      } else {
        query = query.filter('video_id', 'is', null);
      }

      final existingFavorite = await query.maybeSingle();

      if (existingFavorite != null) {
        // Supprimer des favoris
        await supabase
            .from('favorites')
            .delete()
            .eq('id', existingFavorite['id']);
        return false;
      } else {
        // Ajouter aux favoris
        await supabase.from('favorites').insert({
          'user_id': userId,
          'product_id': productId,
          'recipe_id': recipeId,
          'video_id': videoId,
        });
        return true;
      }
    } catch (e) {
      print('Erreur lors de la gestion du favori: $e');
      throw Exception('Impossible de modifier le favori');
    }
  }

  Future<bool> isFavorite({
    String? productId,
    String? recipeId,
    String? videoId,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Construire la requête de base
      var query = supabase
          .from('favorites')
          .select('id')
          .eq('user_id', userId);

      // Ajouter les filtres selon le type
      if (productId != null) {
        query = query.eq('product_id', productId);
      } else if (recipeId != null) {
        query = query.eq('recipe_id', recipeId);
      } else if (videoId != null) {
        query = query.eq('video_id', videoId);
      } else {
        return false;
      }

      final existingFavorite = await query.maybeSingle();
      return existingFavorite != null;
    } catch (e) {
      print('Erreur lors de la vérification des favoris: $e');
      return false;
    }
  }

  Future<List<String>> getUserFavoriteRecipeIds() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await supabase
          .from('favorites')
          .select('recipe_id')
          .eq('user_id', userId)
          .not('recipe_id', 'is', null);

      return response.map<String>((item) => item['recipe_id'] as String).toList();
    } catch (e) {
      print('Erreur lors de la récupération des IDs de recettes favorites: $e');
      return [];
    }
  }
}
