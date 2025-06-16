import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cart_item.dart';
import '../../main.dart';

class SubcartService {
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

  Future<Map<String, dynamic>> getSubcartDetails(String subcartId) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Utilisateur non connecté');

      final response = await supabase
          .from('subcarts')
          .select('id, name, description, recipe_id, servings, source_type, updated_at')
          .eq('id', subcartId)
          .eq('user_id', userId)
          .filter('deleted_at', 'is', null)
          .single();

      return response;
    } catch (e) {
      print('Erreur lors de la récupération des détails du sous-panier: $e');
      throw Exception('Impossible de charger les détails du sous-panier');
    }
  }

  Future<List<CartItem>> getSubcartItems(String subcartId) async {
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
          .eq('subcart_id', subcartId)
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
          subcartId: subcartId,
        );
      }).toList();
    } catch (e) {
      print('Erreur lors de la récupération des articles du sous-panier: $e');
      throw Exception('Impossible de charger les articles du sous-panier');
    }
  }

  Future<void> updateSubcartItemQuantity({
    required String cartItemId,
    required int quantity,
  }) async {
    try {
      if (quantity <= 0) {
        await removeFromSubcart(cartItemId: cartItemId);
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

  Future<void> removeFromSubcart({required String cartItemId}) async {
    try {
      await supabase.from('cart_items').delete().eq('id', cartItemId);
    } catch (e) {
      print('Erreur lors de la suppression de l\'article: $e');
      throw Exception('Impossible de supprimer l\'article');
    }
  }

  Future<void> deleteSubcart(String subcartId) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Utilisateur non connecté');

      // Soft delete du sous-panier
      await supabase.from('subcarts').update({
        'deleted_at': DateTime.now().toIso8601String(),
      }).eq('id', subcartId).eq('user_id', userId);

      // Supprimer tous les articles du sous-panier
      await supabase
          .from('cart_items')
          .delete()
          .eq('subcart_id', subcartId)
          .eq('user_id', userId);
    } catch (e) {
      print('Erreur lors de la suppression du sous-panier: $e');
      throw Exception('Impossible de supprimer le sous-panier');
    }
  }

  Future<void> renameSubcart({
    required String subcartId,
    required String name,
    String? description,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Utilisateur non connecté');

      final updateData = {
        'name': name,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (description != null) {
        updateData['description'] = description;
      }

      await supabase
          .from('subcarts')
          .update(updateData)
          .eq('id', subcartId)
          .eq('user_id', userId);
    } catch (e) {
      print('Erreur lors du renommage du sous-panier: $e');
      throw Exception('Impossible de renommer le sous-panier');
    }
  }

  Future<void> moveAllToMainCart(String subcartId) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Utilisateur non connecté');

      // Récupérer tous les articles du sous-panier
      final items = await getSubcartItems(subcartId);

      // Pour chaque article
      for (final item in items) {
        // Vérifier si le produit existe déjà dans le panier principal
        final existingItem = await supabase
            .from('cart_items')
            .select()
            .eq('user_id', userId)
            .eq('product_id', item.productId)
            .filter('subcart_id', 'is', null)
            .maybeSingle();

        if (existingItem != null) {
          final existingQuantity = _safeToInt(existingItem['quantity']);

          // Mettre à jour la quantité dans le panier principal
          await supabase.from('cart_items').update({
            'quantity': existingQuantity + item.quantity,
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', existingItem['id']);
        } else {
          // Ajouter un nouvel élément au panier principal
          await supabase.from('cart_items').insert({
            'user_id': userId,
            'product_id': item.productId,
            'quantity': item.quantity,
            'updated_at': DateTime.now().toIso8601String(),
          });
        }
      }

      // Supprimer tous les articles du sous-panier
      await supabase
          .from('cart_items')
          .delete()
          .eq('subcart_id', subcartId)
          .eq('user_id', userId);

      // Marquer le sous-panier comme supprimé (soft delete)
      await supabase.from('subcarts').update({
        'deleted_at': DateTime.now().toIso8601String(),
      }).eq('id', subcartId).eq('user_id', userId);
    } catch (e) {
      print('Erreur lors du déplacement des articles vers le panier principal: $e');
      throw Exception('Impossible de déplacer les articles vers le panier principal');
    }
  }

  Future<void> addToSubcart({
    required String subcartId,
    required String productId,
    required int quantity,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Utilisateur non connecté');

      // Vérifier si le produit est déjà dans le sous-panier
      final existingItem = await supabase
          .from('cart_items')
          .select()
          .eq('user_id', userId)
          .eq('product_id', productId)
          .eq('subcart_id', subcartId)
          .maybeSingle();

      if (existingItem != null) {
        final existingQuantity = _safeToInt(existingItem['quantity']);
        
        // Mettre à jour la quantité
        await supabase.from('cart_items').update({
          'quantity': existingQuantity + quantity,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', existingItem['id']);
      } else {
        // Ajouter un nouvel élément au sous-panier
        await supabase.from('cart_items').insert({
          'user_id': userId,
          'product_id': productId,
          'quantity': quantity,
          'subcart_id': subcartId,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Erreur lors de l\'ajout au sous-panier: $e');
      throw Exception('Impossible d\'ajouter au sous-panier');
    }
  }

  Future<void> moveToMainCart({
    required String cartItemId,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Utilisateur non connecté');

      // Récupérer les détails de l'article
      final cartItem = await supabase
          .from('cart_items')
          .select('product_id, quantity')
          .eq('id', cartItemId)
          .eq('user_id', userId)
          .single();

      // Vérifier si le produit est déjà dans le panier principal
      final existingItem = await supabase
          .from('cart_items')
          .select()
          .eq('user_id', userId)
          .eq('product_id', cartItem['product_id'])
          .filter('subcart_id', 'is', null)
          .maybeSingle();

      if (existingItem != null) {
        final existingQuantity = _safeToInt(existingItem['quantity']);
        final itemQuantity = _safeToInt(cartItem['quantity']);
        
        // Mettre à jour la quantité dans le panier principal
        await supabase.from('cart_items').update({
          'quantity': existingQuantity + itemQuantity,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', existingItem['id']);

        // Supprimer l'article du sous-panier
        await removeFromSubcart(cartItemId: cartItemId);
      } else {
        // Déplacer l'article vers le panier principal
        await supabase.from('cart_items').update({
          'subcart_id': null,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', cartItemId);
      }
    } catch (e) {
      print('Erreur lors du déplacement vers le panier principal: $e');
      throw Exception('Impossible de déplacer vers le panier principal');
    }
  }
}
