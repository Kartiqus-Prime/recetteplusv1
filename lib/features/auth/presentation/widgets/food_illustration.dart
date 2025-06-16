import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FoodIllustration extends StatelessWidget {
  const FoodIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(
          maxHeight: 280,
          maxWidth: 280,
        ),
        child: SvgPicture.asset(
          'assets/images/food-illustration.svg',
          fit: BoxFit.contain,
          colorFilter: null, // Préserve les couleurs originales
          placeholderBuilder: (BuildContext context) => Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              color: const Color(0xFFFF7A5A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Icon(
                Icons.restaurant_menu,
                size: 80,
                color: Color(0xFFFF7A5A),
              ),
            ),
          ),
          // Gestion d'erreur si le SVG ne se charge pas
          semanticsLabel: 'Illustration culinaire',
        ),
      ),
    );
  }
}
