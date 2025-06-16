import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class ThemeBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, bool isDarkMode) builder;
  
  const ThemeBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        return builder(context, isDarkMode);
      },
    );
  }
}
