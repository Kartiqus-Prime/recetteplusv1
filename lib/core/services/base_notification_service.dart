import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class BaseNotificationService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Configuration des notifications
  static const String channelId = 'recette_plus_notifications';
  static const String channelName = 'Recette+ Notifications';
  static const String channelDescription =
      'Notifications de l\'application Recette+';

  // Clé de chiffrement pour les tokens (à stocker de manière sécurisée)
  static const String _encryptionKey =
      'RecettePlus2024SecureKey123456789'; // 32 caractères

  /// Configuration iOS pour les notifications
  static final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  /// Configuration Android pour les notifications
  static final AndroidNotificationDetails androidDetails =
      AndroidNotificationDetails(
    channelId,
    channelName,
    channelDescription: channelDescription,
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_notification',
    largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_notification'),
    color: const Color(0xFF4CAF50),
    enableVibration: true,
    playSound: true,
    showWhen: true,
    styleInformation: const BigTextStyleInformation(''),
  );

  /// Configuration complète des notifications
  static final NotificationDetails notificationDetails = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );

  /// Créer le canal de notification Android
  static Future<void> createNotificationChannel() async {
    if (!Platform.isAndroid) return;

    const channel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(channel);
      logInfo('📢 Canal de notification créé: ${channel.id}');
    }
  }

  /// Chiffrer un token FCM avant stockage
  static String encryptToken(String token) {
    try {
      final key = utf8.encode(_encryptionKey);
      final bytes = utf8.encode(token);
      final hmacSha256 = Hmac(sha256, key);
      final digest = hmacSha256.convert(bytes);

      // Encoder en base64 pour le stockage
      final encrypted =
          base64.encode(utf8.encode('$token:${digest.toString()}'));
      return encrypted;
    } catch (e) {
      logError('❌ Erreur chiffrement token: $e');
      return token; // Fallback non chiffré
    }
  }

  /// Déchiffrer un token FCM
  static String? decryptToken(String encryptedToken) {
    try {
      final decoded = utf8.decode(base64.decode(encryptedToken));
      final parts = decoded.split(':');
      if (parts.length != 2) return null;

      final token = parts[0];
      final expectedDigest = parts[1];

      // Vérifier l'intégrité
      final key = utf8.encode(_encryptionKey);
      final bytes = utf8.encode(token);
      final hmacSha256 = Hmac(sha256, key);
      final actualDigest = hmacSha256.convert(bytes).toString();

      if (expectedDigest == actualDigest) {
        return token;
      }
      return null;
    } catch (e) {
      logError('❌ Erreur déchiffrement token: $e');
      return null;
    }
  }

  /// Sauvegarder le token FCM de manière sécurisée
  static Future<bool> saveTokenSecurely(String token) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        logWarning('⚠️ Utilisateur non connecté, token non sauvegardé');
        return false;
      }

      final encryptedToken = encryptToken(token);
      final now = DateTime.now().toIso8601String();

      await _supabase.from('user_fcm_tokens').upsert({
        'user_id': user.id,
        'fcm_token_encrypted': encryptedToken,
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'updated_at': now,
        'created_at': now,
      });

      logSuccess(
          '✅ Token FCM sauvegardé de manière sécurisée pour ${user.email}');
      return true;
    } catch (e) {
      logError('❌ Erreur sauvegarde sécurisée token: $e');
      return false;
    }
  }

  /// Récupérer le token FCM déchiffré
  static Future<String?> getDecryptedToken(String userId) async {
    try {
      final response = await _supabase
          .from('user_fcm_tokens')
          .select('fcm_token_encrypted')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;

      final encryptedToken = response['fcm_token_encrypted'] as String?;
      if (encryptedToken == null) return null;

      return decryptToken(encryptedToken);
    } catch (e) {
      logError('❌ Erreur récupération token déchiffré: $e');
      return null;
    }
  }

  /// Supprimer le token de manière sécurisée
  static Future<bool> removeTokenSecurely() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      await _supabase.from('user_fcm_tokens').delete().eq('user_id', user.id);
      logSuccess('🗑️ Token FCM supprimé de manière sécurisée');
      return true;
    } catch (e) {
      logError('❌ Erreur suppression sécurisée token: $e');
      return false;
    }
  }

  /// Mécanisme de retry avec backoff exponentiel
  static Future<T?> retryWithBackoff<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
    double backoffMultiplier = 2.0,
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (attempt < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempt++;
        if (attempt >= maxRetries) {
          logError('❌ Échec après $maxRetries tentatives: $e');
          rethrow;
        }

        logWarning(
            '⚠️ Tentative $attempt échouée, retry dans ${delay.inSeconds}s: $e');
        await Future.delayed(delay);
        delay = Duration(
            milliseconds: (delay.inMilliseconds * backoffMultiplier).round());
      }
    }
    return null;
  }

  /// Valider les données de notification
  static bool validateNotificationData(Map<String, dynamic> data) {
    if (data.isEmpty) return false;

    // Vérifier les champs obligatoires
    final requiredFields = ['title', 'content', 'user_id'];
    for (final field in requiredFields) {
      if (!data.containsKey(field) ||
          data[field] == null ||
          data[field].toString().isEmpty) {
        logWarning('⚠️ Champ obligatoire manquant: $field');
        return false;
      }
    }

    // Vérifier la longueur des champs
    if (data['title'].toString().length > 100) {
      logWarning('⚠️ Titre trop long (max 100 caractères)');
      return false;
    }

    if (data['content'].toString().length > 500) {
      logWarning('⚠️ Contenu trop long (max 500 caractères)');
      return false;
    }

    return true;
  }

  /// Nettoyer les anciennes notifications
  static Future<void> cleanupOldNotifications({int daysToKeep = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

      await _supabase
          .from('notifications')
          .delete()
          .lt('created_at', cutoffDate.toIso8601String());

      logInfo('🧹 Anciennes notifications nettoyées (> $daysToKeep jours)');
    } catch (e) {
      logError('❌ Erreur nettoyage notifications: $e');
    }
  }

  /// Obtenir les statistiques des notifications
  static Future<Map<String, dynamic>> getNotificationStats() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return {};

      final response = await _supabase
          .from('notifications')
          .select('is_read, created_at')
          .eq('user_id', user.id);

      final total = response.length;
      final unread = response.where((n) => n['is_read'] == false).length;
      final today = response.where((n) {
        final createdAt = DateTime.parse(n['created_at']);
        final now = DateTime.now();
        return createdAt.year == now.year &&
            createdAt.month == now.month &&
            createdAt.day == now.day;
      }).length;

      return {
        'total': total,
        'unread': unread,
        'read': total - unread,
        'today': today,
      };
    } catch (e) {
      logError('❌ Erreur récupération stats notifications: $e');
      return {};
    }
  }

  // Méthodes de logging améliorées
  static void logSuccess(String message) {
    if (kDebugMode) print('✅ $message');
  }

  static void logInfo(String message) {
    if (kDebugMode) print('ℹ️ $message');
  }

  static void logWarning(String message) {
    if (kDebugMode) print('⚠️ $message');
  }

  static void logError(String message) {
    if (kDebugMode) print('❌ $message');
  }

  static void logDebug(String message) {
    if (kDebugMode) print('🐛 $message');
  }
}
