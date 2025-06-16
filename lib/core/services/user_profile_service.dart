import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class UserProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<UserProfile?> getCurrentUserProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        // Créer un profil par défaut si aucun n'existe
        return await _createDefaultProfile(userId);
      }

      return UserProfile.fromJson(response);
    } catch (e) {
      print('Erreur lors de la récupération du profil: $e');
      return null;
    }
  }

  Future<UserProfile?> _createDefaultProfile(String userId) async {
    try {
      final user = _supabase.auth.currentUser;
      final defaultProfile = {
        'user_id': userId,
        'display_name': user?.userMetadata?['display_name'] ?? 
                       user?.email?.split('@')[0] ?? 
                       'Utilisateur',
        'phone': user?.phone ?? '',
        'bio': '',
        'avatar_url': user?.userMetadata?['avatar_url'] ?? '',
        'phone_verified': user?.phoneConfirmedAt != null,
        'preferences': {
          'theme': 'light',
          'notifications': true,
          'language': 'fr',
          'currency': 'fcfa'
        },
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('user_profiles')
          .insert(defaultProfile)
          .select()
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      print('Erreur lors de la création du profil par défaut: $e');
      return null;
    }
  }

  Future<UserProfile?> updateProfile({
    String? displayName,
    String? phone,
    String? bio,
    String? avatarUrl,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Utilisateur non connecté');

      // Vérifier si le profil existe déjà
      final existingProfile = await _supabase
          .from('user_profiles')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (displayName != null) updates['display_name'] = displayName.trim();
      if (phone != null) updates['phone'] = phone.trim();
      if (bio != null) updates['bio'] = bio.trim();
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (preferences != null) updates['preferences'] = preferences;

      // Si le profil existe, utiliser update au lieu de upsert
      if (existingProfile != null) {
        final response = await _supabase
            .from('user_profiles')
            .update(updates)
            .eq('user_id', userId)
            .select()
            .single();
        
        return UserProfile.fromJson(response);
      } else {
        // Si le profil n'existe pas, créer un nouveau
        updates['user_id'] = userId;
        updates['created_at'] = DateTime.now().toIso8601String();
        
        final response = await _supabase
            .from('user_profiles')
            .insert(updates)
            .select()
            .single();
            
        return UserProfile.fromJson(response);
      }
    } catch (e) {
      print('Erreur lors de la mise à jour du profil: $e');
      rethrow;
    }
  }

  Future<bool> validateProfileData({
    String? displayName,
    String? phone,
    String? bio,
  }) async {
    // Validation du nom d'affichage
    if (displayName != null && displayName.trim().isEmpty) {
      throw Exception('Le nom d\'affichage ne peut pas être vide');
    }

    // Validation du téléphone (format malien)
    if (phone != null && phone.trim().isNotEmpty) {
      final phoneRegex = RegExp(r'^\+223[0-9]{8}$|^[0-9]{8}$');
      if (!phoneRegex.hasMatch(phone.trim())) {
        throw Exception('Format de téléphone invalide (ex: +223XXXXXXXX ou XXXXXXXX)');
      }
    }

    // Validation de la bio (longueur maximale)
    if (bio != null && bio.trim().length > 500) {
      throw Exception('La biographie ne peut pas dépasser 500 caractères');
    }

    return true;
  }

  Future<bool> addToFavorites(String itemId, {String? itemType}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final favoriteData = {
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      };

      // Déterminer le type d'élément à ajouter aux favoris
      if (itemType == 'recipe') {
        favoriteData['recipe_id'] = itemId;
      } else if (itemType == 'product') {
        favoriteData['product_id'] = itemId;
      } else if (itemType == 'video') {
        favoriteData['video_id'] = itemId;
      } else {
        // Par défaut, considérer comme un produit
        favoriteData['product_id'] = itemId;
      }

      await _supabase.from('favorites').insert(favoriteData);
      return true;
    } catch (e) {
      print('Erreur lors de l\'ajout aux favoris: $e');
      return false;
    }
  }

  Future<bool> removeFromFavorites(String itemId, {String? itemType}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      var query = _supabase.from('favorites').delete().eq('user_id', userId);

      if (itemType == 'recipe') {
        query = query.eq('recipe_id', itemId);
      } else if (itemType == 'product') {
        query = query.eq('product_id', itemId);
      } else if (itemType == 'video') {
        query = query.eq('video_id', itemId);
      } else {
        query = query.eq('product_id', itemId);
      }

      await query;
      return true;
    } catch (e) {
      print('Erreur lors de la suppression des favoris: $e');
      return false;
    }
  }
}
