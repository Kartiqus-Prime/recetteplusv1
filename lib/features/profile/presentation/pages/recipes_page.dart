import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/recipe.dart';
import '../../../../core/services/recipes_service.dart';
import '../../../../core/utils/time_formatter.dart';
import 'recipe_detail_page.dart';

class RecipesPage extends StatefulWidget {
  const RecipesPage({super.key});

  @override
  State<RecipesPage> createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesPage>
    with SingleTickerProviderStateMixin {
  final RecipesService _recipesService = RecipesService();

  List<Recipe>? _favoriteRecipes;
  List<Recipe>? _allRecipes;
  bool _isLoadingFavorites = true;
  bool _isLoadingAll = true;
  String? _errorFavorites;
  String? _errorAll;

  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<Recipe>? _searchResults;
  bool _isLoadingSearch = false;

  // Filtres
  String? _selectedCategory;
  String? _selectedDifficulty;
  RangeValues? _prepTimeRange;
  bool _showFilters = false;
  List<String> _categories = [];
  List<String> _difficulties = ['Facile', 'Moyen', 'Difficile'];
  RangeValues _timeRange = const RangeValues(0, 120);
  double _maxPrepTime = 120;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFavoriteRecipes();
    _loadAllRecipes();
    _loadCategories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      setState(() {
        _categories = [
          'Entrée',
          'Plat principal',
          'Dessert',
          'Boisson',
          'Apéritif'
        ];
      });
    } catch (e) {
      // Gérer l'erreur
    }
  }

  Future<void> _loadFavoriteRecipes() async {
    if (mounted) {
      setState(() {
        _isLoadingFavorites = true;
        _errorFavorites = null;
      });
    }

    try {
      final recipes = await _recipesService.getUserFavoriteRecipes();
      if (mounted) {
        setState(() {
          _favoriteRecipes = recipes;
          _isLoadingFavorites = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorFavorites = 'Impossible de charger les recettes favorites';
          _isLoadingFavorites = false;
        });
      }
    }
  }

  Future<void> _loadAllRecipes() async {
    if (mounted) {
      setState(() {
        _isLoadingAll = true;
        _errorAll = null;
      });
    }

    try {
      final recipes = await _recipesService.getAllRecipes();
      if (mounted) {
        setState(() {
          _allRecipes = recipes;
          _isLoadingAll = false;

          // Déterminer le temps de préparation maximum pour le filtre
          if (recipes.isNotEmpty) {
            double maxTime = 120;
            for (var recipe in recipes) {
              if (recipe.totalTime != null) {
                final minutes = TimeFormatter.extractMinutes(recipe.totalTime!);
                if (minutes > maxTime) {
                  maxTime = minutes.toDouble();
                }
              }
            }
            _maxPrepTime = maxTime;
            _timeRange = RangeValues(0, maxTime);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorAll = 'Impossible de charger les recettes';
          _isLoadingAll = false;
        });
      }
    }
  }

  Future<void> _searchRecipes(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _isLoadingSearch = true;
    });

    try {
      final results = await _recipesService.searchRecipes(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoadingSearch = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isLoadingSearch = false;
        });
      }
    }
  }

  void _showRecipeDetails(Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailPage(recipe: recipe),
      ),
    ).then((_) {
      _loadFavoriteRecipes();
    });
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
  }

  List<Recipe> _filterRecipes(List<Recipe> recipes) {
    if (_selectedCategory == null &&
        _selectedDifficulty == null &&
        _prepTimeRange == null) {
      return recipes;
    }

    return recipes.where((recipe) {
      // Filtre par catégorie
      if (_selectedCategory != null &&
          recipe.categoryName != _selectedCategory) {
        return false;
      }

      // Filtre par difficulté
      if (_selectedDifficulty != null) {
        final difficulty = recipe.difficulty?.toLowerCase() ?? '';
        final selectedDiff = _selectedDifficulty!.toLowerCase();

        if (!(difficulty == selectedDiff ||
            (difficulty == 'easy' && selectedDiff == 'facile') ||
            (difficulty == 'medium' && selectedDiff == 'moyen') ||
            (difficulty == 'hard' && selectedDiff == 'difficile'))) {
          return false;
        }
      }

      // Filtre par temps de préparation
      if (_prepTimeRange != null && recipe.totalTime != null) {
        final minutes = TimeFormatter.extractMinutes(recipe.totalTime!);
        if (minutes < _prepTimeRange!.start ||
            minutes > _prepTimeRange!.end) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _applyFilters() {
    setState(() {
      _showFilters = false;
    });
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedDifficulty = null;
      _prepTimeRange = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF121212) : const Color(0xFFFAF9F6),
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher des recettes...',
                  hintStyle: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  border: InputBorder.none,
                ),
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                onChanged: (value) {
                  _searchRecipes(value);
                },
                autofocus: true,
              )
            : const Text('Recettes'),
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  _searchResults = null;
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          if (!_isSearching)
            IconButton(
              icon: Icon(
                  _showFilters ? Icons.filter_list_off : Icons.filter_list),
              onPressed: _toggleFilters,
              tooltip: 'Filtrer les recettes',
            ),
        ],
        bottom: _isSearching
            ? null
            : TabBar(
                controller: _tabController,
                labelColor: AppTheme.primaryOrange,
                unselectedLabelColor:
                    isDarkMode ? Colors.white70 : Colors.black54,
                indicatorColor: AppTheme.primaryOrange,
                tabs: const [
                  Tab(text: 'Mes favoris'),
                  Tab(text: 'Toutes les recettes'),
                ],
              ),
      ),
      body: Column(
        children: [
          if (_showFilters) _buildFiltersSection(isDarkMode),
          Expanded(
            child: _isSearching
                ? _buildSearchResults(isDarkMode)
                : TabBarView(
                    controller: _tabController,
                    children: [
                      RefreshIndicator(
                        onRefresh: _loadFavoriteRecipes,
                        color: AppTheme.primaryOrange,
                        child: _buildFavoriteRecipesList(isDarkMode),
                      ),
                      RefreshIndicator(
                        onRefresh: _loadAllRecipes,
                        color: AppTheme.primaryOrange,
                        child: _buildAllRecipesList(isDarkMode),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filtres',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleFilters,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildDropdownFilter(
                label: 'Catégorie',
                value: _selectedCategory,
                items: _categories,
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                isDarkMode: isDarkMode,
              ),
              _buildDropdownFilter(
                label: 'Difficulté',
                value: _selectedDifficulty,
                items: _difficulties,
                onChanged: (value) {
                  setState(() {
                    _selectedDifficulty = value;
                  });
                },
                isDarkMode: isDarkMode,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Temps de préparation (min)',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '0',
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.white54 : Colors.black45,
                ),
              ),
              Expanded(
                child: RangeSlider(
                  values: _prepTimeRange ?? _timeRange,
                  min: 0,
                  max: _maxPrepTime,
                  divisions: _maxPrepTime > 120 ? 12 : 6,
                  activeColor: AppTheme.primaryOrange,
                  inactiveColor:
                      isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
                  labels: RangeLabels(
                    (_prepTimeRange?.start ?? _timeRange.start)
                        .round()
                        .toString(),
                    (_prepTimeRange?.end ?? _timeRange.end).round().toString(),
                  ),
                  onChanged: (values) {
                    setState(() {
                      _prepTimeRange = values;
                    });
                  },
                ),
              ),
              Text(
                _maxPrepTime.round().toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.white54 : Colors.black45,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _resetFilters,
                child: Text(
                  'Réinitialiser',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryOrange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Appliquer'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required bool isDarkMode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF252525) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
            ),
          ),
          child: DropdownButton<String>(
            value: value,
            hint: Text(
              'Sélectionner',
              style: TextStyle(
                color: isDarkMode ? Colors.white54 : Colors.black45,
              ),
            ),
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: isDarkMode ? const Color(0xFF252525) : Colors.white,
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults(bool isDarkMode) {
    if (_isLoadingSearch) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_searchResults == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: isDarkMode ? Colors.white38 : Colors.black26,
            ),
            const SizedBox(height: 16),
            Text(
              'Recherchez des recettes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: isDarkMode ? Colors.white38 : Colors.black26,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun résultat trouvé',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez avec d\'autres mots-clés',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    final filteredRecipes = _filterRecipes(_searchResults!);
    return _buildRecipeGrid(filteredRecipes, isDarkMode);
  }

  Widget _buildFavoriteRecipesList(bool isDarkMode) {
    if (_isLoadingFavorites) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorFavorites != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _errorFavorites!,
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadFavoriteRecipes,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_favoriteRecipes == null || _favoriteRecipes!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 64,
              color: isDarkMode ? Colors.white38 : Colors.black26,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune recette favorite',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez des recettes à vos favoris\npour les retrouver ici',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    final filteredRecipes = _filterRecipes(_favoriteRecipes!);
    return _buildRecipeGrid(filteredRecipes, isDarkMode);
  }

  Widget _buildAllRecipesList(bool isDarkMode) {
    if (_isLoadingAll) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorAll != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _errorAll!,
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadAllRecipes,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_allRecipes == null || _allRecipes!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 64,
              color: isDarkMode ? Colors.white38 : Colors.black26,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune recette disponible',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Revenez plus tard pour découvrir\nde nouvelles recettes',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    final filteredRecipes = _filterRecipes(_allRecipes!);
    if (filteredRecipes.isEmpty &&
        (_selectedCategory != null ||
            _selectedDifficulty != null ||
            _prepTimeRange != null)) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_list_off,
              size: 64,
              color: isDarkMode ? Colors.white38 : Colors.black26,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune recette ne correspond aux filtres',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _resetFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Réinitialiser les filtres'),
            ),
          ],
        ),
      );
    }

    return _buildRecipeGrid(filteredRecipes, isDarkMode);
  }

  Widget _buildRecipeGrid(List<Recipe> recipes, bool isDarkMode) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calcul dynamique du nombre de colonnes basé sur la largeur
        int crossAxisCount;
        double cardWidth;
        
        if (constraints.maxWidth > 1200) {
          crossAxisCount = 4;
          cardWidth = (constraints.maxWidth - 80) / 4; // 80 = padding + spacing
        } else if (constraints.maxWidth > 800) {
          crossAxisCount = 3;
          cardWidth = (constraints.maxWidth - 64) / 3; // 64 = padding + spacing
        } else if (constraints.maxWidth > 500) {
          crossAxisCount = 2;
          cardWidth = (constraints.maxWidth - 48) / 2; // 48 = padding + spacing
        } else {
          crossAxisCount = 1;
          cardWidth = constraints.maxWidth - 32; // 32 = padding
        }

        // Calcul de l'aspect ratio basé sur la largeur de la carte
        double aspectRatio = cardWidth > 200 ? 0.75 : 0.7;

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: aspectRatio,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: recipes.length,
          itemBuilder: (context, index) {
            final recipe = recipes[index];
            return _buildRecipeCard(recipe, isDarkMode, cardWidth);
          },
        );
      },
    );
  }

  Widget _buildRecipeCard(Recipe recipe, bool isDarkMode, double cardWidth) {
    final formattedTime = TimeFormatter.formatDuration(recipe.totalTime);
    final bool isSmallCard = cardWidth < 180;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
          width: 1,
        ),
      ),
      color: isDarkMode ? const Color(0xFF252525) : Colors.white,
      child: InkWell(
        onTap: () => _showRecipeDetails(recipe),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image avec ratio fixe
            Expanded(
              flex: isSmallCard ? 3 : 4,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Container(
                  width: double.infinity,
                  child: recipe.image != null && recipe.image!.isNotEmpty
                      ? Image.network(
                          recipe.image!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: isDarkMode
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade300,
                              child: Icon(
                                Icons.restaurant,
                                size: isSmallCard ? 32 : 40,
                                color: isDarkMode ? Colors.white38 : Colors.black26,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: isDarkMode
                              ? Colors.grey.shade800
                              : Colors.grey.shade300,
                          child: Icon(
                            Icons.restaurant,
                            size: isSmallCard ? 32 : 40,
                            color: isDarkMode ? Colors.white38 : Colors.black26,
                          ),
                        ),
                ),
              ),
            ),

            // Contenu avec flex pour éviter l'overflow
            Expanded(
              flex: isSmallCard ? 2 : 3,
              child: Padding(
                padding: EdgeInsets.all(isSmallCard ? 8 : 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre avec hauteur flexible
                    Expanded(
                      flex: 2,
                      child: Text(
                        recipe.title,
                        style: TextStyle(
                          fontSize: isSmallCard ? 12 : 14,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Catégorie (optionnelle)
                    if (recipe.categoryName != null && !isSmallCard)
                      Text(
                        recipe.categoryName!,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.primaryOrange,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    
                    const Spacer(),
                    
                    // Informations en bas
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Première ligne : Temps et ingrédients
                        Row(
                          children: [
                            if (formattedTime.isNotEmpty)
                              Expanded(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: isSmallCard ? 12 : 14,
                                      color: isDarkMode ? Colors.white54 : Colors.black45,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        formattedTime,
                                        style: TextStyle(
                                          fontSize: isSmallCard ? 10 : 12,
                                          color: isDarkMode ? Colors.white54 : Colors.black45,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            
                            if (recipe.ingredients != null && recipe.ingredients!.isNotEmpty)
                              Text(
                                '${recipe.ingredients!.length} ing.',
                                style: TextStyle(
                                  fontSize: isSmallCard ? 10 : 12,
                                  color: isDarkMode ? Colors.white54 : Colors.black45,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // Deuxième ligne : Coûts
                        Row(
                          children: [
                            if (recipe.canCalculateCost || recipe.estimatedCost != null)
                              Expanded(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: recipe.canCalculateCost 
                                            ? AppTheme.primaryOrange.withOpacity(0.1)
                                            : Colors.grey.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'FCFA',
                                        style: TextStyle(
                                          fontSize: isSmallCard ? 8 : 9,
                                          fontWeight: FontWeight.bold,
                                          color: recipe.canCalculateCost 
                                              ? AppTheme.primaryOrange 
                                              : Colors.grey,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        recipe.canCalculateCost
                                            ? recipe.formattedCalculatedCost
                                            : recipe.formattedEstimatedCost,
                                        style: TextStyle(
                                          fontSize: isSmallCard ? 10 : 12,
                                          fontWeight: recipe.canCalculateCost 
                                              ? FontWeight.bold 
                                              : FontWeight.w500,
                                          color: recipe.canCalculateCost
                                              ? AppTheme.primaryOrange
                                              : Colors.grey,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            
                            if (recipe.canCalculateCost && !isSmallCard)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  recipe.formattedCostPerServing,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
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
