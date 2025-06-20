import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'onesignal_service.dart';

class PushNotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  static Function(String)? onNotificationTap;

  /// Initialiser le service de notifications push avec OneSignal
  static Future<void> initialize() async {
    try {
      print('🔔 Initialisation des notifications push avec OneSignal...');

      // Initialiser OneSignal
      await OneSignalService.initialize();

      // Demander les permissions
      await _requestPermissions();

      // Initialiser les notifications locales
      await _initializeLocalNotifications();

      print('✅ Notifications push initialisées avec succès');
    } catch (e) {
      print('❌ Erreur initialisation notifications push: $e');
    }
  }

  /// Demander les permissions de notification
  static Future<void> _requestPermissions() async {
    try {
      final status = await Permission.notification.request();
      print('📱 Permissions notifications: $status');
    } catch (e) {
      print('❌ Erreur permissions: $e');
    }
  }

  /// Initialiser les notifications locales
  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Créer le canal de notification Android
    await _createNotificationChannel();
  }

  /// Créer le canal de notification Android
  static Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      'recetteplus_notifications',
      'Recette+ Notifications',
      description: 'Notifications de l\'application Recette+',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Afficher une notification à partir de données (pour Supabase realtime)
  static Future<void> showNotificationFromData(Map<String, dynamic> data) async {
    try {
      print('🔔 Affichage notification depuis données Supabase...');

      const androidDetails = AndroidNotificationDetails(
        'recetteplus_notifications',
        'Recette+ Notifications',
        channelDescription: 'Notifications temps réel de Recette+',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        largeIcon: null,
        enableVibration: true,
        playSound: true,
        showWhen: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final notification = data['notification'] ?? {};
      final title = notification['title'] ?? 'Recette+';
      final body = notification['body'] ?? 'Nouvelle notification';
      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      print('🔔 Affichage notification: $title - $body');

      await _localNotifications.show(
        id,
        title,
        body,
        details,
        payload: jsonEncode(data['data'] ?? {}),
      );

      print('✅ Notification affichée avec succès');
    } catch (e) {
      print('❌ Erreur affichage notification: $e');
    }
  }

  /// Envoyer une notification de test locale
  static Future<void> sendTestLocalNotification() async {
    try {
      print('🧪 Envoi notification locale de test...');

      const androidDetails = AndroidNotificationDetails(
        'recetteplus_notifications',
        'Recette+ Notifications',
        channelDescription: 'Notifications de test',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        largeIcon: null,
        enableVibration: true,
        playSound: true,
        styleInformation: BigTextStyleInformation(
            'Ceci est une notification de test avec OneSignal !'),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final now = DateTime.now();
      await _localNotifications.show(
        now.millisecondsSinceEpoch ~/ 1000,
        '🧪 Test Recette+ OneSignal',
        'Notification de test à ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
        details,
        payload: jsonEncode({'type': 'test', 'route': '/notifications'}),
      );

      print('✅ Notification locale de test envoyée');
    } catch (e) {
      print('❌ Erreur envoi notification locale: $e');
    }
  }

  /// Vérifier le statut des notifications
  static Future<Map<String, dynamic>> checkNotificationStatus() async {
    final status = <String, dynamic>{};

    try {
      // Vérifier les permissions
      final permission = await Permission.notification.status;
      status['permission'] = permission.toString();
      status['permission_granted'] = permission.isGranted;

      // Vérifier OneSignal
      final oneSignalStatus = await OneSignalService.getNotificationStatus();
      status.addAll(oneSignalStatus);

      // Vérifier l'utilisateur connecté
      final user = Supabase.instance.client.auth.currentUser;
      status['user_connected'] = user != null;
      status['user_email'] = user?.email ?? 'null';

      print('📊 Status des notifications: $status');
    } catch (e) {
      print('❌ Erreur vérification status: $e');
      status['error'] = e.toString();
    }

    return status;
  }

  /// Obtenir le Player ID OneSignal
  static Future<String?> getCurrentToken() async {
    try {
      return await OneSignalService.getPlayerId();
    } catch (e) {
      print('❌ Erreur récupération Player ID: $e');
      return null;
    }
  }

  /// Gérer le tap sur notification locale
  static void _onNotificationTapped(NotificationResponse response) {
    print('👆 Notification locale tappée');
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        _navigateFromNotification(data);
      } catch (e) {
        print('❌ Erreur parsing payload: $e');
      }
    }
  }

  /// Naviguer depuis une notification
  static void _navigateFromNotification(Map<String, dynamic> data) {
    final route = data['route'] as String?;
    if (route != null && onNotificationTap != null) {
      onNotificationTap!(route);
    }
  }

  /// Envoyer une notification de test (alias pour compatibilité)
  static Future<void> sendTestNotification() async {
    await sendTestLocalNotification();
  }

  /// Obtenir le Player ID (alias pour compatibilité)
  static Future<String?> get fcmToken async => await getCurrentToken();
}
