import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/video.dart';

class VideosService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<List<Video>> getShortVideos({int limit = 20}) async {
    try {
      // Essayer d'abord avec la vue, sinon utiliser la table directement
      var response;
      try {
        response = await supabase
            .from('videos_with_user_likes')
            .select('*')
            .eq('is_short', true)
            .eq('is_published', true)
            .order('created_at', ascending: false)
            .limit(limit);
      } catch (e) {
        // Si la vue n'existe pas, utiliser la table directe
        print('Vue non disponible, utilisation de la table directe: $e');
        response = await supabase
            .from('active_videos')
            .select('*')
            .eq('is_short', true)
            .eq('is_published', true)
            .order('created_at', ascending: false)
            .limit(limit);
      }

      return response.map<Video>((json) => Video.fromJson(json)).toList();
    } catch (e) {
      print('Erreur lors de la récupération des shorts: $e');
      throw Exception('Impossible de charger les vidéos courtes');
    }
  }

  Future<Video?> getVideoById(String videoId) async {
    try {
      var response;
      try {
        response = await supabase
            .from('videos_with_user_likes')
            .select('*')
            .eq('id', videoId)
            .maybeSingle();
      } catch (e) {
        // Si la vue n'existe pas, utiliser la table directe
        response = await supabase
            .from('active_videos')
            .select('*')
            .eq('id', videoId)
            .maybeSingle();
      }

      if (response == null) return null;

      return Video.fromJson(response);
    } catch (e) {
      print('Erreur lors de la récupération de la vidéo: $e');
      throw Exception('Impossible de charger la vidéo');
    }
  }

  Future<void> incrementViews(String videoId) async {
    try {
      await supabase
          .rpc('increment_video_views', params: {'video_id': videoId});
    } catch (e) {
      print('Erreur lors de l\'incrémentation des vues: $e');
      // Ne pas lancer d'exception pour les vues
    }
  }

  Future<void> likeVideo(String videoId) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Utilisateur non connecté');

      // Insérer le like
      await supabase.from('video_likes').insert({
        'user_id': userId,
        'video_id': videoId,
      });

      // Incrémenter le compteur
      await supabase
          .rpc('increment_video_likes', params: {'video_id': videoId});
    } catch (e) {
      print('Erreur lors du like: $e');
      throw Exception('Impossible de liker la vidéo');
    }
  }

  Future<void> unlikeVideo(String videoId) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Utilisateur non connecté');

      // Supprimer le like
      await supabase
          .from('video_likes')
          .delete()
          .eq('user_id', userId)
          .eq('video_id', videoId);

      // Décrémenter le compteur
      await supabase
          .rpc('decrement_video_likes', params: {'video_id': videoId});
    } catch (e) {
      print('Erreur lors du unlike: $e');
      throw Exception('Impossible de retirer le like');
    }
  }

  Future<int> getCommentsCount(String videoId) async {
    try {
      final result = await supabase
          .rpc('get_video_comments_count', params: {'video_id': videoId});
      return result as int;
    } catch (e) {
      print('Erreur lors de la récupération du nombre de commentaires: $e');
      return 0;
    }
  }

  Future<List<Video>> getVideos({
    String? category,
    bool? isPublished,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var query = supabase.from('videos_with_user_likes').select('*');

      if (category != null) {
        query = query.eq('category', category);
      }

      if (isPublished != null) {
        query = query.eq('is_published', isPublished);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map<Video>((json) => Video.fromJson(json)).toList();
    } catch (e) {
      print('Erreur lors de la récupération des vidéos: $e');
      throw Exception('Impossible de charger les vidéos');
    }
  }

  Future<List<Video>> searchVideos(String query) async {
    try {
      final response = await supabase
          .from('videos_with_user_likes')
          .select('*')
          .or('title.ilike.%$query%,description.ilike.%$query%')
          .eq('is_published', true)
          .order('created_at', ascending: false);

      return response.map<Video>((json) => Video.fromJson(json)).toList();
    } catch (e) {
      print('Erreur lors de la recherche de vidéos: $e');
      throw Exception('Impossible de rechercher les vidéos');
    }
  }
}
