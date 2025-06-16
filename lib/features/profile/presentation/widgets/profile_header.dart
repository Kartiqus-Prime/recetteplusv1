import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/user_profile.dart';
import '../pages/edit_profile_page.dart';

class ProfileHeader extends StatelessWidget {
  final String? avatarUrl;
  final String displayName;
  final String email;
  final UserProfile? currentProfile;
  final Function(String) onAvatarUpload;
  final VoidCallback? onProfileUpdated;

  const ProfileHeader({
    super.key,
    required this.avatarUrl,
    required this.displayName,
    required this.email,
    required this.onAvatarUpload,
    this.currentProfile,
    this.onProfileUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
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
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar sans icône d'édition
              CircleAvatar(
                radius: 50,
                backgroundColor: isDarkMode 
                    ? Colors.grey.shade800 
                    : Colors.grey.shade100,
                backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                    ? NetworkImage(avatarUrl!)
                    : null,
                child: avatarUrl == null || avatarUrl!.isEmpty
                    ? Icon(
                        Icons.person,
                        size: 50,
                        color: isDarkMode 
                            ? Colors.grey.shade400 
                            : Colors.grey.shade500,
                      )
                    : null,
              ),
              const SizedBox(height: 20),

              // Nom d'utilisateur
              Text(
                displayName.isNotEmpty ? displayName : 'Utilisateur',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 6),

              // Email
              Text(
                email,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 16),

              // Bouton d'édition du profil
              OutlinedButton.icon(
                onPressed: () async {
                  final updatedProfile = await Navigator.of(context).push<UserProfile>(
                    MaterialPageRoute(
                      builder: (context) => EditProfilePage(
                        currentProfile: currentProfile,
                      ),
                    ),
                  );
                  
                  if (updatedProfile != null && onProfileUpdated != null) {
                    onProfileUpdated!();
                  }
                },
                icon: Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: AppTheme.primaryOrange,
                ),
                label: Text(
                  'Modifier le profil',
                  style: TextStyle(
                    color: AppTheme.primaryOrange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppTheme.primaryOrange),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
