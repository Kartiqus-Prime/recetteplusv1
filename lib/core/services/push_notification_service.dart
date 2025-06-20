import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PushNotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  static String? _fcmToken;
  static Function(String)? onNotificationTap;

  /// Initialiser le service de notifications push
  static Future<void> initialize() async {
    try {
      print('🔔 Initialisation des notifications push...');

      // Demander les permissions
      await _requestPermissions();

      // Initialiser les notifications locales
      await _initializeLocalNotifications();

      // Obtenir le token FCM
      await _getFCMToken();

      // Configurer les handlers
      _setupMessageHandlers();

      print('✅ Notifications push initialisées avec succès');
    } catch (e) {
      print('❌ Erreur initialisation notifications push: $e');
    }
  }

  /// Demander les permissions de notification
  static Future<void> _requestPermissions() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print('📱 Permissions notifications: ${settings.authorizationStatus}');
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

  /// Obtenir le token FCM
  static Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      print('🔑 Token FCM: ${_fcmToken?.substring(0, 20)}...');

      // Sauvegarder le token en base
      await _saveTokenToDatabase();

      // Écouter les changements de token
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        _saveTokenToDatabase();
      });
    } catch (e) {
      print('❌ Erreur récupération token FCM: $e');
    }
  }

  /// Sauvegarder le token en base de données
  static Future<void> _saveTokenToDatabase() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null && _fcmToken != null) {
        await Supabase.instance.client
            .from('user_tokens')
            .upsert({
              'user_id': user.id,
              'fcm_token': _fcmToken,
              'platform': defaultTargetPlatform.name,
              'updated_at': DateTime.now().toIso8601String(),
            });
        print('💾 Token FCM sauvegardé en base');
      }
    } catch (e) {
      print('❌ Erreur sauvegarde token: $e');
    }
  }

  /// Configurer les handlers de messages
  static void _setupMessageHandlers() {
    // Message reçu quand l'app est au premier plan
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Message tapé quand l'app est en arrière-plan
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessageTap);

    // Vérifier si l'app a été ouverte via une notification
    _checkInitialMessage();
  }

  /// Gérer les messages au premier plan
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📨 Message reçu au premier plan: ${message.notification?.title}');

    // Afficher une notification locale
    await _showLocalNotification(message);
  }

  /// Afficher une notification locale
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'recetteplus_notifications',
      'Recette+ Notifications',
      channelDescription: 'Notifications de l\'application Recette+',
      importance: Importance.high,
      priority: Priority.high,
      // ✅ Utiliser l'icône par défaut de l'app
      icon: '@mipmap/ic_launcher',
      // ✅ Pas d'icône supplémentaire à droite
      largeIcon: null,
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

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      details,
      payload: jsonEncode(message.data),
    );
  }

  /// Gérer le tap sur notification en arrière-plan
  static void _handleBackgroundMessageTap(RemoteMessage message) {
    print('👆 Notification tappée (arrière-plan): ${message.notification?.title}');
    _navigateFromNotification(message.data);
  }

  /// Gérer le tap sur notification locale
  static void _onNotificationTapped(NotificationResponse response) {
    print('👆 Notification locale tappée');
    if (response.payload != null) {
      final data = jsonDecode(response.payload!);
      _navigateFromNotification(data);
    }
  }

  /// Vérifier le message initial
  static Future<void> _checkInitialMessage() async {
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      print('🚀 App ouverte via notification: ${initialMessage.notification?.title}');
      _navigateFromNotification(initialMessage.data);
    }
  }

  /// Naviguer depuis une notification
  static void _navigateFromNotification(Map<String, dynamic> data) {
    final route = data['route'] as String?;
    if (route != null && onNotificationTap != null) {
      onNotificationTap!(route);
    }
  }

  /// Obtenir le token FCM actuel
  static String? get fcmToken => _fcmToken;

  /// Envoyer une notification de test
  static Future<void> sendTestNotification() async {
    final message = RemoteMessage(
      notification: const RemoteNotification(
        title: '🧪 Test Notification',
        body: 'Ceci est une notification de test depuis Recette+',
      ),
      data: {'route': '/home', 'type': 'test'},
    );

    await _handleForegroundMessage(message);
  }
}
