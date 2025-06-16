import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import '../../main.dart';

class ProductsService {
  // Utiliser la vue active_products ou la table products avec filtre
  static const String _tableName = 'active_products';
  static const String _fallbackTableName = 'products';

  Future<Product?> getProductById(String productId) async {
    try {
      // Essayer d'abord avec active_products, sinon fallback vers products
      final response = await _executeQuery(() => supabase
          .from(_tableName)
          .select('*')
          .eq('id', productId)
          .maybeSingle());

      if (response == null) return null;

      return Product.fromJson(response);
    } catch (e) {
      print('Erreur lors de la récupération du produit: $e');
      throw Exception('Impossible de charger le produit');
    }
  }

  Future<List<Product>> getProducts({
    String? category,
    bool? inStock,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var query = supabase.from(_tableName).select('*');

      if (category != null) {
        query = query.eq('category_id', category);
      }

      if (inStock != null && inStock) {
        query = query.gt('stock', 0);
      } else if (inStock != null && !inStock) {
        query = query.eq('stock', 0);
      }

      final response = await _executeQuery(() => query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1));

      return response.map<Product>((json) => Product.fromJson(json)).toList();
    } catch (e) {
      print('Erreur lors de la récupération des produits: $e');
      throw Exception('Impossible de charger les produits');
    }
  }

  Future<List<Product>> searchProducts(String query) async {
    try {
      final response = await _executeQuery(() => supabase
          .from(_tableName)
          .select('*')
          .or('name.ilike.%$query%,description.ilike.%$query%')
          .order('created_at', ascending: false));

      return response.map<Product>((json) => Product.fromJson(json)).toList();
    } catch (e) {
      print('Erreur lors de la recherche de produits: $e');
      throw Exception('Impossible de rechercher les produits');
    }
  }

  Future<List<Product>> getProductsByCategory(String categoryId) async {
    try {
      final response = await _executeQuery(() => supabase
          .from(_tableName)
          .select('*')
          .eq('category_id', categoryId)
          .order('created_at', ascending: false));

      return response.map<Product>((json) => Product.fromJson(json)).toList();
    } catch (e) {
      print('Erreur lors de la récupération des produits par catégorie: $e');
      throw Exception('Impossible de charger les produits de cette catégorie');
    }
  }

  Future<List<Product>> getFeaturedProducts({int limit = 10}) async {
    try {
      final response = await _executeQuery(() => supabase
          .from(_tableName)
          .select('*')
          .eq('is_new', true)
          .gt('stock', 0)
          .order('created_at', ascending: false)
          .limit(limit));

      return response.map<Product>((json) => Product.fromJson(json)).toList();
    } catch (e) {
      print('Erreur lors de la récupération des produits vedettes: $e');
      throw Exception('Impossible de charger les produits vedettes');
    }
  }

  /// Méthode utilitaire pour exécuter une requête avec fallback automatique
  Future<T> _executeQuery<T>(Future<T> Function() queryFunction) async {
    try {
      return await queryFunction();
    } on PostgrestException catch (e) {
      // Si la vue active_products n'existe pas, utiliser la table products avec filtre
      if (e.code == '42P01' || e.message.contains('does not exist')) {
        print('Vue active_products non trouvée, utilisation de la table products avec filtre deleted_at IS NULL');
        return await _executeWithFallback<T>();
      }
      rethrow;
    }
  }

  /// Fallback vers la table products avec filtre deleted_at IS NULL
  Future<T> _executeWithFallback<T>() async {
    // Pour l'instant, on relance l'exception car il faut créer la vue
    throw Exception('La vue active_products doit être créée. Exécutez le script SQL correspondant.');
  }
}
