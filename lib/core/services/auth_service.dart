import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static AuthService? _instance;

  // Singleton pattern
  static AuthService get instance {
    _instance ??= AuthService._internal();
    return _instance!;
  }

  AuthService._internal();

  Future<User?> getCurrentUser() async {
    try {
      await _ensureValidSession();
      return _supabase.auth.currentUser;
    } catch (e) {
      print('❌ Erreur getCurrentUser: $e');
      return null;
    }
  }

  Future<bool> _ensureValidSession() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) {
        print('❌ Aucune session active');
        return false;
      }

      // Vérifier si le token expire bientôt (dans les 10 prochaines minutes)
      final expiresAt =
          DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);
      final now = DateTime.now();
      final timeUntilExpiry = expiresAt.difference(now);

      print('⏰ Token expire dans: ${timeUntilExpiry.inMinutes} minutes');

      if (timeUntilExpiry.inMinutes < 10) {
        print('🔄 Token expire bientôt, rafraîchissement automatique...');
        try {
          final response = await _supabase.auth.refreshSession();
          if (response.session != null) {
            print('✅ Token rafraîchi avec succès');
            return true;
          } else {
            print('❌ Échec du rafraîchissement du token');
            return false;
          }
        } catch (refreshError) {
          print('❌ Erreur lors du rafraîchissement: $refreshError');
          // Essayer de reconnecter l'utilisateur
          await _handleAuthError();
          return false;
        }
      }

      return true;
    } catch (e) {
      print('❌ Erreur vérification session: $e');
      await _handleAuthError();
      return false;
    }
  }

  Future<void> _handleAuthError() async {
    try {
      print('🔄 Tentative de reconnexion automatique...');

      // Vérifier si on a des credentials stockés
      final session = _supabase.auth.currentSession;
      if (session?.refreshToken != null) {
        await _supabase.auth.refreshSession();
        print('✅ Reconnexion réussie');
      } else {
        print('⚠️ Aucun refresh token disponible');
        // Ici vous pourriez rediriger vers la page de connexion
      }
    } catch (e) {
      print('❌ Échec de la reconnexion: $e');
      // Nettoyer la session corrompue
      await _supabase.auth.signOut();
    }
  }

  Future<String?> getValidAccessToken() async {
    try {
      final isValid = await _ensureValidSession();
      if (!isValid) return null;

      final session = _supabase.auth.currentSession;
      return session?.accessToken;
    } catch (e) {
      print('❌ Erreur récupération token: $e');
      return null;
    }
  }

  Future<bool> isAuthenticated() async {
    try {
      return await _ensureValidSession();
    } catch (e) {
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      print('✅ Déconnexion réussie');
    } catch (e) {
      print('❌ Erreur déconnexion: $e');
    }
  }

  Future<bool> ensureValidSession() async {
    return await _ensureValidSession();
  }

  Future<bool> signInWithGoogle(BuildContext context) async {
    try {
      print('🔄 Tentative de connexion avec Google...');

      final response = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.recetteplus://login-callback/',
      );

      if (response) {
        print('✅ Connexion Google réussie');
        return true;
      } else {
        print('❌ Connexion Google échouée');
        return false;
      }
    } catch (e) {
      print('❌ Erreur connexion Google: $e');
      return false;
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    try {
      print('🔄 Tentative de connexion avec email...');

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        print('✅ Connexion email réussie');
        return true;
      } else {
        print('❌ Connexion email échouée');
        return false;
      }
    } catch (e) {
      print('❌ Erreur connexion email: $e');
      return false;
    }
  }

  Future<bool> signUpWithEmail(String email, String password) async {
    try {
      print('🔄 Tentative d\'inscription avec email...');

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        print('✅ Inscription email réussie');
        return true;
      } else {
        print('❌ Inscription email échouée');
        return false;
      }
    } catch (e) {
      print('❌ Erreur inscription email: $e');
      return false;
    }
  }
}
