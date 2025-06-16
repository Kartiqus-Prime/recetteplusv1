import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';

enum TransitionType {
  fade,
  slideUp,
  slideLeft,
  slideRight,
  scale,
  rotate,
  flip,
  glassmorph,
  futuristic,
}

class FuturisticPageTransition extends PageRouteBuilder {
  final Widget page;
  final TransitionType transitionType;
  final Curve curve;
  final Alignment alignment;
  final Duration duration;

  FuturisticPageTransition({
    required this.page,
    this.transitionType = TransitionType.futuristic,
    this.curve = Curves.fastLinearToSlowEaseIn,
    this.alignment = Alignment.center,
    this.duration = const Duration(milliseconds: 600),
  }) : super(
          pageBuilder: (BuildContext context, Animation<double> animation,
              Animation<double> secondaryAnimation) {
            return page;
          },
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
              Widget child) {
            switch (transitionType) {
              case TransitionType.fade:
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              case TransitionType.slideUp:
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                );
              case TransitionType.slideLeft:
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                );
              case TransitionType.slideRight:
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(-1, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                );
              case TransitionType.scale:
                return ScaleTransition(
                  scale: animation,
                  alignment: alignment,
                  child: child,
                );
              case TransitionType.rotate:
                return RotationTransition(
                  turns: animation,
                  alignment: alignment,
                  child: child,
                );
              case TransitionType.flip:
                return RotationTransition(
                  turns: Tween<double>(begin: 0.0, end: 1.0)
                      .animate(CurvedAnimation(parent: animation, curve: curve)),
                  child: ScaleTransition(
                    scale: animation,
                    child: child,
                  ),
                );
              case TransitionType.glassmorph:
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.9, end: 1.0)
                        .animate(CurvedAnimation(parent: animation, curve: curve)),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: Tween<double>(begin: 10.0, end: 0.0)
                            .animate(animation)
                            .value,
                        sigmaY: Tween<double>(begin: 10.0, end: 0.0)
                            .animate(animation)
                            .value,
                      ),
                      child: child,
                    ),
                  ),
                );
              case TransitionType.futuristic:
              default:
                return AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(math.pi * (1 - animation.value))
                        ..scale(
                          Tween<double>(begin: 0.8, end: 1.0)
                              .animate(CurvedAnimation(
                                parent: animation,
                                curve: const Interval(0.6, 1.0, curve: Curves.easeOutQuint),
                              ))
                              .value,
                        ),
                      child: Opacity(
                        opacity: animation.value,
                        child: child,
                      ),
                    );
                  },
                  child: child,
                );
            }
          },
        );
}
