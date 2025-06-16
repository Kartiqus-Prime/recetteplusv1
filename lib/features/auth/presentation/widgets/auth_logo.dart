import 'package:flutter/material.dart';

class AuthLogo extends StatelessWidget {
  const AuthLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Logo encore plus agrandi sans conteneur avec fond
        Image.asset(
          'assets/images/logo.png',
          height: 150, // Agrandi de 120 à 150
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 8), // Réduit de 12 à 8
        const Text(
          'L\'univers des saveurs',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFFFF7A5A),
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
