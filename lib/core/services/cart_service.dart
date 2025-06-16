import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cart_item.dart';
import '../../main.dart';

class CartService {
  // Méthode utilitaire pour convertir de manière sécurisée en int
  int _safeToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // Méthode utilitaire pour convertir de manière sécurisée en double
  double? _safeToDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Future<List<CartItem>> getCartItems() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Utilisateur non connecté');

      final response = await supabase
          .from('cart_items')
          .select('''
           id,
           user_id,
           product_id,
           quantity,
           updated_at,
           products(
             id,
             name,
             description,
             price,
             image,
             size,
             unit
           )
         ''')
          .eq('user_id', userId)
          .filter('subcart_id', 'is', null)
          .order('updated_at', ascending: false);

      return response.map<CartItem>((json) {
        final product = json['products'];
        final updatedAt = DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String());
        
        return CartItem(
          id: json['id'],
          userId: json['user_id'],
          productId: json['product_id'],
          quantity: _safeToInt(json['quantity']), // Conversion sécurisée
          createdAt: updatedAt,
          updatedAt: updatedAt,
          productName: product['name'],
          productDescription: product['description'],
          productPrice: _safeToDouble(product['price']),
          productImage: product['image'],
          productSize: _safeToDouble(product['size']),
          productUnit: product['unit'],
        );
      }).toList();
    } catch (e) {
      print('Erreur lors de la récupération du panier: $e');
      print('Stack trace: ${StackTrace.current}');
      throw Exception('Impossible de charger le panier');
    }
  }

  Future<void> addToCart(
      {required String productId, required int quantity}) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Utilisateur non connecté');

      // Vérifier si le produit est déjà dans le panier
      final existingItem = await supabase
          .from('cart_items')
          .select()
          .eq('user_id', userId)
          .eq('product_id', productId)
          .filter('subcart_id', 'is', null)
          .maybeSingle();

      if (existingItem != null) {
        final existingQuantity = _safeToInt(existingItem['quantity']);
        
        // Mettre à jour la quantité
        await supabase.from('cart_items').update({
          'quantity': existingQuantity + quantity,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', existingItem['id']);
      } else {
        // Ajouter un nouvel élément au panier
        await supabase.from('cart_items').insert({
          'user_id': userId,
          'product_id': productId,
          'quantity': quantity,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Erreur lors de l\'ajout au panier: $e');
      throw Exception('Impossible d\'ajouter au panier');
    }
  }

  Future<void> updateCartItemQuantity(
      {required String cartItemId, required int quantity}) async {
    try {
      if (quantity <= 0) {
        await removeFromCart(cartItemId: cartItemId);
        return;
      }

      await supabase.from('cart_items').update({
        'quantity': quantity,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', cartItemId);
    } catch (e) {
      print('Erreur lors de la mise à jour de la quantité: $e');
      throw Exception('Impossible de mettre à jour la quantité');
    }
  }

  Future<void> removeFromCart({required String cartItemId}) async {
    try {
      await supabase.from('cart_items').delete().eq('id', cartItemId);
    } catch (e) {
      print('Erreur lors de la suppression du panier: $e');
      throw Exception('Impossible de supprimer du panier');
    }
  }

  Future<void> clearCart() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Utilisateur non connecté');

      await supabase
          .from('cart_items')
          .delete()
          .eq('user_id', userId)
          .filter('subcart_id', 'is', null);
    } catch (e) {
      print('Erreur lors de la suppression du panier: $e');
      throw Exception('Impossible de vider le panier');
    }
  }

  Future<int> getCartItemCount() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final response = await supabase
          .from('cart_items')
          .select('quantity')
          .eq('user_id', userId)
          .filter('subcart_id', 'is', null);

      int count = 0;
      for (var item in response) {
        count += _safeToInt(item['quantity']); // Conversion sécurisée
      }
      return count;
    } catch (e) {
      print('Erreur lors du comptage des articles du panier: $e');
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getSubcarts() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Utilisateur non connecté');

      final response = await supabase
          .from('subcarts')
          .select('id, name, description, recipe_id, servings, source_type, updated_at')
          .eq('user_id', userId)
          .filter('deleted_at', 'is', null)
          .order('updated_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Erreur lors de la récupération des sous-paniers: $e');
      throw Exception('Impossible de charger les sous-paniers');
    }
  }

  Future<String> createSubcartFromRecipe({
    required String recipeName,
    required String recipeId,
    required int servings,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Utilisateur non connecté');

      final now = DateTime.now().toIso8601String();
      
      final response = await supabase
          .from('subcarts')
          .insert({
            'user_id': userId,
            'name': 'Recette: $recipeName',
            'description': 'Ingrédients pour $servings personne(s)',
            'source_type': 'recipe',
            'source_id': recipeId,
            'recipe_id': recipeId,
            'servings': servings,
            'updated_at': now,
          })
          .select('id')
          .single();

      return response['id'];
    } catch (e) {
      print('Erreur lors de la création du sous-panier: $e');
      throw Exception('Impossible de créer le sous-panier');
    }
  }

  Future<void> addRecipeIngredientsToSubcart({
    required String recipeId,
    required String subcartId,
    required List<Map<String, dynamic>> ingredients,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Utilisateur non connecté');

      final now = DateTime.now().toIso8601String();
      
      // Préparer les données pour l'insertion en batch
      final cartItems = ingredients
          .map((ingredient) {
            if (ingredient['product_id'] == null) return null;

            return {
              'user_id': userId,
              'product_id': ingredient['product_id'],
              'quantity': _safeToInt(ingredient['quantity']), // Conversion sécurisée
              'subcart_id': subcartId,
              'updated_at': now,
            };
          })
          .where((item) => item != null)
          .toList();

      if (cartItems.isEmpty) return;

      // Insérer tous les ingrédients en une seule requête
      await supabase.from('cart_items').insert(cartItems);
    } catch (e) {
      print('Erreur lors de l\'ajout des ingrédients au sous-panier: $e');
      throw Exception('Impossible d\'ajouter les ingrédients au sous-panier');
    }
  }
}
