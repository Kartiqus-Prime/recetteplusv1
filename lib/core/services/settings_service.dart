import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_preference.dart';
import '../../main.dart';

class SettingsService {
  static const String _themeKey = 'app_theme';

  // Méthodes pour le thème
  Future<String> getTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_themeKey) ?? 'light';
    } catch (e) {
      return 'light';
    }
  }

  Future<bool> updateTheme(String theme) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, theme);
      
      // Optionnel : sauvegarder aussi dans Supabase
      final user = supabase.auth.currentUser;
      if (user != null) {
        await supabase
            .from('user_profiles')
            .update({
              'preferences': {
                'theme': theme,
              },
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', user.id);
            
        // Enregistrer l'activité
        await supabase.from('user_activity_log').insert({
          'user_id': user.id,
          'activity_type': 'settings_update',
          'entity_type': 'user_preferences',
          'entity_id': user.id,
          'metadata': {
            'setting': 'theme',
            'value': theme,
          },
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      
      return true;
    } catch (e) {
      print('Erreur lors de la mise à jour du thème: $e');
      return false;
    }
  }

  // Méthodes pour les préférences de notification
  Future<List<NotificationPreference>> getNotificationPreferences() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return [];

      final response = await supabase
          .from('notification_preferences')
          .select()
          .eq('user_id', user.id)
          .isFilter('deleted_at', null);

      return (response as List)
          .map((item) => NotificationPreference.fromJson(item))
          .toList();
    } catch (e) {
      print('Erreur lors du chargement des préférences de notification: $e');
      return [];
    }
  }

  Future<bool> updateNotificationPreference(String type, bool enabled) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return false;

      // Vérifier si la préférence existe déjà
      final existing = await supabase
          .from('notification_preferences')
          .select()
          .eq('user_id', user.id)
          .eq('type', type)
          .isFilter('deleted_at', null)
          .maybeSingle();

      if (existing != null) {
        // Mettre à jour
        await supabase
            .from('notification_preferences')
            .update({
              'enabled': enabled,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existing['id']);
      } else {
        // Créer
        await supabase
            .from('notification_preferences')
            .insert({
              'user_id': user.id,
              'type': type,
              'enabled': enabled,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
      }
      
      // Enregistrer l'activité
      await supabase.from('user_activity_log').insert({
        'user_id': user.id,
        'activity_type': 'settings_update',
        'entity_type': 'notification_preferences',
        'entity_id': type,
        'metadata': {
          'setting': 'notification',
          'type': type,
          'enabled': enabled,
        },
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('Erreur lors de la mise à jour de la préférence de notification: $e');
      return false;
    }
  }

  // Méthode pour vider le cache
  Future<bool> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Garder les préférences importantes mais supprimer le cache
      final theme = prefs.getString(_themeKey);
      
      await prefs.clear();
      
      // Restaurer les préférences importantes
      if (theme != null) await prefs.setString(_themeKey, theme);
      
      // Enregistrer l'activité
      final user = supabase.auth.currentUser;
      if (user != null) {
        await supabase.from('user_activity_log').insert({
          'user_id': user.id,
          'activity_type': 'cache_clear',
          'entity_type': 'app_cache',
          'entity_id': user.id,
          'metadata': {
            'action': 'clear_cache',
          },
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      
      return true;
    } catch (e) {
      print('Erreur lors du vidage du cache: $e');
      return false;
    }
  }

  // Méthode pour supprimer le compte
  Future<bool> deleteAccount() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return false;

      // Enregistrer l'activité de suppression de compte
      await supabase.from('user_activity_log').insert({
        'user_id': user.id,
        'activity_type': 'account_deletion',
        'entity_type': 'user_account',
        'entity_id': user.id,
        'metadata': {
          'action': 'delete_account',
        },
        'created_at': DateTime.now().toIso8601String(),
      });

      // Supprimer dans l'ordre pour respecter les contraintes de clés étrangères
      
      // 1. Soft delete des préférences de notification
      await supabase
          .from('notification_preferences')
          .update({
            'deleted_at': DateTime.now().toIso8601String(),
            'deleted_by': user.id,
          })
          .eq('user_id', user.id);

      // 2. Soft delete des favoris
      await supabase
          .from('favorites')
          .update({
            'deleted_at': DateTime.now().toIso8601String(),
            'deleted_by': user.id,
          })
          .eq('user_id', user.id);

      // 3. Soft delete des éléments du panier
      await supabase
          .from('cart_items')
          .update({
            'deleted_at': DateTime.now().toIso8601String(),
            'deleted_by': user.id,
          })
          .eq('user_id', user.id);

      // 4. Soft delete des sous-paniers
      await supabase
          .from('subcarts')
          .update({
            'deleted_at': DateTime.now().toIso8601String(),
            'deleted_by': user.id,
          })
          .eq('user_id', user.id);

      // 5. Soft delete du profil utilisateur
      await supabase
          .from('user_profiles')
          .update({
            'deleted_at': DateTime.now().toIso8601String(),
            'deleted_by': user.id,
          })
          .eq('user_id', user.id);

      // 6. Supprimer le compte utilisateur (Auth)
      await supabase.auth.admin.deleteUser(user.id);

      // 7. Vider les préférences locales
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      return true;
    } catch (e) {
      print('Erreur lors de la suppression du compte: $e');
      return false;
    }
  }
}
