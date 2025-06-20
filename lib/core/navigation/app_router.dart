import 'package:flutter/material.dart';
import 'main_navigation.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/profile/presentation/pages/product_detail_page.dart';
import '../../features/profile/presentation/pages/recipe_detail_page.dart';
import '../../features/profile/presentation/pages/video_detail_page.dart';
import '../../features/profile/presentation/pages/order_detail_page.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
      case '/home':
        return MaterialPageRoute(
          builder: (_) => const MainNavigation(),
          settings: const RouteSettings(name: '/home'),
        );
      case '/recipes':
        return MaterialPageRoute(
          builder: (_) => const MainNavigation(initialIndex: 2),
          settings: const RouteSettings(name: '/recipes'),
        );
      case '/products':
        return MaterialPageRoute(
          builder: (_) => const MainNavigation(initialIndex: 2), // Recettes
          settings: const RouteSettings(name: '/recipes'),
        );
      case '/shorts':
        return MaterialPageRoute(
          builder: (_) => const MainNavigation(initialIndex: 1),
          settings: const RouteSettings(name: '/shorts'),
        );
      case '/profile':
        return MaterialPageRoute(
          builder: (_) => const MainNavigation(initialIndex: 4),
          settings: const RouteSettings(name: '/profile'),
        );
      case '/search':
        return MaterialPageRoute(
          builder: (_) => const SearchPage(),
          settings: const RouteSettings(name: '/search'),
        );
      case '/notifications':
        return MaterialPageRoute(
          builder: (_) => const NotificationsPage(),
          settings: const RouteSettings(name: '/notifications'),
        );
      case '/product-detail':
        final productId = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => ProductDetailPage(productId: productId ?? ''),
          settings: settings,
        );
      case '/recipe-detail':
        // Pour l'instant, rediriger vers la page des recettes
        return MaterialPageRoute(
          builder: (_) => const MainNavigation(initialIndex: 2),
          settings: settings,
        );
      case '/video-detail':
        final videoId = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => VideoDetailPage(videoId: videoId ?? ''),
          settings: settings,
        );
      case '/order-detail':
        // Pour l'instant, rediriger vers la page de profil
        return MaterialPageRoute(
          builder: (_) => const MainNavigation(initialIndex: 4),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const MainNavigation(),
        );
    }
  }

  // Méthodes de navigation statiques simplifiées
  static void navigateToPath(BuildContext context, String path) {
    Navigator.pushNamed(context, path);
  }

  static void navigateToProductDetail(BuildContext context, String productId) {
    Navigator.pushNamed(context, '/product-detail', arguments: productId);
  }

  static void navigateToRecipeDetail(BuildContext context, String recipeId) {
    // Pour l'instant, on navigue vers la page des recettes
    Navigator.pushNamed(context, '/recipes');
  }

  static void navigateToVideoDetail(BuildContext context, String videoId) {
    Navigator.pushNamed(context, '/video-detail', arguments: videoId);
  }

  static void navigateToOrderDetail(BuildContext context, String orderId) {
    // Pour l'instant, on navigue vers le profil (section commandes)
    Navigator.pushNamed(context, '/profile');
  }
}
