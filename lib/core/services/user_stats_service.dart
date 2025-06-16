import 'package:supabase_flutter/supabase_flutter.dart';

class UserStatsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        print('UserStatsService: Utilisateur non connecté');
        return {
          'favorites_count': 0,
          'orders_count': 0,
          'recipes_count': 0,
        };
      }

      print('UserStatsService: Récupération des stats pour user_id: $userId');

      // Compter les favoris
      final favoritesResponse = await _supabase
          .from('favorites')
          .select('id')
          .eq('user_id', userId);
      
      final favoritesCount = favoritesResponse.length;
      print('UserStatsService: Favoris trouvés: $favoritesCount');

      // Compter les commandes
      final ordersResponse = await _supabase
          .from('orders')
          .select('id')
          .eq('user_id', userId);
      
      final ordersCount = ordersResponse.length;
      print('UserStatsService: Commandes trouvées: $ordersCount');

      // Compter les recettes favorites (celles qui ont recipe_id non null)
      final recipeFavoritesResponse = await _supabase
          .from('favorites')
          .select('id')
          .eq('user_id', userId)
          .not('recipe_id', 'is', null);
      
      final recipesCount = recipeFavoritesResponse.length;
      print('UserStatsService: Recettes favorites trouvées: $recipesCount');

      final stats = {
        'favorites_count': favoritesCount,
        'orders_count': ordersCount,
        'recipes_count': recipesCount,
      };

      print('UserStatsService: Stats finales: $stats');
      return stats;

    } catch (e) {
      print('UserStatsService: Erreur lors de la récupération des stats: $e');
      return {
        'favorites_count': 0,
        'orders_count': 0,
        'recipes_count': 0,
      };
    }
  }
}
