import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_theme.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;
    
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
          'À propos',
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec logo et illustration
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDarkMode 
                      ? const Color(0xFF1E1E1E) 
                      : Colors.white,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Logo de l'application
                    Image.asset(
                      'assets/images/logo.png',
                      height: 80,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Recette+',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'La cuisine malienne à portée de main',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Illustration
                    SvgPicture.asset(
                      'assets/images/food-illustration.svg',
                      height: 180,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Notre mission
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSection(
                  context: context,
                  title: 'Notre Mission',
                  icon: Icons.lightbulb_outline,
                  content: 'Recette+ a pour mission de faciliter l\'accès aux ingrédients de qualité et de promouvoir la cuisine malienne et internationale auprès des foyers maliens. Nous croyons que la bonne cuisine devrait être accessible à tous.',
                  isDarkMode: isDarkMode,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Nos services
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSection(
                  context: context,
                  title: 'Nos Services',
                  icon: Icons.room_service_outlined,
                  content: '',
                  isDarkMode: isDarkMode,
                  children: [
                    _buildServiceItem(
                      icon: Icons.menu_book_outlined,
                      title: 'Recettes Inspirantes',
                      description: 'Découvrez des centaines de recettes maliennes et internationales adaptées aux goûts locaux.',
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(height: 16),
                    _buildServiceItem(
                      icon: Icons.shopping_basket_outlined,
                      title: 'Commande d\'Ingrédients',
                      description: 'Commandez tous les ingrédients nécessaires pour vos recettes préférées en quelques clics.',
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(height: 16),
                    _buildServiceItem(
                      icon: Icons.videocam_outlined,
                      title: 'Vidéos Tutorielles',
                      description: 'Apprenez avec nos vidéos pas à pas pour maîtriser chaque technique culinaire.',
                      isDarkMode: isDarkMode,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Notre histoire
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSection(
                  context: context,
                  title: 'Notre Histoire',
                  icon: Icons.history_edu_outlined,
                  content: 'Fondée à Bamako en 2023, Recette+ est née de la passion pour la cuisine et du désir de simplifier l\'accès aux ingrédients de qualité au Mali. Notre équipe de passionnés travaille chaque jour pour vous offrir la meilleure expérience culinaire possible.',
                  isDarkMode: isDarkMode,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Zone de service
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSection(
                  context: context,
                  title: 'Zone de Service',
                  icon: Icons.location_on_outlined,
                  content: 'Actuellement, Recette+ est disponible exclusivement au Mali, avec une couverture complète à Bamako et dans les principales villes du pays. Nous travaillons à étendre notre réseau pour servir davantage de régions.',
                  isDarkMode: isDarkMode,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Illustration finale
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.favorite,
                        color: AppTheme.primaryOrange,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Merci de faire partie de notre communauté !',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Pied de page
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                color: isDarkMode 
                    ? const Color(0xFF1E1E1E) 
                    : Colors.white,
                child: Column(
                  children: [
                    Text(
                      '© 2023 Recette+ | Tous droits réservés',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bamako, Mali',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required String content,
    required bool isDarkMode,
    List<Widget> children = const [],
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
            if (content.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                content,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
            if (children.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...children,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildServiceItem({
    required IconData icon,
    required String title,
    required String description,
    required bool isDarkMode,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryOrange,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
