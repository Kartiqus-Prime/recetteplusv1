import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../main.dart';
import '../../../../core/extensions/context_extensions.dart';

class SocialAuthButton extends StatefulWidget {
  final String provider;
  final Color color;

  const SocialAuthButton({
    super.key,
    required this.provider,
    required this.color,
  });

  @override
  State<SocialAuthButton> createState() => _SocialAuthButtonState();
}

class _SocialAuthButtonState extends State<SocialAuthButton> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      // Utiliser l'authentification native sur Android
      final googleClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'];
      
      if (googleClientId == null) {
        throw Exception('GOOGLE_WEB_CLIENT_ID non défini dans .env');
      }

      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.flutterquickstart://login-callback/',
        queryParams: {
          'access_type': 'offline',
          'prompt': 'consent',
        },
        authScreenLaunchMode: LaunchMode.platformDefault, // Utilise le mode natif si disponible
      );
    } catch (error) {
      if (mounted) {
        context.showSnackBar(
          'Erreur lors de la connexion avec Google: ${error.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: widget.color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(
                Icons.g_translate_rounded,
                size: 30,
                color: Color(0xFF4285F4), // Couleur officielle de Google
              ),
        onPressed: _isLoading ? null : _handleGoogleSignIn,
      ),
    );
  }
}
