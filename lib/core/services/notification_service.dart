import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  /// Initialiser le service de notifications
  static Future<void> initialize() async {
    try {
      print('🔔 Initialisation du service de notifications...');

      // Demander les permissions
      await _requestPermissions();

      // Initialiser les notifications locales
      await _initializeLocalNotifications();

      print('✅ Service de notifications initialisé');
    } catch (e) {
      print('❌ Erreur initialisation notifications: $e');
    }
  }

  /// Demander les permissions
  static Future<void> _requestPermissions() async {
    // Permission pour les notifications
    await Permission.notification.request();

    // Permission Firebase
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// Initialiser les notifications locales
  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);

    // Créer le canal Android
    const channel = AndroidNotificationChannel(
      'recetteplus_notifications',
      'Recette+ Notifications',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Configurer pour un utilisateur connecté
  static Future<void> setupForUser() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Obtenir et sauvegarder le token FCM
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _saveUserToken(user.id, token);
      }

      print('✅ Notifications configurées pour l\'utilisateur');
    } catch (e) {
      print('❌ Erreur configuration utilisateur: $e');
    }
  }

  /// Sauvegarder le token utilisateur
  static Future<void> _saveUserToken(String userId, String token) async {
    try {
      await Supabase.instance.client
          .from('user_tokens')
          .upsert({
            'user_id': userId,
            'fcm_token': token,
            'updated_at': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      print('❌ Erreur sauvegarde token: $e');
    }
  }

  /// Afficher une notification locale
  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'recetteplus_notifications',
      'Recette+ Notifications',
      importance: Importance.high,
      priority: Priority.high,
      // ✅ Utiliser uniquement l'icône de l'app
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }
}
