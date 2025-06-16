import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        
        return IconButton(
          onPressed: () {
            final newTheme = isDarkMode ? 'light' : 'dark';
            themeProvider.setTheme(newTheme);
          },
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              isDarkMode ? Icons.light_mode : Icons.dark_mode,
              key: ValueKey(isDarkMode),
              color: AppTheme.primaryOrange,
            ),
          ),
          tooltip: isDarkMode ? 'Mode clair' : 'Mode sombre',
        );
      },
    );
  }
}
