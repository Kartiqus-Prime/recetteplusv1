import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';

class ThemeProvider extends ChangeNotifier with WidgetsBindingObserver {
  final SettingsService _settingsService = SettingsService();
  
  ThemeMode _themeMode = ThemeMode.light;
  bool _isLoading = true;
  String _savedThemePreference = 'light';

  ThemeMode get themeMode => _themeMode;
  bool get isLoading => _isLoading;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  String get currentThemeString => _savedThemePreference;

  ThemeProvider() {
    _loadTheme();
    // Écouter les changements du thème système
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Cette méthode est appelée quand le thème système change
  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    _updateThemeMode();
  }

  Future<void> _loadTheme() async {
    try {
      final themeString = await _settingsService.getTheme();
      _savedThemePreference = themeString;
      _updateThemeMode();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Erreur lors du chargement du thème: $e');
      _savedThemePreference = 'light';
      _themeMode = ThemeMode.light;
      _isLoading = false;
      notifyListeners();
    }
  }

  void _updateThemeMode() {
    final newThemeMode = _getThemeModeFromString(_savedThemePreference);
    if (newThemeMode != _themeMode) {
      _themeMode = newThemeMode;
      if (!_isLoading) {
        notifyListeners();
      }
    }
  }

  Future<void> setTheme(String themeString) async {
    if (themeString != _savedThemePreference) {
      _savedThemePreference = themeString;
      _updateThemeMode();
      
      // Sauvegarder le thème
      try {
        await _settingsService.updateTheme(themeString);
      } catch (e) {
        print('Erreur lors de la sauvegarde du thème: $e');
      }
    }
  }

  ThemeMode _getThemeModeFromString(String themeString) {
    switch (themeString) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      case 'light':
      default:
        return ThemeMode.light;
    }
  }

  // Méthode utilitaire pour obtenir la luminosité actuelle
  Brightness getCurrentBrightness(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      return MediaQuery.of(context).platformBrightness;
    }
    return _themeMode == ThemeMode.dark ? Brightness.dark : Brightness.light;
  }

  // Méthode pour vérifier si on est en mode sombre actuellement
  bool isDarkModeActive(BuildContext context) {
    return getCurrentBrightness(context) == Brightness.dark;
  }
}
