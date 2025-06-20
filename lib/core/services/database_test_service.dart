import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseTestService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<void> testConnection() async {
    try {
      print('🔗 Test de connexion à Supabase...');

      // Test simple de connexion
      final response = await supabase
          .from('active_videos')
          .select('id, title, thumbnail_url, is_short')
          .limit(5);

      print('✅ Connexion réussie !');
      print('📊 Nombre de vidéos trouvées: ${response.length}');

      if (response.isNotEmpty) {
        print('📹 Première vidéo:');
        final firstVideo = response.first;
        firstVideo.forEach((key, value) {
          print('  $key: $value');
        });
      }
    } catch (e) {
      print('❌ Erreur de connexion: $e');

      // Test avec une table plus basique
      try {
        print('🔄 Test avec la table recipes...');
        final recipesTest =
            await supabase.from('recipes').select('id, title').limit(1);
        print('✅ Table recipes accessible: ${recipesTest.length} résultats');
      } catch (e2) {
        print('❌ Erreur avec recipes aussi: $e2');
      }
    }
  }

  Future<List<Map<String, dynamic>>> getAvailableTables() async {
    try {
      // Cette requête peut ne pas fonctionner selon les permissions
      final result = await supabase.rpc('get_table_names');
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      print('⚠️ Impossible de lister les tables: $e');
      return [];
    }
  }
}
