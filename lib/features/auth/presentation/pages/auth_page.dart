import 'package:flutter/material.dart';
import '../widgets/onboarding_screen.dart';
import '../widgets/login_screen.dart';
import '../widgets/register_screen.dart';

enum AuthPageType { onboarding, login, register }

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with TickerProviderStateMixin {
  AuthPageType _currentPage = AuthPageType.onboarding;
  AuthPageType _previousPage = AuthPageType.onboarding;

  void _navigateToPage(AuthPageType page) {
    if (page == _currentPage) return;
    
    setState(() {
      _previousPage = _currentPage;
      _currentPage = page;
    });
  }

  Widget _buildCurrentPage() {
    switch (_currentPage) {
      case AuthPageType.onboarding:
        return OnboardingScreen(
          onLoginTap: () => _navigateToPage(AuthPageType.login),
          onRegisterTap: () => _navigateToPage(AuthPageType.register),
        );
      case AuthPageType.login:
        return LoginScreen(
          onCreateAccountTap: () => _navigateToPage(AuthPageType.register),
          onBackTap: () => _navigateToPage(AuthPageType.onboarding),
        );
      case AuthPageType.register:
        return RegisterScreen(
          onLoginTap: () => _navigateToPage(AuthPageType.login),
          onBackTap: () => _navigateToPage(AuthPageType.onboarding),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (Widget child, Animation<double> animation) {
          // Déterminer la direction de l'animation
          bool isForward = _getPageIndex(_currentPage) > _getPageIndex(_previousPage);
          
          return SlideTransition(
            position: Tween<Offset>(
              begin: Offset(isForward ? 1.0 : -1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: FadeTransition(
              opacity: Tween<double>(
                begin: 0.8,
                end: 1.0,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: Container(
          key: ValueKey(_currentPage),
          child: _buildCurrentPage(),
        ),
      ),
    );
  }

  int _getPageIndex(AuthPageType page) {
    switch (page) {
      case AuthPageType.onboarding:
        return 0;
      case AuthPageType.login:
        return 1;
      case AuthPageType.register:
        return 2;
    }
  }
}
