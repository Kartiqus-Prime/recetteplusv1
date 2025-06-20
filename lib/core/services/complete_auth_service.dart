import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CompleteAuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static CompleteAuthService? _instance;

  static CompleteAuthService get instance {
    _instance ??= CompleteAuthService._internal();
    return _instance!;
  }

  CompleteAuthService._internal();

  // Stream pour écouter les changements d'état d'authentification
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Vérifier si l'utilisateur est connecté
  bool get isSignedIn => _supabase.auth.currentUser != null;

  // Obtenir l'utilisateur actuel
  User? get currentUser => _supabase.auth.currentUser;

  // Connexion avec email/mot de passe
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      print('🔄 Connexion avec email: $email');

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        print('✅ Connexion réussie pour: ${response.user!.email}');
      }

      return response;
    } catch (e) {
      print('❌ Erreur connexion email: $e');
      rethrow;
    }
  }

  // Inscription avec email/mot de passe
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    try {
      print('🔄 Inscription avec email: $email');

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: data,
      );

      if (response.user != null) {
        print('✅ Inscription réussie pour: ${response.user!.email}');
      }

      return response;
    } catch (e) {
      print('❌ Erreur inscription email: $e');
      rethrow;
    }
  }

  // Connexion avec Google
  Future<bool> signInWithGoogle() async {
    try {
      print('🔄 Connexion avec Google...');

      final response = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.recetteplus://login-callback/',
      );

      print('✅ Redirection Google initiée: $response');
      return response;
    } catch (e) {
      print('❌ Erreur connexion Google: $e');
      return false;
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    try {
      print('🔄 Déconnexion...');
      await _supabase.auth.signOut();
      print('✅ Déconnexion réussie');
    } catch (e) {
      print('❌ Erreur déconnexion: $e');
      rethrow;
    }
  }

  // Réinitialiser le mot de passe
  Future<void> resetPassword(String email) async {
    try {
      print('🔄 Réinitialisation mot de passe pour: $email');

      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.recetteplus://reset-password/',
      );

      print('✅ Email de réinitialisation envoyé');
    } catch (e) {
      print('❌ Erreur réinitialisation: $e');
      rethrow;
    }
  }

  // Vérifier et rafraîchir la session
  Future<bool> ensureValidSession() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) {
        print('❌ Aucune session active');
        return false;
      }

      // Vérifier l'expiration
      final expiresAt =
          DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);
      final now = DateTime.now();
      final timeUntilExpiry = expiresAt.difference(now);

      if (timeUntilExpiry.inMinutes < 10) {
        print('🔄 Rafraîchissement de la session...');

        final response = await _supabase.auth.refreshSession();
        if (response.session != null) {
          print('✅ Session rafraîchie');
          return true;
        } else {
          print('❌ Échec du rafraîchissement');
          return false;
        }
      }

      return true;
    } catch (e) {
      print('❌ Erreur vérification session: $e');
      return false;
    }
  }

  // Obtenir un token d'accès valide
  Future<String?> getValidAccessToken() async {
    try {
      final isValid = await ensureValidSession();
      if (!isValid) return null;

      return _supabase.auth.currentSession?.accessToken;
    } catch (e) {
      print('❌ Erreur récupération token: $e');
      return null;
    }
  }
}
