import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/theme_provider.dart';
import 'core/navigation/main_navigation.dart';
import 'core/navigation/app_router.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/notifications_service.dart';
import 'core/services/background_notification_service.dart';
import 'features/auth/presentation/pages/auth_page.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    print('🚀 Démarrage de l\'application...');

    // Charger les variables d'environnement
    print('📁 Chargement du fichier .env...');
    await dotenv.load(fileName: ".env");
    print('✅ Fichier .env chargé');

    // Vérifier que les variables d'environnement sont présentes
    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (supabaseUrl == null || supabaseUrl.isEmpty) {
      throw Exception('SUPABASE_URL manquant dans le fichier .env');
    }

    if (supabaseAnonKey == null || supabaseAnonKey.isEmpty) {
      throw Exception('SUPABASE_ANON_KEY manquant dans le fichier .env');
    }

    print('🔗 URL Supabase: ${supabaseUrl.substring(0, 20)}...');

    // Initialiser Supabase
    print('🔧 Initialisation de Supabase...');
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: true,
    );
    print('✅ Supabase initialisé avec succès');

    // Initialiser les notifications push
    print('📱 Initialisation des notifications push...');
    await PushNotificationService.initialize();
    print('✅ Notifications push initialisées');

    // Initialiser le service de notifications en arrière-plan
    print('🔄 Initialisation du service arrière-plan...');
    await BackgroundNotificationService.initialize();
    print('✅ Service arrière-plan initialisé');

    print('🎯 Lancement de l\'application...');
    runApp(const RecettePlusApp());
  } catch (e, stackTrace) {
    print('❌ Erreur lors de l\'initialisation: $e');
    print('📍 Stack trace: $stackTrace');

    // Lancer une application d'erreur simple
    runApp(ErrorApp(error: e.toString()));
  }
}

final supabase = Supabase.instance.client;

class RecettePlusApp extends StatelessWidget {
  const RecettePlusApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Configurer le callback de navigation pour les notifications
    PushNotificationService.onNotificationTap = (String route) {
      // Ici vous pouvez gérer la navigation globale
      print('🔗 Navigation demandée vers: $route');
      // Vous pouvez utiliser un GlobalKey<NavigatorState> pour naviguer
    };

    return ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          // Afficher un écran de chargement pendant que le thème se charge
          if (themeProvider.isLoading) {
            return MaterialApp(
              home: const LoadingScreen(),
              debugShowCheckedModeBanner: false,
            );
          }

          return MaterialApp(
            title: 'Recette+',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const AuthWrapper(),
            onGenerateRoute: AppRouter.generateRoute,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

// Widget séparé pour l'écran de chargement
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppTheme.primaryGreen,
            ),
            const SizedBox(height: 20),
            Text(
              'Recette+',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Chargement...',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget séparé pour gérer l'authentification
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeNotificationsAfterAuth();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        print('📱 App au premier plan');
        // Traiter les notifications en attente quand l'app revient au premier plan
        _processBackgroundNotifications();
        break;
      case AppLifecycleState.paused:
        print('📱 App en arrière-plan');
        break;
      case AppLifecycleState.detached:
        print('📱 App fermée');
        break;
      default:
        break;
    }
  }

  /// Traiter les notifications en arrière-plan
  Future<void> _processBackgroundNotifications() async {
    try {
      await BackgroundNotificationService.processNotifications();
    } catch (e) {
      print('❌ Erreur traitement notifications arrière-plan: $e');
    }
  }

  /// Initialiser les notifications après l'authentification
  void _initializeNotificationsAfterAuth() {
    // Écouter les changements d'état d'authentification
    supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        // Utilisateur connecté, initialiser les notifications temps réel
        print(
            '👤 Utilisateur connecté, initialisation notifications temps réel...');
        _setupRealtimeNotifications();
      } else {
        // Utilisateur déconnecté, nettoyer les notifications
        print('👤 Utilisateur déconnecté, nettoyage notifications...');
        _cleanupNotifications();
      }
    });
  }

  /// Configurer les notifications temps réel
  Future<void> _setupRealtimeNotifications() async {
    try {
      // Petit délai pour s'assurer que l'utilisateur est bien connecté
      await Future.delayed(const Duration(seconds: 1));

      final notificationsService = NotificationsService.instance;
      await notificationsService.initializeRealtimeNotifications();

      print('✅ Notifications temps réel configurées');
    } catch (e) {
      print('❌ Erreur configuration notifications temps réel: $e');
    }
  }

  /// Nettoyer les notifications
  Future<void> _cleanupNotifications() async {
    try {
      final notificationsService = NotificationsService.instance;
      await notificationsService.dispose();

      print('🧹 Notifications nettoyées');
    } catch (e) {
      print('❌ Erreur nettoyage notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Gestion des erreurs de stream
        if (snapshot.hasError) {
          print(
              '❌ Erreur dans le stream d\'authentification: ${snapshot.error}');
          return ErrorScreen(error: snapshot.error.toString());
        }

        // Vérification de l'état de la session
        final session = supabase.auth.currentSession;
        print(
            '🔐 Session actuelle: ${session != null ? 'Connecté' : 'Non connecté'}');

        if (session != null) {
          return const MainNavigation();
        } else {
          return const AuthPage();
        }
      },
    );
  }
}

// Application d'erreur simple pour afficher les erreurs d'initialisation
class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red[50],
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Erreur d\'initialisation',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // Redémarrer l'application
                    main();
                  },
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Écran d'erreur pour les erreurs de stream
class ErrorScreen extends StatelessWidget {
  final String error;

  const ErrorScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange[50],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.warning_outlined,
                size: 64,
                color: Colors.orange,
              ),
              const SizedBox(height: 20),
              const Text(
                'Erreur d\'authentification',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Redémarrer l'application
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const AuthPage()),
                  );
                },
                child: const Text('Aller à la connexion'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
