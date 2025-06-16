import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../main.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/user_profile_service.dart';
import '../../../../core/services/user_stats_service.dart';
import '../../../../core/models/user_profile.dart';
import '../../../auth/presentation/pages/auth_page.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_stats.dart';
import '../widgets/profile_menu.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UserProfileService _profileService = UserProfileService();
  final UserStatsService _statsService = UserStatsService();
  
  UserProfile? _currentProfile;
  String? _avatarUrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _getProfile();
  }

  Future<void> _getProfile() async {
    setState(() => _loading = true);

    try {
      final profile = await _profileService.getCurrentUserProfile();
      if (profile != null && mounted) {
        setState(() {
          _currentProfile = profile;
          _avatarUrl = profile.avatarUrl;
        });
      }
    } catch (error) {
      if (mounted) {
        context.showSnackBar('Erreur lors du chargement du profil', isError: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showSignOutConfirmation() async {
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
            'Confirmation',
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Êtes-vous sûr de vouloir vous déconnecter ?',
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
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Se déconnecter'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      _signOut();
    }
  }

  Future<void> _signOut() async {
    try {
      await supabase.auth.signOut();
    } on AuthException catch (error) {
      if (mounted) context.showSnackBar(error.message, isError: true);
    } catch (error) {
      if (mounted) {
        context.showSnackBar('Erreur lors de la déconnexion', isError: true);
      }
    } finally {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AuthPage()),
        );
      }
    }
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
          'Mon Profil',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
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
                    // Header du profil avec bouton d'édition
                    ProfileHeader(
                      avatarUrl: _avatarUrl,
                      displayName: _currentProfile?.displayName ?? 'Utilisateur',
                      email: supabase.auth.currentUser?.email ?? '',
                      currentProfile: _currentProfile,
                      onAvatarUpload: (imageUrl) {
                        setState(() => _avatarUrl = imageUrl);
                      },
                      onProfileUpdated: () {
                        _getProfile(); // Recharger le profil après modification
                      },
                    ),
                    const SizedBox(height: 24),

                    // Statistiques (avec clé pour forcer le rafraîchissement)
                    ProfileStats(
                      key: ValueKey(_currentProfile?.updatedAt),
                      statsService: _statsService,
                    ),
                    const SizedBox(height: 24),

                    // Menu du profil
                    const ProfileMenu(),
                    
                    // Espacement avant le bouton de déconnexion
                    const SizedBox(height: 40),
                    
                    // Bouton de déconnexion (à la fin du contenu scrollable)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 20),
                      child: ElevatedButton.icon(
                        onPressed: _showSignOutConfirmation,
                        icon: const Icon(Icons.logout, size: 20),
                        label: const Text(
                          'Se déconnecter',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
