import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../main.dart';

class AuthService {
  // URL de callback pour la redirection depuis Supabase
  static const String callbackUrl = 'com.recetteplus.app://auth-callback/';
  
  static Future<bool> signInWithGoogle(BuildContext context) async {
    try {
      debugPrint('🔄 Début de la connexion Google...');
      
      // Récupérer le client ID depuis les variables d'environnement
      final googleClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'];
      
      if (googleClientId == null || googleClientId.isEmpty) {
        debugPrint('❌ GOOGLE_WEB_CLIENT_ID non défini dans .env');
        _showErrorDialog(context, 'Configuration manquante', 'GOOGLE_WEB_CLIENT_ID non défini dans le fichier .env');
        return false;
      }
      
      debugPrint('✅ Client ID Google trouvé: ${googleClientId.substring(0, 20)}...');

      // Initialiser GoogleSignIn avec le client ID
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        serverClientId: googleClientId,
      );
      
      debugPrint('🔄 Initialisation GoogleSignIn terminée');
      
      // Déconnecter l'utilisateur précédent si nécessaire
      await googleSignIn.signOut();
      debugPrint('🔄 Déconnexion précédente effectuée');
      
      // Déclencher le flux de connexion Google
      debugPrint('🔄 Ouverture du sélecteur de compte Google...');
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        debugPrint('⚠️ Connexion Google annulée par l\'utilisateur');
        return false;
      }
      
      debugPrint('✅ Utilisateur Google sélectionné: ${googleUser.email}');
      
      // Obtenir les détails d'authentification de la requête
      debugPrint('🔄 Récupération des tokens d\'authentification...');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      debugPrint('✅ Tokens récupérés:');
      debugPrint('  - ID Token: ${googleAuth.idToken != null ? "✅ Présent" : "❌ Absent"}');
      debugPrint('  - Access Token: ${googleAuth.accessToken != null ? "✅ Présent" : "❌ Absent"}');
      
      if (googleAuth.idToken == null) {
        debugPrint('❌ ID Token manquant');
        _showErrorDialog(context, 'Erreur d\'authentification', 'Impossible d\'obtenir le token d\'authentification Google');
        return false;
      }
      
      debugPrint('🔄 Connexion à Supabase avec les tokens Google...');
      
      // Connecter l'utilisateur à Supabase avec les informations d'identification Google
      final AuthResponse res = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );
      
      debugPrint('📊 Réponse Supabase:');
      debugPrint('  - Session: ${res.session != null ? "✅ Créée" : "❌ Nulle"}');
      debugPrint('  - User: ${res.user != null ? "✅ ${res.user!.email}" : "❌ Nul"}');
      
      if (res.session != null && res.user != null) {
        debugPrint('🎉 Connexion Supabase réussie pour ${res.user!.email}');
        return true;
      } else {
        debugPrint('❌ Échec de la connexion Supabase - Session ou User nul');
        _showErrorDialog(context, 'Erreur Supabase', 'Impossible de créer la session utilisateur');
        return false;
      }
    } on Exception catch (e) {
      debugPrint('💥 Exception lors de la connexion avec Google: $e');
      
      // Gestion spécifique des erreurs Google Sign In
      if (e.toString().contains('ApiException: 10:')) {
        _showErrorDialog(
          context, 
          'Erreur de configuration', 
          'Configuration Google incorrecte.\n\nVérifiez :\n• L\'empreinte SHA-1 dans Google Cloud Console\n• Le package name (com.recetteplus.app)\n• Le Client ID dans le fichier .env'
        );
      } else if (e.toString().contains('sign_in_failed')) {
        _showErrorDialog(
          context, 
          'Connexion échouée', 
          'La connexion Google a échoué. Vérifiez votre configuration.'
        );
      } else {
        _showErrorDialog(
          context, 
          'Erreur inattendue', 
          'Une erreur inattendue s\'est produite : ${e.toString()}'
        );
      }
      return false;
    } catch (e, stackTrace) {
      debugPrint('💥 Erreur lors de la connexion avec Google: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      _showErrorDialog(context, 'Erreur', 'Une erreur s\'est produite lors de la connexion');
      return false;
    }
  }

  static void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> signOut() async {
    try {
      debugPrint('🔄 Déconnexion en cours...');
      
      // Déconnecter de Google Sign In
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      debugPrint('✅ Déconnexion Google terminée');
      
      // Déconnecter de Supabase
      await supabase.auth.signOut();
      debugPrint('✅ Déconnexion Supabase terminée');
    } catch (e) {
      debugPrint('❌ Erreur lors de la déconnexion: $e');
    }
  }

  static Future<AuthResponse?> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint('❌ Erreur lors de la connexion: $e');
      return null;
    }
  }

  static Future<AuthResponse?> signUp({
    required String email,
    required String password,
  }) async {
    try {
      return await supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: callbackUrl,
      );
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'inscription: $e');
      return null;
    }
  }

  static Future<void> resetPassword(String email) async {
    await supabase.auth.resetPasswordForEmail(
      email,
      redirectTo: callbackUrl,
    );
  }
}
