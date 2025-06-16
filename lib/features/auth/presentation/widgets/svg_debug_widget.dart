import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SvgDebugWidget extends StatelessWidget {
  const SvgDebugWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text('Test SVG:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SvgPicture.asset(
              'assets/images/food-illustration.svg',
              fit: BoxFit.contain,
              placeholderBuilder: (context) => const Center(
                child: Text('SVG non trouvé', style: TextStyle(color: Colors.red)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
