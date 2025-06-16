import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/recipe.dart';
import '../../../../core/services/favorites_service.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/services/cart_service.dart';
import '../../../../core/services/videos_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../cart/presentation/widgets/cart_selection_dialog.dart';

class RecipeDetailPage extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailPage({
    super.key,
    required this.recipe,
  });

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  final FavoritesService _favoritesService = FavoritesService();
  final CartService _cartService = CartService();
  final VideosService _videosService = VideosService();
  bool _isFavorite = false;
  bool _isLoading = false;
  bool _isAddingToCart = false;
  bool _isAddingAllToCart = false;
  Map<String, bool> _expandedIngredients = {};

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
    // Initialiser tous les ingrédients comme non-développés
    if (widget.recipe.ingredients != null) {
      for (var ingredient in widget.recipe.ingredients!) {
        _expandedIngredients[ingredient.id] = false;
      }
    }
  }

  Future<void> _checkIfFavorite() async {
    try {
      final result = await _favoritesService.isFavorite(
        recipeId: widget.recipe.id,
      );
      if (mounted) {
        setState(() {
          _isFavorite = result;
        });
      }
    } catch (e) {
      // Ignorer l'erreur
    }
  }

  Future<void> _toggleFavorite() async {
    setState(() => _isLoading = true);
    try {
      final result = await _favoritesService.toggleFavorite(
        recipeId: widget.recipe.id,
      );
      if (mounted) {
        setState(() {
          _isFavorite = result;
          _isLoading = false;
        });
        context.showSnackBar(
          result ? 'Ajouté aux favoris' : 'Retiré des favoris',
        );
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar(
          'Erreur lors de la modification des favoris',
          isError: true,
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addProductToCart(RecipeProduct product) async {
    setState(() => _isAddingToCart = true);
    try {
      await _cartService.addToCart(
        productId: product.productId,
        quantity: 1,
      );
      if (mounted) {
        context.showSnackBar('Produit ajouté au panier');
        setState(() => _isAddingToCart = false);
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar(
          'Erreur lors de l\'ajout au panier',
          isError: true,
        );
        setState(() => _isAddingToCart = false);
      }
    }
  }

  Future<void> _addIngredientToCart(RecipeIngredient ingredient) async {
    if (ingredient.productId == null) {
      context.showSnackBar('Ce produit n\'est pas disponible à l\'achat',
          isError: true);
      return;
    }

    setState(() => _isAddingToCart = true);
    try {
      await _cartService.addToCart(
        productId: ingredient.productId!,
        quantity: ingredient.quantity.toInt(),
      );
      if (mounted) {
        context.showSnackBar('${ingredient.name} ajouté au panier');
        setState(() => _isAddingToCart = false);
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar(
          'Erreur lors de l\'ajout au panier',
          isError: true,
        );
        setState(() => _isAddingToCart = false);
      }
    }
  }

  Future<void> _addAllIngredientsToCart() async {
    final ingredients = widget.recipe.ingredients;
    if (ingredients == null || ingredients.isEmpty) {
      context.showSnackBar('Aucun ingrédient disponible', isError: true);
      return;
    }

    // Afficher le dialogue de sélection du panier
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => CartSelectionDialog(
        recipeName: widget.recipe.title,
        recipeId: widget.recipe.id,
        servings: widget.recipe.servings ?? 4,
      ),
    );

    if (result == null) return; // L'utilisateur a annulé

    setState(() => _isAddingAllToCart = true);
    try {
      final cartType = result['cartType'];

      if (cartType == 'main') {
        // Ajouter au panier principal
        for (final ingredient in ingredients) {
          if (ingredient.productId != null) {
            await _cartService.addToCart(
              productId: ingredient.productId!,
              quantity: ingredient.quantity.toInt(),
            );
          }
        }
        if (mounted) {
          context.showSnackBar(
              'Tous les ingrédients ont été ajoutés au panier principal');
        }
      } else if (cartType == 'existing') {
        // Ajouter à un sous-panier existant
        final subcartId = result['subcartId'];
        final ingredientsData = ingredients
            .map((ingredient) => {
                  'product_id': ingredient.productId,
                  'quantity': ingredient.quantity.toInt(),
                })
            .toList();

        await _cartService.addRecipeIngredientsToSubcart(
          recipeId: widget.recipe.id,
          subcartId: subcartId,
          ingredients: ingredientsData,
        );

        if (mounted) {
          context.showSnackBar(
              'Tous les ingrédients ont été ajoutés au sous-panier');
        }
      } else if (cartType == 'new') {
        // Créer un nouveau sous-panier
        final subcartName = result['subcartName'];
        final servings = result['servings'];

        final subcartId = await _cartService.createSubcartFromRecipe(
          recipeName: subcartName ?? widget.recipe.title,
          recipeId: widget.recipe.id,
          servings: servings,
        );

        final ingredientsData = ingredients
            .map((ingredient) => {
                  'product_id': ingredient.productId,
                  'quantity': ingredient.quantity.toInt(),
                })
            .toList();

        await _cartService.addRecipeIngredientsToSubcart(
          recipeId: widget.recipe.id,
          subcartId: subcartId,
          ingredients: ingredientsData,
        );

        if (mounted) {
          context.showSnackBar('Nouveau sous-panier créé avec les ingrédients');
        }
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar(
          'Erreur lors de l\'ajout des ingrédients au panier: ${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAddingAllToCart = false);
      }
    }
  }

  void _toggleIngredientExpanded(String ingredientId) {
    setState(() {
      _expandedIngredients[ingredientId] =
          !(_expandedIngredients[ingredientId] ?? false);
    });
  }

  Future<void> _viewVideo() async {
    if (widget.recipe.videoUrl == null) {
      context.showSnackBar('Aucune vidéo disponible pour cette recette',
          isError: true);
      return;
    }

    final videoUrl = widget.recipe.videoUrl!;

    // Essayer d'ouvrir l'URL directement
    try {
      final uri = Uri.parse(videoUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          context.showSnackBar('Impossible d\'ouvrir la vidéo', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar(
          'Erreur lors de l\'ouverture de la vidéo: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final recipe = widget.recipe;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF121212) : const Color(0xFFFAF9F6),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(recipe, isDarkMode),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMediumScreen ? 16 : 24,
                vertical: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRecipeHeader(recipe, isDarkMode),
                  const SizedBox(height: 24),
                  _buildRecipeInfo(recipe, isDarkMode, isSmallScreen),
                  const SizedBox(height: 24),
                  _buildCostBreakdown(recipe, isDarkMode, isMediumScreen),
                  const SizedBox(height: 24),
                  _buildIngredients(recipe, isDarkMode, isMediumScreen),
                  const SizedBox(height: 24),
                  _buildInstructions(recipe, isDarkMode),
                  if (recipe.nutrition != null &&
                      recipe.nutrition!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildNutrition(recipe, isDarkMode, isMediumScreen),
                  ],
                  if (recipe.tags != null && recipe.tags!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildTags(recipe, isDarkMode),
                  ],
                  if (recipe.relatedProducts != null &&
                      recipe.relatedProducts!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildRelatedProducts(recipe, isDarkMode, isMediumScreen),
                  ],
                  if (recipe.videoUrl != null) ...[
                    const SizedBox(height: 24),
                    _buildVideoSection(recipe, isDarkMode),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (recipe.ingredients != null && recipe.ingredients!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: FloatingActionButton(
                heroTag: "addToCartBtn",
                onPressed: _isAddingAllToCart ? null : _addAllIngredientsToCart,
                backgroundColor: AppTheme.primaryOrange,
                child: _isAddingAllToCart
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.shopping_cart,
                        color: Colors.white,
                      ),
              ),
            ),
          FloatingActionButton(
            heroTag: "favoriteBtn",
            onPressed: _isLoading ? null : _toggleFavorite,
            backgroundColor: _isFavorite ? Colors.red : AppTheme.primaryOrange,
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: Colors.white,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(Recipe recipe, bool isDarkMode) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black26,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: recipe.image != null && recipe.image!.isNotEmpty
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
                      size: 80,
                      color: isDarkMode ? Colors.white38 : Colors.black26,
                    ),
                  );
                },
              )
            : Container(
                color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
                child: Icon(
                  Icons.restaurant,
                  size: 80,
                  color: isDarkMode ? Colors.white38 : Colors.black26,
                ),
              ),
      ),
    );
  }

  Widget _buildRecipeHeader(Recipe recipe, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          recipe.title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        if (recipe.categoryName != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.category,
                size: 16,
                color: isDarkMode ? Colors.white54 : Colors.black45,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Catégorie: ${recipe.categoryName}',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
        if (recipe.description != null) ...[
          const SizedBox(height: 16),
          Text(
            recipe.description!,
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRecipeInfo(Recipe recipe, bool isDarkMode, bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF252525) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.spaceAround,
            spacing: isSmallScreen ? 8 : 16,
            runSpacing: 16,
            children: [
              _buildInfoItem(
                icon: Icons.timer,
                label: 'Préparation',
                value: recipe.prepTime ?? 'N/A',
                isDarkMode: isDarkMode,
                isSmallScreen: isSmallScreen,
              ),
              _buildInfoItem(
                icon: Icons.whatshot,
                label: 'Cuisson',
                value: recipe.cookTime ?? 'N/A',
                isDarkMode: isDarkMode,
                isSmallScreen: isSmallScreen,
              ),
              _buildInfoItem(
                icon: Icons.access_time,
                label: 'Total',
                value: recipe.totalTime ?? 'N/A',
                isDarkMode: isDarkMode,
                isSmallScreen: isSmallScreen,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.spaceAround,
            spacing: isSmallScreen ? 8 : 16,
            runSpacing: 16,
            children: [
              _buildInfoItem(
                icon: Icons.people,
                label: 'Portions',
                value: recipe.servings != null
                    ? recipe.servings.toString()
                    : 'N/A',
                isDarkMode: isDarkMode,
                isSmallScreen: isSmallScreen,
              ),
              _buildInfoItem(
                icon: Icons.person,
                label: 'Coût/portion',
                value: recipe.canCalculateCost
                    ? recipe.formattedCostPerServing
                    : 'N/A',
                isDarkMode: isDarkMode,
                valueColor: Colors.green,
                isSmallScreen: isSmallScreen,
              ),
              _buildInfoItem(
                icon: Icons.trending_up,
                label: 'Difficulté',
                value: recipe.difficultyLevel ?? 'N/A',
                isDarkMode: isDarkMode,
                isSmallScreen: isSmallScreen,
              ),
              _buildInfoItem(
                icon: Icons.euro,
                label: 'Coût total',
                value: recipe.canCalculateCost
                    ? recipe.formattedCalculatedCost
                    : (recipe.formattedEstimatedCost != 'Non spécifié'
                        ? recipe.formattedEstimatedCost
                        : 'N/A'),
                isDarkMode: isDarkMode,
                valueColor: AppTheme.primaryOrange,
                isSmallScreen: isSmallScreen,
              ),
            ],
          ),
          if (recipe.rating != null) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...List.generate(5, (index) {
                  return Icon(
                    index < (recipe.rating ?? 0).floor()
                        ? Icons.star
                        : index < (recipe.rating ?? 0)
                            ? Icons.star_half
                            : Icons.star_border,
                    color: Colors.amber,
                    size: 24,
                  );
                }),
                const SizedBox(width: 8),
                Text(
                  '${recipe.rating!.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required bool isDarkMode,
    required bool isSmallScreen,
    Color? valueColor,
  }) {
    return SizedBox(
      width: isSmallScreen ? 90 : 100,
      child: Column(
        children: [
          Icon(
            icon,
            color: isDarkMode ? Colors.white70 : Colors.black54,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.white54 : Colors.black45,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor ?? (isDarkMode ? Colors.white : Colors.black87),
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildIngredients(
      Recipe recipe, bool isDarkMode, bool isMediumScreen) {
    final ingredients = recipe.ingredients ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ingrédients',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            if (recipe.servings != null)
              Text(
                'Pour ${recipe.servings} personne${recipe.servings! > 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF252525) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
            ),
          ),
          child: ingredients.isEmpty
              ? Center(
                  child: Text(
                    'Aucun ingrédient disponible',
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                )
              : Column(
                  children: ingredients.map((ingredient) {
                    final isExpanded =
                        _expandedIngredients[ingredient.id] ?? false;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: ingredient.productId != null
                            ? () => _toggleIngredientExpanded(ingredient.id)
                            : null,
                        borderRadius: BorderRadius.circular(8),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(top: 6),
                                  decoration: BoxDecoration(
                                    color: ingredient.optional ?? false
                                        ? Colors.grey
                                        : AppTheme.primaryOrange,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: RichText(
                                              text: TextSpan(
                                                children: [
                                                  TextSpan(
                                                    text:
                                                        '${ingredient.formattedQuantity} ',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: isDarkMode
                                                          ? Colors.white70
                                                          : Colors.black87,
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text: ingredient.name,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color: isDarkMode
                                                          ? Colors.white70
                                                          : Colors.black87,
                                                      fontStyle: ingredient
                                                                  .optional ??
                                                              false
                                                          ? FontStyle.italic
                                                          : FontStyle.normal,
                                                    ),
                                                  ),
                                                  if (ingredient.optional ??
                                                      false)
                                                    TextSpan(
                                                      text: ' (optionnel)',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontStyle:
                                                            FontStyle.italic,
                                                        color: isDarkMode
                                                            ? Colors.white54
                                                            : Colors.black45,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          if (ingredient.productId != null)
                                            Icon(
                                              isExpanded
                                                  ? Icons.keyboard_arrow_up
                                                  : Icons.keyboard_arrow_down,
                                              color: isDarkMode
                                                  ? Colors.white54
                                                  : Colors.black45,
                                            ),
                                        ],
                                      ),
                                      if (ingredient.notes != null &&
                                          ingredient.notes!.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          ingredient.notes!,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontStyle: FontStyle.italic,
                                            color: isDarkMode
                                                ? Colors.white54
                                                : Colors.black45,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            // Aperçu du produit si développé
                            if (isExpanded && ingredient.productId != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? Colors.black12
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Image du produit
                                    if (ingredient.productImage != null)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: SizedBox(
                                          width: 80,
                                          height: 80,
                                          child: Image.network(
                                            ingredient.productImage!,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                color: isDarkMode
                                                    ? Colors.grey.shade800
                                                    : Colors.grey.shade300,
                                                child: Icon(
                                                  Icons.image_not_supported,
                                                  size: 30,
                                                  color: isDarkMode
                                                      ? Colors.white38
                                                      : Colors.black26,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      )
                                    else
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: isDarkMode
                                              ? Colors.grey.shade800
                                              : Colors.grey.shade300,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.shopping_basket,
                                          size: 30,
                                          color: isDarkMode
                                              ? Colors.white38
                                              : Colors.black26,
                                        ),
                                      ),
                                    const SizedBox(width: 12),
                                    // Informations du produit
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            ingredient.name,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors.black87,
                                            ),
                                          ),
                                          if (ingredient.productPrice !=
                                              null) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              '${ingredient.productPrice!.toStringAsFixed(0)} FCFA',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.primaryOrange,
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 8),
                                          ElevatedButton.icon(
                                            onPressed: () =>
                                                _addIngredientToCart(
                                                    ingredient),
                                            icon: Icon(Icons.add_shopping_cart,
                                                size: 18),
                                            label: Text('Ajouter au panier'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppTheme.primaryOrange,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8),
                                              textStyle:
                                                  const TextStyle(fontSize: 14),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildInstructions(Recipe recipe, bool isDarkMode) {
    final instructions = recipe.instructions ?? [];

    if (instructions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Instructions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF252525) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
            ),
          ),
          child: Column(
            children: instructions.asMap().entries.map((entry) {
              final index = entry.key;
              final instruction = entry.value;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryOrange,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        instruction,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode ? Colors.white70 : Colors.black87,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildNutrition(Recipe recipe, bool isDarkMode, bool isMediumScreen) {
    final nutrition = recipe.nutrition;

    if (nutrition == null || nutrition.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculer le nombre d'éléments par ligne en fonction de la taille de l'écran
    final itemsPerRow = isMediumScreen ? 3 : 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations nutritionnelles',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF252525) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
            ),
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: itemsPerRow,
              childAspectRatio: 0.8,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: nutrition.length,
            itemBuilder: (context, index) {
              final entry = nutrition.entries.elementAt(index);
              String value = entry.value.toString();
              String unit = '';

              // Déterminer l'unité en fonction de la clé
              if (entry.key.toLowerCase().contains('calories')) {
                unit = ' kcal';
              } else if (entry.key.toLowerCase().contains('proteines') ||
                  entry.key.toLowerCase().contains('lipides') ||
                  entry.key.toLowerCase().contains('glucides') ||
                  entry.key.toLowerCase().contains('fibres')) {
                unit = ' g';
              }

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _getNutritionColor(entry.key, isDarkMode),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    entry.key,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    unit,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getNutritionColor(String key, bool isDarkMode) {
    key = key.toLowerCase();
    if (key.contains('calories')) {
      return Colors.red.shade400;
    } else if (key.contains('proteines')) {
      return Colors.green.shade400;
    } else if (key.contains('lipides')) {
      return Colors.amber.shade400;
    } else if (key.contains('glucides')) {
      return Colors.blue.shade400;
    } else if (key.contains('fibres')) {
      return Colors.purple.shade400;
    } else {
      return isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300;
    }
  }

  Widget _buildTags(Recipe recipe, bool isDarkMode) {
    final tags = recipe.tags ?? [];

    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags.map((tag) {
            return Chip(
              label: Text(
                tag,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              backgroundColor:
                  isDarkMode ? const Color(0xFF252525) : Colors.grey.shade200,
              side: BorderSide(
                color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRelatedProducts(
      Recipe recipe, bool isDarkMode, bool isMediumScreen) {
    final relatedProducts = recipe.relatedProducts ?? [];

    if (relatedProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Produits associés',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: relatedProducts.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final product = relatedProducts[index];

              return Container(
                width: isMediumScreen ? 120 : 150,
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF252525) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDarkMode
                        ? Colors.grey.shade800
                        : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12)),
                        child: product.image != null
                            ? Image.network(
                                product.image!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: isDarkMode
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade300,
                                    child: Icon(
                                      Icons.image_not_supported,
                                      size: 40,
                                      color: isDarkMode
                                          ? Colors.white38
                                          : Colors.black26,
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: isDarkMode
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade300,
                                child: Icon(
                                  Icons.shopping_basket,
                                  size: 40,
                                  color: isDarkMode
                                      ? Colors.white38
                                      : Colors.black26,
                                ),
                              ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        product.name.toString(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVideoSection(Recipe recipe, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vidéo',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: _viewVideo,
          child: Container(
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF252525) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.play_circle_fill,
                    size: 40,
                    color: AppTheme.primaryOrange,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Regarder la vidéo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCostBreakdown(
      Recipe recipe, bool isDarkMode, bool isMediumScreen) {
    if (!recipe.canCalculateCost) {
      return const SizedBox.shrink();
    }

    final ingredientsWithPrice = recipe.ingredients!
        .where((ingredient) => ingredient.productPrice != null)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Détail des coûts',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primaryOrange.withOpacity(0.3),
                ),
              ),
              child: Text(
                '${recipe.ingredientPriceCompleteness.toStringAsFixed(0)}% des prix disponibles',
                style: TextStyle(
                  color: AppTheme.primaryOrange,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF252525) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
            ),
          ),
          child: Column(
            children: [
              // Liste des ingrédients avec prix
              ...ingredientsWithPrice.map((ingredient) {
                final totalPrice =
                    ingredient.productPrice! * ingredient.quantity;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          ingredient.name,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          ingredient.formattedQuantity,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.white54 : Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${ingredient.productPrice!.toStringAsFixed(0)} FCFA',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.white54 : Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${totalPrice.toStringAsFixed(0)} FCFA',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryOrange,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),

              // Séparateur
              if (ingredientsWithPrice.isNotEmpty) ...[
                const SizedBox(height: 12),
                Divider(
                  color:
                      isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                ),
                const SizedBox(height: 12),
              ],

              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Coût total estimé',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    recipe.formattedCalculatedCost,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryOrange,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Coût par portion
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Coût par portion',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  Text(
                    recipe.formattedCostPerServing,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),

              // Note sur les prix manquants
              if (recipe.ingredientPriceCompleteness < 100) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.amber.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.amber.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Certains prix d\'ingrédients ne sont pas disponibles. Le coût réel peut être différent.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
