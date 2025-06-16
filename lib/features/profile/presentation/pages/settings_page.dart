import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../../../main.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/models/notification_preference.dart';
import '../../../auth/presentation/pages/auth_page.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/extensions/toast_extensions.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SettingsService _settingsService = SettingsService();
  
  bool _loading = true;
  String _currentTheme = 'light';
  List<NotificationPreference> _notificationPreferences = [];
  
  // Types de notifications disponibles
  final Map<String, String> _notificationTypes = {
    'order': 'Commandes',
    'new_content': 'Nouveau contenu',
    'price_drop': 'Baisse de prix',
    'low_stock': 'Stock limité',
    'comment_reply': 'Réponses aux commentaires',
    'auth': 'Sécurité du compte',
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _loading = true);

    try {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      final theme = themeProvider.currentThemeString;
      final notifications = await _settingsService.getNotificationPreferences();

      setState(() {
        // Validation des valeurs pour éviter les erreurs de dropdown
        _currentTheme = ['light', 'dark', 'system'].contains(theme) ? theme : 'light';
        _notificationPreferences = notifications;
      });
    } catch (e) {
      // En cas d'erreur, utiliser les valeurs par défaut
      setState(() {
        _currentTheme = 'light';
        _notificationPreferences = [];
      });
      
      if (mounted) {
        context.showErrorToast('Erreur lors du chargement des paramètres');
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateTheme(String theme) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    await themeProvider.setTheme(theme);
    await _settingsService.updateTheme(theme);
    setState(() => _currentTheme = theme);
    context.showSuccessToast('Thème mis à jour', icon: Icons.palette);
  }

  Future<void> _updateNotificationPreference(String type, bool enabled) async {
    final success = await _settingsService.updateNotificationPreference(type, enabled);
    if (success) {
      setState(() {
        final index = _notificationPreferences.indexWhere((pref) => pref.type == type);
        if (index != -1) {
          _notificationPreferences[index] = _notificationPreferences[index].copyWith(enabled: enabled);
        } else {
          // Créer une nouvelle préférence si elle n'existe pas
          _notificationPreferences.add(NotificationPreference(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            userId: supabase.auth.currentUser!.id,
            type: type,
            enabled: enabled,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
        }
      });
      context.showSuccessToast('Préférence de notification mise à jour', icon: Icons.notifications);
    } else {
      context.showErrorToast('Erreur lors de la mise à jour');
    }
  }

  Future<void> _clearCache() async {
    final confirmed = await _showConfirmationDialog(
      'Vider le cache',
      'Êtes-vous sûr de vouloir vider le cache de l\'application ?',
    );

    if (confirmed) {
      final success = await _settingsService.clearCache();
      if (success) {
        context.showSuccessToast('Cache vidé avec succ��s', icon: Icons.cleaning_services);
      } else {
        context.showErrorToast('Erreur lors du vidage du cache');
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await _showConfirmationDialog(
      'Supprimer le compte',
      'Cette action est irréversible. Toutes vos données seront définitivement supprimées. Êtes-vous sûr de vouloir continuer ?',
      isDestructive: true,
    );

    if (confirmed) {
      final success = await _settingsService.deleteAccount();
      if (success) {
        context.showSuccessToast('Compte supprimé avec succès', icon: Icons.delete_forever);
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthPage()),
          (route) => false,
        );
      } else {
        context.showErrorToast('Erreur lors de la suppression du compte');
      }
    }
  }

  Future<bool> _showConfirmationDialog(String title, String content, {bool isDestructive = false}) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF252525) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            content,
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Annuler',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDestructive ? Colors.red : AppTheme.primaryOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(isDestructive ? 'Supprimer' : 'Confirmer'),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  bool _getNotificationEnabled(String type) {
    final pref = _notificationPreferences.firstWhere(
      (pref) => pref.type == type,
      orElse: () => NotificationPreference(
        id: '',
        userId: '',
        type: type,
        enabled: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    return pref.enabled;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode 
          ? const Color(0xFF121212) 
          : const Color(0xFFFAF9F6),
      appBar: AppBar(
        backgroundColor: isDarkMode 
            ? const Color(0xFF1E1E1E) 
            : Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Paramètres',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryOrange,
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Apparence
                    _buildSectionCard(
                      title: 'Apparence',
                      icon: Icons.palette_outlined,
                      isDarkMode: isDarkMode,
                      children: [
                        _buildDropdownTile(
                          title: 'Thème',
                          value: _currentTheme,
                          items: const {
                            'light': 'Clair',
                            'dark': 'Sombre',
                            'system': 'Système',
                          },
                          onChanged: _updateTheme,
                          isDarkMode: isDarkMode,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Section Notifications
                    _buildSectionCard(
                      title: 'Notifications',
                      icon: Icons.notifications_outlined,
                      isDarkMode: isDarkMode,
                      children: _notificationTypes.entries.map((entry) {
                        return Column(
                          children: [
                            _buildSwitchTile(
                              title: entry.value,
                              value: _getNotificationEnabled(entry.key),
                              onChanged: (value) => _updateNotificationPreference(entry.key, value),
                              isDarkMode: isDarkMode,
                            ),
                            if (entry.key != _notificationTypes.keys.last)
                              const Divider(height: 1),
                          ],
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Section Stockage
                    _buildSectionCard(
                      title: 'Stockage',
                      icon: Icons.storage_outlined,
                      isDarkMode: isDarkMode,
                      children: [
                        _buildActionTile(
                          title: 'Vider le cache',
                          subtitle: 'Libérer de l\'espace de stockage',
                          icon: Icons.cleaning_services_outlined,
                          onTap: _clearCache,
                          isDarkMode: isDarkMode,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Section Compte
                    _buildSectionCard(
                      title: 'Compte',
                      icon: Icons.account_circle_outlined,
                      isDarkMode: isDarkMode,
                      children: [
                        _buildActionTile(
                          title: 'Supprimer le compte',
                          subtitle: 'Supprimer définitivement votre compte',
                          icon: Icons.delete_forever_outlined,
                          onTap: _deleteAccount,
                          isDarkMode: isDarkMode,
                          isDestructive: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required bool isDarkMode,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
          width: 1,
        ),
      ),
      color: isDarkMode ? const Color(0xFF252525) : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: AppTheme.primaryOrange,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String value,
    required Map<String, String> items,
    required Function(String) onChanged,
    required bool isDarkMode,
  }) {
    // S'assurer que la valeur existe dans les items
    final validValue = items.containsKey(value) ? value : items.keys.first;
    
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: DropdownButton<String>(
        value: validValue,
        items: items.entries.map((entry) {
          return DropdownMenuItem<String>(
            value: entry.key,
            child: Text(
              entry.value,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          );
        }).toList(),
        onChanged: (newValue) {
          if (newValue != null) {
            onChanged(newValue);
          }
        },
        dropdownColor: isDarkMode ? const Color(0xFF252525) : Colors.white,
        underline: Container(),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required Function(bool) onChanged,
    required bool isDarkMode,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.primaryOrange,
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required bool isDarkMode,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : AppTheme.primaryOrange,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive 
              ? Colors.red 
              : (isDarkMode ? Colors.white : Colors.black87),
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDarkMode ? Colors.white70 : Colors.black54,
          fontSize: 12,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDarkMode ? Colors.white70 : Colors.black54,
      ),
      onTap: onTap,
    );
  }
}
