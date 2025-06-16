import 'dart:async';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';
import 'push_notification_service.dart';

class BackgroundNotificationService {
  static const String _taskName = 'processNotifications';
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Initialiser le service de notifications en arrière-plan
  static Future<void> initialize() async {
    try {
      print('🔄 Initialisation du service de notifications en arrière-plan...');

      // Initialiser WorkManager
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: true,
      );

      // Programmer une tâche périodique pour traiter les notifications
      await _scheduleNotificationProcessing();

      print('✅ Service de notifications en arrière-plan initialisé');
    } catch (e) {
      print('❌ Erreur initialisation service arrière-plan: $e');
    }
  }

  /// Programmer le traitement périodique des notifications
  static Future<void> _scheduleNotificationProcessing() async {
    try {
      // Annuler les tâches existantes
      await Workmanager().cancelAll();

      // Programmer une tâche périodique (toutes les 15 minutes minimum sur Android)
      await Workmanager().registerPeriodicTask(
        _taskName,
        _taskName,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );

      print('📅 Tâche périodique programmée: $_taskName');
    } catch (e) {
      print('❌ Erreur programmation tâche: $e');
    }
  }

  /// Traiter les notifications en arrière-plan
  static Future<void> processNotifications() async {
    try {
      print('🔄 Traitement des notifications en arrière-plan...');

      // Appeler l'Edge Function pour traiter les notifications
      final response = await _supabase.functions.invoke(
        'send-push-notification',
        method: HttpMethod.post,
      );

      if (response.status == 200) {
        final data = response.data;
        print(
            '✅ Notifications traitées: ${data['success']} succès, ${data['errors']} erreurs');
      } else {
        print('❌ Erreur traitement notifications: ${response.status}');
      }
    } catch (e) {
      print('❌ Erreur traitement notifications: $e');
    }
  }

  /// Créer une notification de test pour vérifier le système
  static Future<void> createTestBackgroundNotification() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        print('❌ Utilisateur non connecté');
        return;
      }

      final now = DateTime.now();
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': '🚀 Test Notification Arrière-plan',
        'content':
            'Cette notification devrait apparaître même si l\'app est fermée ! Créée à ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
        'type': 'test_background',
        'is_read': false,
        'priority': 'high',
        'icon': 'rocket_launch',
        'color': 'text-purple-500',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });

      // Déclencher immédiatement le traitement
      await processNotifications();

      print('✅ Notification de test arrière-plan créée et traitée');
    } catch (e) {
      print('❌ Erreur création test arrière-plan: $e');
    }
  }

  /// Arrêter le service
  static Future<void> stop() async {
    try {
      await Workmanager().cancelAll();
      print('🛑 Service de notifications en arrière-plan arrêté');
    } catch (e) {
      print('❌ Erreur arrêt service: $e');
    }
  }
}

/// Callback pour les tâches en arrière-plan
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      print('🔄 Exécution tâche arrière-plan: $task');

      switch (task) {
        case BackgroundNotificationService._taskName:
          await BackgroundNotificationService.processNotifications();
          break;
        default:
          print('⚠️ Tâche inconnue: $task');
      }

      return Future.value(true);
    } catch (e) {
      print('❌ Erreur tâche arrière-plan: $e');
      return Future.value(false);
    }
  });
}
