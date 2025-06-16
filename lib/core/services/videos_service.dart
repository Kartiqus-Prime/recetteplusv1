import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/video.dart';
import '../../main.dart';

class VideosService {
  Future<Video?> getVideoById(String videoId) async {
    try {
      final response = await supabase
          .from('active_videos')
          .select('*')
          .eq('id', videoId)
          .maybeSingle();

      if (response == null) return null;

      return Video.fromJson(response);
    } catch (e) {
      print('Erreur lors de la récupération de la vidéo: $e');
      throw Exception('Impossible de charger la vidéo');
    }
  }

  Future<List<Video>> getVideos({
    String? category,
    bool? isPublished,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var query = supabase
          .from('active_videos')
          .select('*');

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
          .from('active_videos')
          .select('*')
          .or('title.ilike.%$query%,description.ilike.%$query%')
          .order('created_at', ascending: false);

      return response.map<Video>((json) => Video.fromJson(json)).toList();
    } catch (e) {
      print('Erreur lors de la recherche de vidéos: $e');
      throw Exception('Impossible de rechercher les vidéos');
    }
  }
}
