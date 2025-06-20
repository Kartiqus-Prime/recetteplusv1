import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

class AuthDiagnosticService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<Map<String, dynamic>> runDiagnostic() async {
    final diagnostic = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'checks': <String, dynamic>{},
    };

    try {
      // 1. Vérifier la session actuelle
      final session = _supabase.auth.currentSession;
      diagnostic['checks']['session_exists'] = {
        'status': session != null ? 'OK' : 'FAIL',
        'details': session != null ? 'Session active' : 'Aucune session',
      };

      if (session != null) {
        // 2. Vérifier l'expiration du token
        final expiresAt =
            DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);
        final now = DateTime.now();
        final timeUntilExpiry = expiresAt.difference(now);

        diagnostic['checks']['token_expiry'] = {
          'status': timeUntilExpiry.inMinutes > 5 ? 'OK' : 'WARNING',
          'details': 'Expire dans ${timeUntilExpiry.inMinutes} minutes',
          'expires_at': expiresAt.toIso8601String(),
        };

        // 3. Vérifier l'utilisateur actuel
        final user = _supabase.auth.currentUser;
        diagnostic['checks']['current_user'] = {
          'status': user != null ? 'OK' : 'FAIL',
          'details':
              user != null ? 'Utilisateur: ${user.email}' : 'Aucun utilisateur',
          'user_id': user?.id,
        };

        // 4. Tester un appel API simple
        try {
          await _supabase.from('notifications').select('id').limit(1);
          diagnostic['checks']['api_call'] = {
            'status': 'OK',
            'details': 'Appel API réussi',
          };
        } catch (apiError) {
          diagnostic['checks']['api_call'] = {
            'status': 'FAIL',
            'details': 'Erreur API: $apiError',
          };
        }

        // 5. Tester le rafraîchissement du token
        if (timeUntilExpiry.inMinutes < 10) {
          try {
            final authService = AuthService.instance;
            final validToken = await authService.getValidAccessToken();
            diagnostic['checks']['token_refresh'] = {
              'status': validToken != null ? 'OK' : 'FAIL',
              'details': validToken != null
                  ? 'Token rafraîchi'
                  : 'Échec rafraîchissement',
            };
          } catch (refreshError) {
            diagnostic['checks']['token_refresh'] = {
              'status': 'FAIL',
              'details': 'Erreur rafraîchissement: $refreshError',
            };
          }
        }
      }

      // Calculer le statut global
      final checks = diagnostic['checks'] as Map<String, dynamic>;
      final hasFailures =
          checks.values.any((check) => check['status'] == 'FAIL');
      final hasWarnings =
          checks.values.any((check) => check['status'] == 'WARNING');

      diagnostic['overall_status'] =
          hasFailures ? 'FAIL' : (hasWarnings ? 'WARNING' : 'OK');

      print(
          '🔍 Diagnostic d\'authentification: ${diagnostic['overall_status']}');
      return diagnostic;
    } catch (e) {
      diagnostic['overall_status'] = 'ERROR';
      diagnostic['error'] = e.toString();
      print('❌ Erreur diagnostic: $e');
      return diagnostic;
    }
  }

  static void printDiagnostic(Map<String, dynamic> diagnostic) {
    print('\n📊 === DIAGNOSTIC D\'AUTHENTIFICATION ===');
    print('🕐 Timestamp: ${diagnostic['timestamp']}');
    print('📈 Statut global: ${diagnostic['overall_status']}');

    final checks = diagnostic['checks'] as Map<String, dynamic>;
    checks.forEach((key, value) {
      final status = value['status'];
      final emoji = status == 'OK' ? '✅' : (status == 'WARNING' ? '⚠️' : '❌');
      print('$emoji $key: ${value['details']}');
    });

    if (diagnostic['error'] != null) {
      print('❌ Erreur: ${diagnostic['error']}');
    }
    print('===========================================\n');
  }
}
