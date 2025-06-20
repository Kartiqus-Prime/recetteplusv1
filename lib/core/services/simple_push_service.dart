import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart';

class SimplePushService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;

  /// Initialiser le service de notifications locales simple
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('🔔 Initialisation service notifications simple...');

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(initSettings);

      // Créer le canal de notification Android
      await _createNotificationChannel();

      _isInitialized = true;
      print('✅ Service notifications simple initialisé');
    } catch (e) {
      print('❌ Erreur initialisation notifications simples: $e');
    }
  }

  /// Créer le canal de notification Android
  static Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      'recetteplus_simple',
      'Recette+ Simple',
      description: 'Notifications simples de Recette+',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Afficher une notification simple
  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      const androidDetails = AndroidNotificationDetails(
        'recetteplus_simple',
        'Recette+ Simple',
        channelDescription: 'Notifications simples de Recette+',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        largeIcon: null,
        showWhen: true,
        enableVibration: true,
        playSound: true,
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

      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      await _localNotifications.show(
        id,
        title,
        body,
        details,
        payload: payload,
      );

      print('✅ Notification simple affichée: $title');
    } catch (e) {
      print('❌ Erreur affichage notification simple: $e');
    }
  }

  /// Afficher une notification à partir d'un objet AppNotification
  static Future<void> showAppNotification(AppNotification notification) async {
    await showNotification(
      title: notification.title,
      body: notification.content,
      payload: notification.id,
    );
  }

  /// Envoyer une notification de test
  static Future<void> sendTestNotification() async {
    final now = DateTime.now();
    await showNotification(
      title: '🧪 Test Simple',
      body:
          'Notification de test simple à ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
      payload: 'test',
    );
  }
}
