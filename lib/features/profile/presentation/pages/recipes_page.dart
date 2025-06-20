import 'package:flutter/material.dart';
import '../../../../core/services/recipes_service.dart';
import '../../../../core/models/recipe.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/time_formatter.dart';
import '../../../profile/presentation/pages/recipe_detail_page.dart';

class RecipesPage extends StatefulWidget {
  const RecipesPage({super.key});

  @override
  State<RecipesPage> createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesPage> {
  final RecipesService _recipesService = RecipesService();
  List<Recipe> _recipes = [];
  List<Recipe> _filteredRecipes = [];
  bool _loading = true;
  String _searchQuery = '';
  String _selectedCategory = 'Toutes';
  String _selectedDifficulty = 'Toutes';
  String _selectedTime = 'Toutes';
  bool _showOnlyFavorites = false;

  final List<String> _categories = [
    'Toutes',
    'Entrées',
    'Plats principaux',
    'Desserts',
    'Boissons',
    'Snacks'
  ];

  final List<String> _difficulties = ['Toutes', 'Facile', 'Moyen', 'Difficile'];

  final List<String> _timeRanges = [
    'Toutes',
    '< 30 min',
    '30-60 min',
    '> 60 min'
  ];

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  @override
  void dispose() {
    // Nettoyer les ressources si nécessaire
    super.dispose();
  }

  Future<void> _loadRecipes() async {
    if (!mounted) return; // Correction ajoutée
    setState(() => _loading = true);
    try {
      final recipes = await _recipesService.getAllRecipes();
      if (!mounted) return; // Correction ajoutée
      setState(() {
        _recipes = recipes;
        _filteredRecipes = recipes;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return; // Correction ajoutée
      setState(() => _loading = false);
      if (mounted) {
        // Correction ajoutée
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _filterRecipes() {
    if (!mounted) return; // Correction ajoutée

    setState(() {
      _filteredRecipes = _recipes.where((recipe) {
        // Filtre par recherche
        if (_searchQuery.isNotEmpty &&
            !recipe.title.toLowerCase().contains(_searchQuery.toLowerCase())) {
          return false;
        }

        // Filtre par catégorie
        if (_selectedCategory != 'Toutes' &&
            recipe.categoryName != _selectedCategory) {
          return false;
        }

        // Filtre par difficulté
        if (_selectedDifficulty != 'Toutes' &&
            recipe.difficulty?.toLowerCase() !=
                _selectedDifficulty.toLowerCase()) {
          return false;
        }

        // Filtre par temps
        if (_selectedTime != 'Toutes') {
          final prepTime = _parseTimeToMinutes(recipe.prepTime.toString());
          switch (_selectedTime) {
            case '< 30 min':
              if (prepTime >= 30) return false;
              break;
            case '30-60 min':
              if (prepTime < 30 || prepTime > 60) return false;
              break;
            case '> 60 min':
              if (prepTime <= 60) return false;
              break;
          }
        }

        // Filtre par favoris
        if (_showOnlyFavorites && false) {
          return false;
        }

        return true;
      }).toList();
    });
  }

  int _parseTimeToMinutes(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length >= 2) {
        final hours = int.tryParse(parts[0]) ?? 0;
        final minutes = int.tryParse(parts[1]) ?? 0;
        return hours * 60 + minutes;
      }
    } catch (e) {
      // Ignore parsing errors
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF121212) : const Color(0xFFFAF9F6),
      appBar: AppBar(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Recettes',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              if (!mounted) return; // Correction ajoutée
              setState(() {
                _showOnlyFavorites = !_showOnlyFavorites;
                _filterRecipes();
              });
            },
            icon: Icon(
              _showOnlyFavorites ? Icons.favorite : Icons.favorite_border,
              color: _showOnlyFavorites
                  ? Colors.red
                  : (isDarkMode ? Colors.white : Colors.black87),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Container(
            padding: const EdgeInsets.all(16),
            color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            child: TextField(
              onChanged: (value) {
                if (!mounted) return; // Correction ajoutée
                setState(() {
                  _searchQuery = value;
                  _filterRecipes();
                });
              },
              decoration: InputDecoration(
                hintText: 'Rechercher une recette...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDarkMode
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFF5F5F5),
              ),
            ),
          ),

          // Filtres
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('Catégorie', _selectedCategory, _categories,
                    (value) {
                  if (!mounted) return; // Correction ajoutée
                  setState(() {
                    _selectedCategory = value;
                    _filterRecipes();
                  });
                }),
                const SizedBox(width: 8),
                _buildFilterChip(
                    'Difficulté', _selectedDifficulty, _difficulties, (value) {
                  if (!mounted) return; // Correction ajoutée
                  setState(() {
                    _selectedDifficulty = value;
                    _filterRecipes();
                  });
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Temps', _selectedTime, _timeRanges, (value) {
                  if (!mounted) return; // Correction ajoutée
                  setState(() {
                    _selectedTime = value;
                    _filterRecipes();
                  });
                }),
              ],
            ),
          ),

          // Liste des recettes
          Expanded(
            child: _loading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryOrange,
                    ),
                  )
                : _filteredRecipes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.restaurant_menu,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune recette trouvée',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadRecipes,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final screenWidth = constraints.maxWidth;
                            int crossAxisCount;
                            double childAspectRatio;
                            double cardPadding;
                            double iconSize;
                            double fontSize;

                            if (screenWidth > 1200) {
                              crossAxisCount = 4;
                              childAspectRatio = 0.75;
                              cardPadding = 8.0;
                              iconSize = 14.0;
                              fontSize = 12.0;
                            } else if (screenWidth > 800) {
                              crossAxisCount = 3;
                              childAspectRatio = 0.8;
                              cardPadding = 6.0;
                              iconSize = 14.0;
                              fontSize = 12.0;
                            } else if (screenWidth > 500) {
                              crossAxisCount = 2;
                              childAspectRatio = 0.85;
                              cardPadding = 4.0;
                              iconSize = 12.0;
                              fontSize = 10.0;
                            } else {
                              crossAxisCount = 1;
                              childAspectRatio = 1.2;
                              cardPadding = 4.0;
                              iconSize = 12.0;
                              fontSize = 10.0;
                            }

                            return GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                childAspectRatio: childAspectRatio,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: _filteredRecipes.length,
                              itemBuilder: (context, index) {
                                final recipe = _filteredRecipes[index];
                                return _buildRecipeCard(
                                  recipe,
                                  cardPadding,
                                  iconSize,
                                  fontSize,
                                  screenWidth < 500,
                                );
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String selectedValue,
      List<String> options, Function(String) onSelected) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      itemBuilder: (context) => options
          .map(
            (option) => PopupMenuItem(
              value: option,
              child: Text(option),
            ),
          )
          .toList(),
      child: Chip(
        label: Text(
          selectedValue == options.first ? label : selectedValue,
          style: const TextStyle(fontSize: 12),
        ),
        backgroundColor: selectedValue != options.first
            ? AppTheme.primaryOrange.withOpacity(0.1)
            : null,
      ),
    );
  }

  Widget _buildRecipeCard(Recipe recipe, double padding, double iconSize,
      double fontSize, bool isSmallCard) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailPage(recipe: recipe),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 6,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  color: Colors.grey[200],
                ),
                child: recipe.image != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12)),
                        child: Image.network(
                          recipe.image!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.restaurant,
                              size: 40,
                              color: Colors.grey[400]),
                        ),
                      )
                    : Icon(Icons.restaurant, size: 40, color: Colors.grey[400]),
              ),
            ),

            // Contenu
            Expanded(
              flex: 4,
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre
                    Flexible(
                      child: Text(
                        recipe.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: fontSize + 2,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Première ligne d'infos : Temps et Ingrédients
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            size: iconSize, color: AppTheme.primaryOrange),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            TimeFormatter.formatDuration(recipe.prepTime),
                            style: TextStyle(
                              fontSize: fontSize,
                              color:
                                  isDarkMode ? Colors.white70 : Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.restaurant_menu,
                            size: iconSize, color: AppTheme.primaryGreen),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${recipe.ingredients?.length ?? 0} ing.',
                            style: TextStyle(
                              fontSize: fontSize,
                              color:
                                  isDarkMode ? Colors.white70 : Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Deuxième ligne d'infos : Prix
                    Row(
                      children: [
                        // Prix total
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: recipe.canCalculateCost
                                ? AppTheme.primaryOrange.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: recipe.canCalculateCost
                                  ? AppTheme.primaryOrange.withOpacity(0.3)
                                  : Colors.grey.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'FCFA',
                            style: TextStyle(
                              fontSize: fontSize - 1,
                              fontWeight: FontWeight.w600,
                              color: recipe.canCalculateCost
                                  ? AppTheme.primaryOrange
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${recipe.canCalculateCost ? recipe.calculatedTotalCost.round() : recipe.estimatedCost?.round() ?? 0}',
                            style: TextStyle(
                              fontSize: fontSize,
                              fontWeight: FontWeight.bold,
                              color: recipe.canCalculateCost
                                  ? AppTheme.primaryOrange
                                  : Colors.grey[600],
                            ),
                          ),
                        ),

                        // Coût par portion (masqué sur très petites cartes)
                        if (!isSmallCard) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${recipe.costPerServing.round()}/p',
                              style: TextStyle(
                                fontSize: fontSize - 1,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
