import 'package:flutter/material.dart';
import '../../../../core/services/cart_service.dart';
import '../../../../core/models/cart_item.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/cart_item_card.dart';
import '../widgets/subcart_card.dart';
import '../widgets/empty_cart.dart';
import '../../../../core/extensions/toast_extensions.dart';
import 'subcart_detail_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage>
    with SingleTickerProviderStateMixin {
  final CartService _cartService = CartService();
  late TabController _tabController;
  bool _isLoading = true;
  List<CartItem> _cartItems = [];
  List<Map<String, dynamic>> _subcarts = [];
  double _totalPrice = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCartData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCartData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final cartItems = await _cartService.getCartItems();
      final subcarts = await _cartService.getSubcarts();

      double total = 0;
      for (var item in cartItems) {
        if (item.productPrice != null) {
          total += (item.productPrice! * item.quantity);
        }
      }

      setState(() {
        _cartItems = cartItems;
        _subcarts = subcarts;
        _totalPrice = total;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        context.showErrorToast('Erreur lors du chargement du panier');
      }
    }
  }

  Future<void> _updateCartItemQuantity(String cartItemId, int quantity) async {
    try {
      await _cartService.updateCartItemQuantity(
        cartItemId: cartItemId,
        quantity: quantity,
      );
      _loadCartData();
    } catch (e) {
      if (mounted) {
        context.showErrorToast('Erreur lors de la mise à jour de la quantité');
      }
    }
  }

  Future<void> _removeCartItem(String cartItemId) async {
    try {
      await _cartService.removeFromCart(cartItemId: cartItemId);
      _loadCartData();
      if (mounted) {
        context.showSuccessToast('Article supprimé du panier');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorToast('Erreur lors de la suppression de l\'article');
      }
    }
  }

  Future<void> _clearCart() async {
    try {
      await _cartService.clearCart();
      _loadCartData();
      if (mounted) {
        context.showSuccessToast('Panier vidé avec succès');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorToast('Erreur lors de la suppression du panier');
      }
    }
  }

  void _showClearCartConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vider le panier'),
        content: const Text('Êtes-vous sûr de vouloir vider votre panier ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearCart();
            },
            child: const Text('Vider'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Panier'),
        actions: [
          if (_cartItems.isNotEmpty && _tabController.index == 0)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _showClearCartConfirmation,
              tooltip: 'Vider le panier',
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Panier Principal'),
            Tab(text: 'Sous-Paniers'),
          ],
          labelColor: AppTheme.primaryOrange,
          unselectedLabelColor: isDarkMode ? Colors.white70 : Colors.black54,
          indicatorColor: AppTheme.primaryOrange,
          onTap: (index) {
            setState(() {}); // Pour mettre à jour les actions de l'AppBar
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMainCartTab(),
                _buildSubcartsTab(),
              ],
            ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildMainCartTab() {
    if (_cartItems.isEmpty) {
      return const EmptyCart(
        message: 'Votre panier est vide',
        subMessage: 'Ajoutez des articles depuis les recettes ou les produits',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCartData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _cartItems.length,
        itemBuilder: (context, index) {
          final item = _cartItems[index];
          return CartItemCard(
            cartItem: item,
            onQuantityChanged: (quantity) {
              _updateCartItemQuantity(item.id, quantity);
            },
            onRemove: () {
              _removeCartItem(item.id);
            },
          );
        },
      ),
    );
  }

  Widget _buildSubcartsTab() {
    if (_subcarts.isEmpty) {
      return const EmptyCart(
        message: 'Aucun sous-panier',
        subMessage: 'Créez des sous-paniers depuis les recettes',
        icon: Icons.shopping_basket_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCartData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _subcarts.length,
        itemBuilder: (context, index) {
          final subcart = _subcarts[index];
          return SubcartCard(
            subcart: subcart,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      SubcartDetailPage(subcartId: subcart['id']),
                ),
              ).then((_) => _loadCartData());
            },
          );
        },
      ),
    );
  }

  Widget _buildBottomBar() {
    if (_cartItems.isEmpty && _tabController.index == 0) {
      return const SizedBox.shrink();
    }

    if (_tabController.index == 1) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${_totalPrice.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _cartItems.isEmpty
                  ? null
                  : () {
                      // Naviguer vers la page de paiement
                      context.showSuccessToast(
                          'Fonctionnalité de paiement à venir');
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Commander'),
            ),
          ],
        ),
      ),
    );
  }
}
