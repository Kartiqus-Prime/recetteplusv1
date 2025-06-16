import 'package:flutter/material.dart';
import 'page_transition.dart';

class NavigationService {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<dynamic> navigateTo(Widget page, {TransitionType transitionType = TransitionType.futuristic}) {
    return navigatorKey.currentState!.push(
      FuturisticPageTransition(
        page: page,
        transitionType: transitionType,
      ),
    );
  }

  Future<dynamic> navigateToReplacement(Widget page, {TransitionType transitionType = TransitionType.futuristic}) {
    return navigatorKey.currentState!.pushReplacement(
      FuturisticPageTransition(
        page: page,
        transitionType: transitionType,
      ),
    );
  }

  void goBack() {
    return navigatorKey.currentState!.pop();
  }
}

final navigationService = NavigationService();
