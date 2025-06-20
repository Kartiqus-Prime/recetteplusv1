import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';
import 'base_notification_service.dart';
import 'secure_api_service.dart';

class BackgroundNotificationService extends BaseNotificationService {
  static const String _taskName = 'processNotifications';
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Initialiser le service de notifications en arrière-plan
  static Future<void> initialize() async {
    try {
      BaseNotificationService.logInfo(
          '🔄 Initialisation du service de notifications en arrière-plan...');

      // Initialiser WorkManager
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: true,
      );

      // Programmer une tâche périodique pour traiter les notifications
      await _scheduleNotificationProcessing();

      BaseNotificationService.logSuccess(
          '✅ Service de notifications en arrière-plan initialisé');
    } catch (e) {
      BaseNotificationService.logError(
          '❌ Erreur initialisation service arrière-plan: $e');
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

      BaseNotificationService.logInfo(
          '📅 Tâche périodique programmée: $_taskName');
    } catch (e) {
      BaseNotificationService.logError('❌ Erreur programmation tâche: $e');
    }
  }

  /// Traiter les notifications en arrière-plan de manière sécurisée
  static Future<void> processNotifications() async {
    try {
      BaseNotificationService.logInfo(
          '🔄 Traitement sécurisé des notifications en arrière-plan...');

      final result = await SecureApiService.processNotificationsSecurely();

      if (result != null) {
        BaseNotificationService.logSuccess(
            '✅ Notifications arrière-plan traitées: ${result['success']} succès, ${result['errors']} erreurs');
      } else {
        BaseNotificationService.logWarning(
            '⚠️ Aucun résultat du traitement arrière-plan');
      }
    } catch (e) {
      BaseNotificationService.logError(
          '❌ Erreur traitement notifications arrière-plan: $e');
    }
  }

  // Autres méthodes existantes...
}

/// Callback pour les tâches en arrière-plan
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      BaseNotificationService.logInfo('🔄 Exécution tâche arrière-plan: $task');

      switch (task) {
        case BackgroundNotificationService._taskName:
          await BackgroundNotificationService.processNotifications();
          break;
        default:
          BaseNotificationService.logWarning('⚠️ Tâche inconnue: $task');
      }

      return Future.value(true);
    } catch (e) {
      BaseNotificationService.logError('❌ Erreur tâche arrière-plan: $e');
      return Future.value(false);
    }
  });
}
