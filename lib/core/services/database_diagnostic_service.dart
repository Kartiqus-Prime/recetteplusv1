import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseDiagnosticService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> checkDatabaseStatus() async {
    final results = <String, dynamic>{};

    try {
      // Vérifier la table active_videos
      final videos =
          await supabase.from('active_videos').select('id').limit(10);

      results['active_videos_exists'] = true;
      results['videos_count'] = videos.length;
    } catch (e) {
      results['active_videos_exists'] = false;
      results['active_videos_error'] = e.toString();
    }

    try {
      // Vérifier la vue videos_with_user_likes
      await supabase.from('videos_with_user_likes').select('id').limit(1);

      results['videos_with_user_likes_exists'] = true;
    } catch (e) {
      results['videos_with_user_likes_exists'] = false;
      results['videos_with_user_likes_error'] = e.toString();
    }

    try {
      // Vérifier la table video_likes
      await supabase.from('video_likes').select('id').limit(1);

      results['video_likes_exists'] = true;
    } catch (e) {
      results['video_likes_exists'] = false;
      results['video_likes_error'] = e.toString();
    }

    try {
      // Vérifier les colonnes de active_videos
      final sample = await supabase.from('active_videos').select('*').limit(1);

      if (sample.isNotEmpty) {
        final columns = sample.first.keys.toList();
        results['active_videos_columns'] = columns;
        results['has_is_published'] = columns.contains('is_published');
        results['has_is_short'] = columns.contains('is_short');
        results['has_thumbnail_url'] = columns.contains('thumbnail_url');
      }
    } catch (e) {
      results['columns_check_error'] = e.toString();
    }

    return results;
  }

  Future<void> printDiagnostic() async {
    print('🔍 === DIAGNOSTIC BASE DE DONNÉES ===');
    final status = await checkDatabaseStatus();

    status.forEach((key, value) {
      print('$key: $value');
    });
    print('🔍 === FIN DIAGNOSTIC ===');
  }
}
