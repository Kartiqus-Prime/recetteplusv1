import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../main.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/user_profile_service.dart';
import '../../../../core/models/user_profile.dart';

class EditProfilePage extends StatefulWidget {
  final UserProfile? currentProfile;

  const EditProfilePage({
    super.key,
    this.currentProfile,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final UserProfileService _profileService = UserProfileService();
  final ImagePicker _imagePicker = ImagePicker();

  String? _avatarUrl;
  bool _updating = false;
  bool _uploadingImage = false;
  bool _hasChanges = false;

  // Nom du bucket pour les photos de profil
  static const String PROFILE_BUCKET = 'user.profile.picture';

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    if (widget.currentProfile != null) {
      _displayNameController.text = widget.currentProfile!.displayName ?? '';
      _phoneController.text = widget.currentProfile!.phone ?? '';
      _bioController.text = widget.currentProfile!.bio ?? '';
      _avatarUrl = widget.currentProfile!.avatarUrl;
    }

    // Écouter les changements dans les champs
    _displayNameController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
    _bioController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    final hasChanges = _displayNameController.text.trim() !=
            (widget.currentProfile?.displayName ?? '') ||
        _phoneController.text.trim() != (widget.currentProfile?.phone ?? '') ||
        _bioController.text.trim() != (widget.currentProfile?.bio ?? '') ||
        _avatarUrl != widget.currentProfile?.avatarUrl;

    if (hasChanges != _hasChanges) {
      setState(() => _hasChanges = hasChanges);
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    try {
      setState(() => _uploadingImage = true);

      // Sélectionner une image
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) {
        setState(() => _uploadingImage = false);
        return;
      }

      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Lire le fichier
      final bytes = await image.readAsBytes();
      final fileExt = image.path.split('.').last.toLowerCase();
      final fileName =
          'avatar_${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      // Vérifier le type MIME
      String mimeType;
      switch (fileExt) {
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'png':
          mimeType = 'image/png';
          break;
        case 'gif':
          mimeType = 'image/gif';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
        default:
          throw Exception(
              'Format d\'image non supporté. Utilisez JPG, PNG, GIF ou WEBP.');
      }

      // Upload vers Supabase Storage avec le bon bucket
      await supabase.storage.from(PROFILE_BUCKET).uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(
              contentType: mimeType,
            ),
          );

      // Obtenir l'URL publique
      final publicUrl =
          supabase.storage.from(PROFILE_BUCKET).getPublicUrl(fileName);

      if (mounted) {
        setState(() {
          _avatarUrl = publicUrl;
          _uploadingImage = false;
        });
        _onFieldChanged(); // Déclencher la détection de changement
        context.showSnackBar('Photo de profil mise à jour !');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _uploadingImage = false);
        context.showSnackBar(
          'Erreur lors de l\'upload: ${error.toString()}',
          isError: true,
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _updating = true);

    try {
      final displayName = _displayNameController.text.trim();
      final phone = _phoneController.text.trim();
      final bio = _bioController.text.trim();

      // Validation des données
      await _profileService.validateProfileData(
        displayName: displayName,
        phone: phone,
        bio: bio,
      );

      // Mise à jour du profil
      final updatedProfile = await _profileService.updateProfile(
        displayName: displayName,
        phone: phone,
        bio: bio,
        avatarUrl: _avatarUrl,
      );

      if (updatedProfile != null && mounted) {
        context.showSnackBar('Profil mis à jour avec succès !');
        Navigator.of(context)
            .pop(updatedProfile); // Retourner le profil mis à jour
      }
    } catch (error) {
      if (mounted) {
        context.showSnackBar(error.toString(), isError: true);
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifications non sauvegardées'),
        content: const Text(
            'Vous avez des modifications non sauvegardées. Voulez-vous vraiment quitter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor:
            isDarkMode ? const Color(0xFF121212) : const Color(0xFFFAF9F6),
        appBar: AppBar(
          backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'Modifier le profil',
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
            onPressed: () async {
              if (await _onWillPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: _hasChanges && !_updating ? _updateProfile : null,
              child: Text(
                'Sauvegarder',
                style: TextStyle(
                  color: _hasChanges && !_updating
                      ? AppTheme.primaryOrange
                      : Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Avatar
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: isDarkMode
                              ? Colors.grey.shade800
                              : Colors.grey.shade100,
                          backgroundImage:
                              _avatarUrl != null && _avatarUrl!.isNotEmpty
                                  ? NetworkImage(_avatarUrl!)
                                  : null,
                          child: _avatarUrl == null || _avatarUrl!.isEmpty
                              ? Icon(
                                  Icons.person,
                                  size: 60,
                                  color: isDarkMode
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade500,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.primaryOrange,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDarkMode
                                    ? const Color(0xFF121212)
                                    : const Color(0xFFFAF9F6),
                                width: 3,
                              ),
                            ),
                            child: IconButton(
                              icon: _uploadingImage
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.camera_alt,
                                      color: Colors.white, size: 20),
                              onPressed:
                                  _uploadingImage ? null : _pickAndUploadImage,
                              constraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
                              ),
                              padding: const EdgeInsets.all(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Informations personnelles
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isDarkMode
                            ? Colors.grey.shade800
                            : Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                    color: isDarkMode ? const Color(0xFF252525) : Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Informations personnelles',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _displayNameController,
                            label: 'Nom d\'affichage',
                            icon: Icons.person_outline,
                            isDarkMode: isDarkMode,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Le nom d\'affichage est requis';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _phoneController,
                            label: 'Téléphone (optionnel)',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            isDarkMode: isDarkMode,
                            validator: (value) {
                              if (value != null && value.trim().isNotEmpty) {
                                final phoneRegex =
                                    RegExp(r'^\+223[0-9]{8}$|^[0-9]{8}$');
                                if (!phoneRegex.hasMatch(value.trim())) {
                                  return 'Format invalide (ex: +223XXXXXXXX)';
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _bioController,
                            label: 'Biographie (optionnel)',
                            icon: Icons.edit_outlined,
                            maxLines: 4,
                            isDarkMode: isDarkMode,
                            validator: (value) {
                              if (value != null && value.trim().length > 500) {
                                return 'Maximum 500 caractères';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_bioController.text.length}/500 caractères',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  isDarkMode ? Colors.white60 : Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Bouton de sauvegarde
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          _hasChanges && !_updating ? _updateProfile : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _hasChanges
                            ? AppTheme.primaryOrange
                            : Colors.grey.shade400,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _updating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _hasChanges
                                  ? 'Sauvegarder les modifications'
                                  : 'Aucune modification',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDarkMode,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(
        color: isDarkMode ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDarkMode ? Colors.white70 : Colors.black54,
        ),
        prefixIcon: Icon(
          icon,
          color: isDarkMode
              ? AppTheme.primaryOrange.withOpacity(0.7)
              : AppTheme.primaryOrange,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppTheme.primaryOrange,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: isDarkMode
            ? Colors.grey.shade800.withOpacity(0.3)
            : Colors.grey.shade50,
      ),
    );
  }
}
