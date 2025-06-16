import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Handler pour les messages en arrière-plan
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📱 Message reçu en arrière-plan: ${message.messageId}');

  // Traiter le message en arrière-plan
  await PushNotificationService._showNotification(message);
}

class PushNotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Callback pour la navigation
  static Function(String)? onNotificationTap;

  /// Initialiser le service de notifications push
  static Future<void> initialize() async {
    try {
      print('🚀 Initialisation des notifications push...');

      // Initialiser Firebase
      await Firebase.initializeApp();
      print('✅ Firebase initialisé');

      // Configurer le handler pour les messages en arrière-plan
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // Initialiser les notifications locales
      await _initializeLocalNotifications();
      print('✅ Notifications locales initialisées');

      // Demander les permissions
      await _requestPermissions();
      print('✅ Permissions demandées');

      // Configurer les listeners
      await _setupMessageHandlers();
      print('✅ Listeners configurés');

      // Obtenir et sauvegarder le token FCM
      await _getFCMToken();
      print('✅ Token FCM obtenu');

      print('✅ Notifications push initialisées avec succès');
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation des notifications: $e');
    }
  }

  /// Initialiser les notifications locales
  static Future<void> _initializeLocalNotifications() async {
    // Utiliser votre icône personnalisée
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_notification');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    final initialized = await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    print('🔔 Notifications locales initialisées: $initialized');

    // Créer le canal de notification Android
    if (Platform.isAndroid) {
      await _createNotificationChannel();
    }
  }

  /// Créer le canal de notification Android
  static Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      'recette_plus_notifications',
      'Recette+ Notifications',
      description: 'Notifications de l\'application Recette+',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(channel);
      print('📢 Canal de notification créé: ${channel.id}');
    }
  }

  /// Demander les permissions
  static Future<void> _requestPermissions() async {
    // Permissions Firebase
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print('🔐 Permissions Firebase: ${settings.authorizationStatus}');

    // Permissions système Android
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      print('🔐 Permissions Android: $status');

      // Vérifier si les permissions sont accordées
      if (status.isDenied) {
        print('⚠️ Permissions de notification refusées');
      } else if (status.isPermanentlyDenied) {
        print('⚠️ Permissions de notification définitivement refusées');
      } else {
        print('✅ Permissions de notification accordées');
      }
    }
  }

  /// Configurer les handlers de messages
  static Future<void> _setupMessageHandlers() async {
    // Messages reçus quand l'app est au premier plan
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📱 Message reçu au premier plan: ${message.notification?.title}');
      print('📱 Corps du message: ${message.notification?.body}');
      print('📱 Données: ${message.data}');
      _showNotification(message);
    });

    // Messages reçus quand l'app est en arrière-plan mais pas fermée
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print(
          '📱 App ouverte depuis notification: ${message.notification?.title}');
      _handleNotificationTap(message.data);
    });

    // Vérifier si l'app a été ouverte depuis une notification
    RemoteMessage? initialMessage =
        await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      print(
          '📱 App lancée depuis notification: ${initialMessage.notification?.title}');
      _handleNotificationTap(initialMessage.data);
    }
  }

  /// Obtenir et sauvegarder le token FCM
  static Future<String?> _getFCMToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        print('🔑 Token FCM: ${token.substring(0, 50)}...');
        await _saveTokenToDatabase(token);

        // Écouter les changements de token
        _firebaseMessaging.onTokenRefresh.listen(_saveTokenToDatabase);
      }
      return token;
    } catch (e) {
      print('❌ Erreur lors de l\'obtention du token: $e');
      return null;
    }
  }

  /// Sauvegarder le token dans la base de données
  static Future<void> _saveTokenToDatabase(String token) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('⚠️ Utilisateur non connecté, token non sauvegardé');
        return;
      }

      await _supabase.from('user_fcm_tokens').upsert({
        'user_id': user.id,
        'fcm_token': token,
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'updated_at': DateTime.now().toIso8601String(),
      });

      print('✅ Token FCM sauvegardé en base pour ${user.email}');
    } catch (e) {
      print('❌ Erreur sauvegarde token: $e');
    }
  }

  /// Afficher une notification locale avec votre icône
  static Future<void> _showNotification(RemoteMessage message) async {
    try {
      print('🔔 Tentative d\'affichage de notification...');

      const androidDetails = AndroidNotificationDetails(
        'recette_plus_notifications',
        'Recette+ Notifications',
        channelDescription: 'Notifications de l\'application Recette+',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_notification', // Votre icône personnalisée
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_notification'),
        color: Color(0xFF4CAF50),
        enableVibration: true,
        playSound: true,
        showWhen: true,
        when: null,
        styleInformation: BigTextStyleInformation(''),
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

      final title = message.notification?.title ?? 'Recette+';
      final body = message.notification?.body ?? 'Nouvelle notification';
      final id = message.hashCode;

      print('🔔 Affichage notification: $title - $body');

      await _localNotifications.show(
        id,
        title,
        body,
        details,
        payload: jsonEncode(message.data),
      );

      print('✅ Notification affichée avec succès');
    } catch (e) {
      print('❌ Erreur affichage notification: $e');
    }
  }

  /// Afficher une notification à partir de données (pour Supabase realtime)
  static Future<void> showNotificationFromData(
      Map<String, dynamic> data) async {
    try {
      print('🔔 Affichage notification depuis données Supabase...');

      const androidDetails = AndroidNotificationDetails(
        'recette_plus_notifications',
        'Recette+ Notifications',
        channelDescription: 'Notifications temps réel de Recette+',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_notification', // Votre icône personnalisée
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_notification'),
        color: Color(0xFF4CAF50),
        enableVibration: true,
        playSound: true,
        showWhen: true,
        styleInformation: BigTextStyleInformation(''),
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

      print('🔔 Affichage notification Supabase: $title - $body');

      await _localNotifications.show(
        id,
        title,
        body,
        details,
        payload: jsonEncode(data['data'] ?? {}),
      );

      print('✅ Notification Supabase affichée avec succès');
    } catch (e) {
      print('❌ Erreur affichage notification Supabase: $e');
    }
  }

  /// Gérer le tap sur une notification locale
  static void _onNotificationTap(NotificationResponse response) {
    print('👆 Notification tappée: ${response.payload}');
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        _handleNotificationTap(data);
      } catch (e) {
        print('❌ Erreur parsing payload: $e');
      }
    }
  }

  /// Gérer la navigation depuis une notification
  static void _handleNotificationTap(Map<String, dynamic> data) {
    print('🔗 Navigation depuis notification: $data');

    // Utiliser le callback si défini
    if (onNotificationTap != null) {
      final route = data['route'] ?? '/notifications';
      onNotificationTap!(route);
      return;
    }
  }

  /// Envoyer une notification de test LOCALE avec votre icône
  static Future<void> sendTestLocalNotification() async {
    try {
      print('🧪 Envoi notification locale de test...');

      const androidDetails = AndroidNotificationDetails(
        'recette_plus_notifications',
        'Recette+ Notifications',
        channelDescription: 'Notifications de test',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_notification', // Votre icône personnalisée
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_notification'),
        color: Color(0xFF4CAF50),
        enableVibration: true,
        playSound: true,
        styleInformation: BigTextStyleInformation(
            'Ceci est une notification de test avec votre logo personnalisé !'),
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
        '🧪 Test Recette+ avec Logo',
        'Notification avec votre icône personnalisée à ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
        details,
        payload: jsonEncode({'type': 'test', 'route': '/notifications'}),
      );

      print('✅ Notification locale de test envoyée avec icône personnalisée');
    } catch (e) {
      print('❌ Erreur envoi notification locale: $e');
    }
  }

  /// Vérifier les permissions et l'état des notifications
  static Future<Map<String, dynamic>> checkNotificationStatus() async {
    final status = <String, dynamic>{};

    try {
      // Vérifier les permissions Android
      if (Platform.isAndroid) {
        final permission = await Permission.notification.status;
        status['android_permission'] = permission.toString();
        status['android_granted'] = permission.isGranted;
      }

      // Vérifier les permissions Firebase
      final settings = await _firebaseMessaging.getNotificationSettings();
      status['firebase_permission'] = settings.authorizationStatus.toString();
      status['firebase_granted'] =
          settings.authorizationStatus == AuthorizationStatus.authorized;

      // Vérifier le token FCM
      final token = await _firebaseMessaging.getToken();
      status['fcm_token'] = token != null;
      status['fcm_token_preview'] = token?.substring(0, 20) ?? 'null';

      // Vérifier l'utilisateur connecté
      final user = _supabase.auth.currentUser;
      status['user_connected'] = user != null;
      status['user_email'] = user?.email ?? 'null';

      print('📊 Status des notifications: $status');
    } catch (e) {
      print('❌ Erreur vérification status: $e');
      status['error'] = e.toString();
    }

    return status;
  }

  /// Obtenir le token FCM actuel
  static Future<String?> getCurrentToken() async {
    return await _firebaseMessaging.getToken();
  }

  /// Supprimer le token de la base de données (déconnexion)
  static Future<void> removeToken() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase.from('user_fcm_tokens').delete().eq('user_id', user.id);

      print('🗑️ Token FCM supprimé');
    } catch (e) {
      print('❌ Erreur suppression token: $e');
    }
  }
}
