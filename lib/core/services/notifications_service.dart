import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart';
import 'push_notification_service.dart';

class NotificationsService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static NotificationsService? _instance;
  RealtimeChannel? _notificationsChannel;

  // Singleton pattern
  static NotificationsService get instance {
    _instance ??= NotificationsService._internal();
    return _instance!;
  }

  NotificationsService._internal();

  // Factory constructor
  factory NotificationsService() => instance;

  // Stream pour les notifications en temps réel
  Stream<List<AppNotification>> get notificationsStream {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return Stream.value(_getFallbackNotifications());

    // Utiliser une approche différente pour les streams avec filtres
    return Stream.periodic(const Duration(seconds: 2), (_) async {
      return await getNotifications();
    }).asyncMap((future) => future);
  }

  // Stream pour le compteur de notifications non lues
  Stream<int> get unreadCountStream {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return Stream.value(3);

    // Stream périodique pour le compteur
    return Stream.periodic(const Duration(seconds: 3), (_) async {
      return await getUnreadCount();
    }).asyncMap((future) => future);
  }

  /// Initialiser le service de notifications temps réel
  Future<void> initializeRealtimeNotifications() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        print('⚠️ Utilisateur non connecté, pas d\'initialisation temps réel');
        return;
      }

      print('🔄 Initialisation des notifications temps réel pour: $userId');

      // Vérifier et afficher les notifications non lues au démarrage
      await _checkAndShowUnreadNotifications();

      // Nettoyer le canal existant s'il y en a un
      if (_notificationsChannel != null) {
        await _supabase.removeChannel(_notificationsChannel!);
      }

      // Créer un nouveau canal pour les notifications temps réel
      _notificationsChannel = _supabase
          .channel('notifications_$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: (payload) {
              print('📨 Nouvelle notification reçue: ${payload.newRecord}');
              _handleNewNotification(payload.newRecord);
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: (payload) {
              print('📝 Notification mise à jour: ${payload.newRecord}');
            },
          );

      // S'abonner au canal
      await _notificationsChannel!.subscribe();

      print('✅ Notifications temps réel initialisées');
    } catch (e) {
      print('❌ Erreur initialisation temps réel: $e');
    }
  }

  /// Vérifier et afficher les notifications non lues au démarrage
  Future<void> _checkAndShowUnreadNotifications() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      print('🔍 Vérification des notifications non lues...');

      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .eq('is_read', false)
          .order('created_at', ascending: false)
          .limit(5); // Limiter à 5 pour éviter le spam

      final unreadNotifications = response as List<dynamic>;
      print('📊 ${unreadNotifications.length} notifications non lues trouvées');

      for (final notificationData in unreadNotifications) {
        final notification = AppNotification.fromJson(notificationData);

        // Vérifier si la notification est récente (moins de 24h)
        final isRecent =
            DateTime.now().difference(notification.createdAt).inHours < 24;

        if (isRecent) {
          print('🔔 Affichage notification non lue: ${notification.title}');
          await _showSystemNotification(notification);

          // Petit délai entre les notifications pour éviter le spam
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
    } catch (e) {
      print('❌ Erreur vérification notifications non lues: $e');
    }
  }

  /// Gérer une nouvelle notification reçue en temps réel
  Future<void> _handleNewNotification(Map<String, dynamic> data) async {
    try {
      final notification = AppNotification.fromJson(data);
      print('🆕 Traitement nouvelle notification: ${notification.title}');

      // Afficher la notification système
      await _showSystemNotification(notification);
    } catch (e) {
      print('❌ Erreur traitement nouvelle notification: $e');
    }
  }

  /// Afficher une notification système
  Future<void> _showSystemNotification(AppNotification notification) async {
    try {
      // Créer un message RemoteMessage simulé pour réutiliser la logique existante
      final fakeMessage = _createFakeRemoteMessage(notification);
      await PushNotificationService.showNotificationFromData(fakeMessage);

      print('✅ Notification système affichée: ${notification.title}');
    } catch (e) {
      print('❌ Erreur affichage notification système: $e');
    }
  }

  /// Créer un faux RemoteMessage à partir d'une AppNotification
  Map<String, dynamic> _createFakeRemoteMessage(AppNotification notification) {
    return {
      'notification': {
        'title': notification.title,
        'body': notification.content,
      },
      'data': {
        'type': notification.type,
        'notification_id': notification.id,
        'route': _getRouteForNotificationType(notification.type),
        'product_id': notification.productId,
        'recipe_id': notification.recipeId,
        'video_id': notification.videoId,
        'order_id': notification.orderId,
      },
    };
  }

  /// Obtenir la route appropriée selon le type de notification
  String _getRouteForNotificationType(String type) {
    switch (type) {
      case 'order':
        return '/profile';
      case 'new_content':
      case 'recipe':
        return '/recipes';
      case 'promotion':
      case 'product':
        return '/products';
      case 'video':
        return '/shorts';
      default:
        return '/notifications';
    }
  }

  /// Nettoyer les ressources
  Future<void> dispose() async {
    try {
      if (_notificationsChannel != null) {
        await _supabase.removeChannel(_notificationsChannel!);
        _notificationsChannel = null;
        print('🧹 Canal de notifications nettoyé');
      }
    } catch (e) {
      print('❌ Erreur nettoyage: $e');
    }
  }

  Future<List<AppNotification>> getNotifications({
    int limit = 20,
    int offset = 0,
    String? type,
    bool? isRead,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return _getFallbackNotifications();

      var query =
          _supabase.from('notifications').select().eq('user_id', userId);

      if (type != null) {
        query = query.eq('type', type);
      }

      if (isRead != null) {
        query = query.eq('is_read', isRead);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List<dynamic>)
          .map<AppNotification>((json) => AppNotification.fromJson(json))
          .toList();
    } catch (e) {
      print('Erreur lors du chargement des notifications: $e');
      return _getFallbackNotifications();
    }
  }

  Future<bool> markAsRead(String notificationId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase
          .from('notifications')
          .update(
              {'is_read': true, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', notificationId)
          .eq('user_id', userId);

      return true;
    } catch (e) {
      print('Erreur lors du marquage: $e');
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase
          .from('notifications')
          .update(
              {'is_read': true, 'updated_at': DateTime.now().toIso8601String()})
          .eq('user_id', userId)
          .eq('is_read', false);

      return true;
    } catch (e) {
      print('Erreur lors du marquage global: $e');
      return false;
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 3;

      final response = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);

      return (response as List<dynamic>).length;
    } catch (e) {
      print('Erreur comptage: $e');
      return 3;
    }
  }

  Future<bool> deleteNotification(String notificationId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId)
          .eq('user_id', userId);

      return true;
    } catch (e) {
      print('Erreur suppression: $e');
      return false;
    }
  }

  Future<Map<String, bool>> getNotificationPreferences() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};

      final response = await _supabase
          .from('notification_preferences')
          .select('type, enabled')
          .eq('user_id', userId);

      return Map.fromEntries((response as List<dynamic>).map(
          (item) => MapEntry(item['type'] as String, item['enabled'] as bool)));
    } catch (e) {
      print('Erreur préférences: $e');
      return {};
    }
  }

  Future<bool> updateNotificationPreference(String type, bool enabled) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase.from('notification_preferences').upsert({
        'user_id': userId,
        'type': type,
        'enabled': enabled,
        'updated_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('Erreur mise à jour préférence: $e');
      return false;
    }
  }

  Future<bool> createTestNotification() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        print(
            'Utilisateur non connecté - création de notification test impossible');
        return false;
      }

      final now = DateTime.now();
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': 'Notification de test temps réel',
        'content':
            'Ceci est une notification de test créée le ${now.day}/${now.month} à ${now.hour}:${now.minute.toString().padLeft(2, '0')}. Elle devrait apparaître automatiquement !',
        'type': 'test',
        'is_read': false,
        'priority': 'normal',
        'icon': 'bell',
        'color': 'text-blue-500',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });

      print(
          'Notification de test temps réel créée avec succès pour l\'utilisateur: $userId');
      return true;
    } catch (e) {
      print('Erreur création test: $e');
      return false;
    }
  }

  List<AppNotification> _getFallbackNotifications() {
    final now = DateTime.now();
    return [
      AppNotification(
        id: '1',
        userId: 'demo-user',
        title: 'Nouvelle recette disponible !',
        content:
            'Découvrez notre nouvelle recette de Thieboudienne aux légumes frais.',
        type: 'new_content',
        isRead: false,
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 2)),
      ),
      AppNotification(
        id: '2',
        userId: 'demo-user',
        title: 'Promotion spéciale',
        content: 'Profitez de -20% sur tous les ingrédients pour vos recettes.',
        type: 'promotion',
        isRead: false,
        createdAt: now.subtract(const Duration(hours: 4)),
        updatedAt: now.subtract(const Duration(hours: 4)),
      ),
      AppNotification(
        id: '3',
        userId: 'demo-user',
        title: 'Commande expédiée',
        content: 'Votre commande #CMD-2024-001 a été expédiée.',
        type: 'order',
        isRead: true,
        createdAt: now.subtract(const Duration(hours: 6)),
        updatedAt: now.subtract(const Duration(hours: 6)),
      ),
    ];
  }
}
