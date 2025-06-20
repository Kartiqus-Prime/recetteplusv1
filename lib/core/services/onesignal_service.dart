import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class OneSignalService {
  static bool _isInitialized = false;
  static String? _playerId;

  /// Initialiser OneSignal
  static Future<void> initialize() async {
    try {
      if (_isInitialized) {
        print('⚠️ OneSignal déjà initialisé');
        return;
      }

      print('🔔 Initialisation de OneSignal...');

      // Récupérer l'App ID depuis .env
      final appId = dotenv.env['ONE_SIGNAL_APP_ID'];
      if (appId == null || appId.isEmpty) {
        throw Exception('ONE_SIGNAL_APP_ID manquant dans le fichier .env');
      }

      // Affichage sécurisé de l'App ID (correction de l'erreur substring)
      final appIdPreview = appId.length > 8 ? '${appId.substring(0, 8)}...' : appId;
      print('🔑 OneSignal App ID: $appIdPreview');

      // Initialiser OneSignal
      OneSignal.initialize(appId);

      // Demander les permissions
      await OneSignal.Notifications.requestPermission(true);

      // Configurer les callbacks
      _setupCallbacks();

      // Récupérer le Player ID
      await _getPlayerId();

      _isInitialized = true;
      print('✅ OneSignal initialisé avec succès');
    } catch (e) {
      print('❌ Erreur initialisation OneSignal: $e');
    }
  }

  /// Configurer les callbacks OneSignal
  static void _setupCallbacks() {
    try {
      // Callback quand une notification est reçue
      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        print('📨 Notification reçue au premier plan: ${event.notification.title}');
        // Laisser OneSignal afficher la notification
        event.preventDefault();
        event.notification.display();
      });

      // Callback quand une notification est tappée
      OneSignal.Notifications.addClickListener((event) {
        print('👆 Notification tappée: ${event.notification.title}');
        final data = event.notification.additionalData;
        if (data != null) {
          _handleNotificationTap(data);
        }
      });

      print('✅ Callbacks OneSignal configurés');
    } catch (e) {
      print('❌ Erreur configuration callbacks: $e');
    }
  }

  /// Récupérer le Player ID
  static Future<void> _getPlayerId() async {
    try {
      // Attendre un peu pour que OneSignal soit complètement initialisé
      await Future.delayed(const Duration(seconds: 2));

      final playerId = OneSignal.User.pushSubscription.id;
      if (playerId != null && playerId.isNotEmpty) {
        _playerId = playerId;
        // Affichage sécurisé du Player ID (correction de l'erreur)
        final playerIdPreview = playerId.length > 8 ? '${playerId.substring(0, 8)}...' : playerId;
        print('🎯 Player ID: $playerIdPreview');
        
        // Sauvegarder en base
        await _savePlayerIdToDatabase();
      } else {
        print('⚠️ Player ID non disponible');
      }
    } catch (e) {
      print('❌ Erreur récupération Player ID: $e');
    }
  }

  /// Sauvegarder le Player ID en base de données
  static Future<void> _savePlayerIdToDatabase() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null && _playerId != null) {
        await Supabase.instance.client
            .from('user_tokens')
            .upsert({
              'user_id': user.id,
              'onesignal_player_id': _playerId,
              'platform': defaultTargetPlatform.name,
              'updated_at': DateTime.now().toIso8601String(),
            });
        print('💾 Player ID sauvegardé en base');
      }
    } catch (e) {
      print('❌ Erreur sauvegarde Player ID: $e');
    }
  }

  /// Gérer le tap sur notification
  static void _handleNotificationTap(Map<String, dynamic> data) {
    try {
      print('🔗 Données notification: $data');
      final route = data['route'] as String?;
      if (route != null) {
        // Ici vous pouvez gérer la navigation
        print('🔗 Navigation vers: $route');
      }
    } catch (e) {
      print('❌ Erreur gestion tap notification: $e');
    }
  }

  /// Créer une notification de test en base de données
  static Future<void> createTestNotification() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        print('❌ Utilisateur non connecté');
        return;
      }

      final now = DateTime.now();
      await Supabase.instance.client.from('notifications').insert({
        'user_id': user.id,
        'title': 'Test OneSignal',
        'content': 'Notification de test OneSignal créée à ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
        'type': 'test',
        'is_read': false,
        'created_at': now.toIso8601String(),
      });

      print('✅ Notification de test OneSignal créée');
    } catch (e) {
      print('❌ Erreur création test OneSignal: $e');
    }
  }

  /// Afficher une notification locale depuis des données
  static Future<void> showNotificationFromData(Map<String, dynamic> data) async {
    try {
      // Cette méthode est appelée par le service de notifications principal
      // OneSignal gère automatiquement l'affichage des notifications push
      print('🔔 OneSignal: Notification reçue');
    } catch (e) {
      print('❌ Erreur OneSignal showNotificationFromData: $e');
    }
  }

  /// Obtenir le statut des notifications
  static Future<Map<String, dynamic>> getNotificationStatus() async {
    final status = <String, dynamic>{};

    try {
      status['onesignal_initialized'] = _isInitialized;
      status['player_id_available'] = _playerId != null;
      
      if (_playerId != null) {
        // Affichage sécurisé (correction de l'erreur)
        status['player_id_preview'] = _playerId!.length > 8 
            ? '${_playerId!.substring(0, 8)}...' 
            : _playerId!;
      }

      // Vérifier l'état de l'abonnement
      final isOptedIn = OneSignal.User.pushSubscription.optedIn;
      status['opted_in'] = isOptedIn;

      print('📊 Status OneSignal: $status');
    } catch (e) {
      print('❌ Erreur status OneSignal: $e');
      status['error'] = e.toString();
    }

    return status;
  }

  /// Obtenir le Player ID
  static Future<String?> getPlayerId() async {
    if (_playerId == null) {
      await _getPlayerId();
    }
    return _playerId;
  }

  /// Définir des tags utilisateur
  static Future<void> setUserTags(Map<String, String> tags) async {
    try {
      OneSignal.User.addTags(tags);
      print('🏷️ Tags utilisateur définis: $tags');
    } catch (e) {
      print('❌ Erreur définition tags: $e');
    }
  }

  /// Opt-in pour les notifications
  static Future<void> optIn() async {
    try {
      OneSignal.User.pushSubscription.optIn();
      print('✅ Opt-in notifications activé');
    } catch (e) {
      print('❌ Erreur opt-in: $e');
    }
  }

  /// Opt-out pour les notifications
  static Future<void> optOut() async {
    try {
      OneSignal.User.pushSubscription.optOut();
      print('❌ Opt-out notifications activé');
    } catch (e) {
      print('❌ Erreur opt-out: $e');
    }
  }

  /// Envoyer une notification de test (alias pour createTestNotification)
  static Future<void> sendTestNotification() async {
    await createTestNotification();
  }

  /// Vérifier le statut des notifications (alias pour getNotificationStatus)
  static Future<Map<String, dynamic>> checkNotificationStatus() async {
    return await getNotificationStatus();
  }

  /// Obtenir le Player ID actuel (alias pour getPlayerId)
  static String? getCurrentPlayerId() {
    return _playerId;
  }
}
