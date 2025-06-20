import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'base_notification_service.dart';
import 'auth_service.dart';

/// Service pour les appels API sécurisés vers les Edge Functions
class SecureApiService extends BaseNotificationService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Clé secrète partagée avec l'Edge Function (à stocker de manière sécurisée)
  static const String _apiSecret = 'RecettePlus2024EdgeFunctionSecret';

  /// Générer un token d'authentification temporaire
  static String _generateAuthToken() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final nonce = Random().nextInt(999999).toString().padLeft(6, '0');
    final payload = '$timestamp:$nonce';

    final key = utf8.encode(_apiSecret);
    final bytes = utf8.encode(payload);
    final hmacSha256 = Hmac(sha256, key);
    final signature = hmacSha256.convert(bytes);

    return base64.encode(utf8.encode('$payload:$signature'));
  }

  /// Appeler l'Edge Function de manière sécurisée
  static Future<Map<String, dynamic>?> callSecureEdgeFunction(
    String functionName, {
    Map<String, dynamic>? body,
    int maxRetries = 3,
  }) async {
    return await BaseNotificationService.retryWithBackoff<Map<String, dynamic>>(
      () async {
        // Vérifier l'authentification avant l'appel
        final authService = AuthService.instance;
        final isAuth = await authService.isAuthenticated();

        if (!isAuth) {
          throw Exception('Utilisateur non authentifié');
        }

        final accessToken = await authService.getValidAccessToken();
        if (accessToken == null) {
          throw Exception('Token d\'accès invalide');
        }

        BaseNotificationService.logDebug(
            '🔐 Appel Edge Function avec token valide: $functionName');

        final response = await _supabase.functions.invoke(
          functionName,
          method: HttpMethod.post,
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
          body: body ?? {},
        );

        if (response.status == 200) {
          BaseNotificationService.logSuccess(
              '✅ Edge Function appelée avec succès: $functionName');
          return response.data as Map<String, dynamic>;
        } else if (response.status == 401) {
          BaseNotificationService.logError(
              '❌ Token JWT invalide, tentative de rafraîchissement...');

          // Forcer le rafraîchissement du token
          await authService.ensureValidSession();
          throw Exception('Token JWT invalide - retry nécessaire');
        } else {
          final error =
              'Edge Function error: ${response.status} - ${response.data}';
          BaseNotificationService.logError('❌ $error');
          throw Exception(error);
        }
      },
      maxRetries: maxRetries,
    );
  }

  /// Traiter les notifications de manière sécurisée
  static Future<Map<String, dynamic>?> processNotificationsSecurely() async {
    try {
      BaseNotificationService.logInfo(
          '🔄 Traitement sécurisé des notifications...');

      final result = await callSecureEdgeFunction('send-push-notification');

      if (result != null) {
        BaseNotificationService.logSuccess(
            '✅ Notifications traitées: ${result['success']} succès, ${result['errors']} erreurs');
      }

      return result;
    } catch (e) {
      BaseNotificationService.logError(
          '❌ Erreur traitement sécurisé notifications: $e');
      return null;
    }
  }

  /// Créer une notification de test sécurisée
  static Future<bool> createSecureTestNotification() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        BaseNotificationService.logWarning('❌ Utilisateur non connecté');
        return false;
      }

      final now = DateTime.now();
      final notificationData = {
        'user_id': userId,
        'title': '🔒 Test Notification Sécurisée',
        'content':
            'Cette notification a été créée avec le système sécurisé ! Créée à ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
        'type': 'test_secure',
        'is_read': false,
        'priority': 'high',
        'icon': 'security',
        'color': 'text-blue-500',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      // Valider les données
      if (!BaseNotificationService.validateNotificationData(notificationData)) {
        BaseNotificationService.logError('❌ Données de notification invalides');
        return false;
      }

      // Insérer en base
      await _supabase.from('notifications').insert(notificationData);

      // Déclencher le traitement sécurisé
      await processNotificationsSecurely();

      BaseNotificationService.logSuccess(
          '✅ Notification de test sécurisée créée et traitée');
      return true;
    } catch (e) {
      BaseNotificationService.logError('❌ Erreur création test sécurisé: $e');
      return false;
    }
  }

  /// Vérifier la santé du système de notifications
  static Future<Map<String, dynamic>> checkSystemHealth() async {
    final health = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'unknown',
      'checks': <String, dynamic>{},
    };

    try {
      // Vérifier la connexion Supabase
      health['checks']['supabase'] = await _checkSupabaseConnection();

      // Vérifier l'Edge Function
      health['checks']['edge_function'] = await _checkEdgeFunctionHealth();

      // Vérifier les permissions
      health['checks']['permissions'] = await _checkPermissions();

      // Vérifier le token FCM
      health['checks']['fcm_token'] = await _checkFcmToken();

      // Calculer le statut global
      final allChecks = health['checks'] as Map<String, dynamic>;
      final allHealthy =
          allChecks.values.every((check) => check['status'] == 'healthy');
      health['status'] = allHealthy ? 'healthy' : 'degraded';

      BaseNotificationService.logInfo(
          '🏥 Vérification santé système: ${health['status']}');
      return health;
    } catch (e) {
      health['status'] = 'error';
      health['error'] = e.toString();
      BaseNotificationService.logError('❌ Erreur vérification santé: $e');
      return health;
    }
  }

  static Future<Map<String, dynamic>> _checkSupabaseConnection() async {
    try {
      await _supabase.from('notifications').select('id').limit(1);
      return {'status': 'healthy', 'message': 'Connexion Supabase OK'};
    } catch (e) {
      return {
        'status': 'unhealthy',
        'message': 'Erreur connexion Supabase: $e'
      };
    }
  }

  static Future<Map<String, dynamic>> _checkEdgeFunctionHealth() async {
    try {
      final result =
          await callSecureEdgeFunction('send-push-notification', maxRetries: 1);
      return {'status': 'healthy', 'message': 'Edge Function accessible'};
    } catch (e) {
      return {
        'status': 'unhealthy',
        'message': 'Edge Function inaccessible: $e'
      };
    }
  }

  static Future<Map<String, dynamic>> _checkPermissions() async {
    // Cette méthode sera implémentée dans le service de notifications push
    return {'status': 'healthy', 'message': 'Permissions à vérifier'};
  }

  static Future<Map<String, dynamic>> _checkFcmToken() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return {'status': 'unhealthy', 'message': 'Utilisateur non connecté'};
      }

      final token = await BaseNotificationService.getDecryptedToken(user.id);
      if (token != null) {
        return {'status': 'healthy', 'message': 'Token FCM présent'};
      } else {
        return {'status': 'unhealthy', 'message': 'Token FCM manquant'};
      }
    } catch (e) {
      return {
        'status': 'unhealthy',
        'message': 'Erreur vérification token: $e'
      };
    }
  }
}
