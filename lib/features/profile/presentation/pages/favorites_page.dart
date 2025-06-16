import 'package:flutter/material.dart';
import '../../../../core/models/favorite.dart';
import '../../../../core/services/favorites_service.dart';
import '../../../../core/theme/app_theme.dart';
import 'recipe_detail_page.dart';
import 'product_detail_page.dart';
import 'video_detail_page.dart';
import '../../../../core/models/recipe.dart';
import '../../../../core/models/product.dart';
import '../../../../core/models/video.dart';
import '../../../../core/services/recipes_service.dart';
import '../../../../core/services/products_service.dart';
import '../../../../core/services/videos_service.dart';
import '../../../../core/extensions/toast_extensions.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> with SingleTickerProviderStateMixin {
  final FavoritesService _favoritesService = FavoritesService();
  final RecipesService _recipesService = RecipesService();
  final ProductsService _productsService = ProductsService();
  final VideosService _videosService = VideosService();
  
  List<Favorite>? _favorites;
  bool _isLoading = true;
  String? _error;
  
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadFavorites();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final favorites = await _favoritesService.getUserFavorites();
      if (mounted) {
        setState(() {
          _favorites = favorites;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Impossible de charger les favoris';
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _removeFavorite(String favoriteId) async {
    try {
      await _favoritesService.removeFavorite(favoriteId);
      if (mounted) {
        setState(() {
          _favorites?.removeWhere((favorite) => favorite.id == favoriteId);
        });
        context.showSuccessToast('Favori supprimé', icon: Icons.delete);
      }
    } catch (e) {
      if (mounted) {
        context.showErrorToast('Erreur lors de la suppression du favori');
      }
    }
  }
  
  Future<void> _showRecipeDetails(String recipeId) async {
    try {
      final recipe = await _recipesService.getRecipeById(recipeId);
      if (recipe != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailPage(recipe: recipe),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        context.showErrorToast('Erreur lors du chargement de la recette');
      }
    }
  }

  Future<void> _showProductDetails(String productId) async {
    try {
      final product = await _productsService.getProductById(productId);
      if (product != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(productId: productId),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        context.showErrorToast('Erreur lors du chargement du produit');
      }
    }
  }

  Future<void> _showVideoDetails(String videoId) async {
    try {
      final video = await _videosService.getVideoById(videoId);
      if (video != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoDetailPage(videoId: videoId),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        context.showErrorToast('Erreur lors du chargement de la vidéo');
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
        title: const Text('Mes favoris'),
        backgroundColor: isDarkMode 
            ? const Color(0xFF1E1E1E) 
            : Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryOrange,
          unselectedLabelColor: isDarkMode ? Colors.white70 : Colors.black54,
          indicatorColor: AppTheme.primaryOrange,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Tous'),
            Tab(text: 'Produits'),
            Tab(text: 'Recettes'),
            Tab(text: 'Vidéos'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadFavorites,
        color: AppTheme.primaryOrange,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildFavoritesList(null, isDarkMode),
            _buildFavoritesList('product', isDarkMode),
            _buildFavoritesList('recipe', isDarkMode),
            _buildFavoritesList('video', isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesList(String? type, bool isDarkMode) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryOrange),
            ),
            const SizedBox(height: 16),
            Text(
              'Chargement des favoris...',
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
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
              _error!,
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadFavorites,
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

    final filteredFavorites = _favorites?.where((favorite) {
      if (type == null) return true;
      if (type == 'product') return favorite.productId != null;
      if (type == 'recipe') return favorite.recipeId != null;
      if (type == 'video') return favorite.videoId != null;
      return false;
    }).toList();

    if (filteredFavorites == null || filteredFavorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 64,
              color: isDarkMode ? Colors.white38 : Colors.black26,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun favori trouvé',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              type == null
                  ? 'Ajoutez des favoris pour les retrouver ici'
                  : type == 'product'
                      ? 'Ajoutez des produits en favoris'
                      : type == 'recipe'
                          ? 'Ajoutez des recettes en favoris'
                          : 'Ajoutez des vidéos en favoris',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredFavorites.length,
      itemBuilder: (context, index) {
        final favorite = filteredFavorites[index];
        return _buildFavoriteCard(favorite, isDarkMode);
      },
    );
  }

  Widget _buildFavoriteCard(Favorite favorite, bool isDarkMode) {
    IconData typeIcon;
    String typeText;
    Color typeColor;
    
    if (favorite.productId != null) {
      typeIcon = Icons.shopping_bag;
      typeText = 'Produit';
      typeColor = Colors.blue;
    } else if (favorite.recipeId != null) {
      typeIcon = Icons.restaurant_menu;
      typeText = 'Recette';
      typeColor = Colors.green;
    } else if (favorite.videoId != null) {
      typeIcon = Icons.play_circle_fill;
      typeText = 'Vidéo';
      typeColor = Colors.purple;
    } else {
      typeIcon = Icons.star;
      typeText = 'Favori';
      typeColor = AppTheme.primaryOrange;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
          width: 1,
        ),
      ),
      color: isDarkMode ? const Color(0xFF252525) : Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          if (favorite.recipeId != null) {
            _showRecipeDetails(favorite.recipeId!);
          } else if (favorite.productId != null) {
            _showProductDetails(favorite.productId!);
          } else if (favorite.videoId != null) {
            _showVideoDetails(favorite.videoId!);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image ou icône
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: favorite.itemImage != null && favorite.itemImage!.isNotEmpty
                    ? Image.network(
                        favorite.itemImage!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 80,
                            height: 80,
                            color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryOrange),
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80,
                            height: 80,
                            color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
                            child: Icon(
                              typeIcon,
                              size: 40,
                              color: isDarkMode ? Colors.white38 : Colors.black26,
                            ),
                          );
                        },
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          typeIcon,
                          size: 40,
                          color: isDarkMode ? Colors.white38 : Colors.black26,
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              // Contenu
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            favorite.itemName ?? 'Sans nom',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: typeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            typeText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: typeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (favorite.itemDescription != null && favorite.itemDescription!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        favorite.itemDescription!,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (favorite.itemPrice != null)
                          Text(
                            '${favorite.itemPrice!.toStringAsFixed(0)} FCFA',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryOrange,
                            ),
                          )
                        else
                          const SizedBox.shrink(),
                        const Spacer(),
                        Text(
                          _formatDate(favorite.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? Colors.white54 : Colors.black45,
                          ),
                        ),
                        const SizedBox(width: 16),
                        InkWell(
                          onTap: () => _showDeleteConfirmation(favorite),
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: Colors.red.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ],
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

  void _showDeleteConfirmation(Favorite favorite) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF252525) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          'Supprimer des favoris',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "${favorite.itemName ?? 'cet élément'}" de vos favoris ?',
          style: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Annuler',
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _removeFavorite(favorite.id);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'Il y a ${difference.inMinutes} min';
      }
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else {
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year;
      return '$day/$month/$year';
    }
  }
}
