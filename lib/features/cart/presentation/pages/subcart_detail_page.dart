import 'package:flutter/material.dart';
import '../../../../core/services/subcart_service.dart';
import '../../../../core/models/cart_item.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/cart_item_card.dart';
import '../widgets/empty_cart.dart';
import '../../../../core/extensions/toast_extensions.dart';

class SubcartDetailPage extends StatefulWidget {
  final String subcartId;

  const SubcartDetailPage({super.key, required this.subcartId});

  @override
  State<SubcartDetailPage> createState() => _SubcartDetailPageState();
}

class _SubcartDetailPageState extends State<SubcartDetailPage> {
  final SubcartService _subcartService = SubcartService();
  bool _isLoading = true;
  Map<String, dynamic>? _subcart;
  List<CartItem> _subcartItems = [];
  double _totalPrice = 0;

  @override
  void initState() {
    super.initState();
    _loadSubcartData();
  }

  Future<void> _loadSubcartData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final subcart = await _subcartService.getSubcartDetails(widget.subcartId);
      final subcartItems = await _subcartService.getSubcartItems(widget.subcartId);
      
      double total = 0;
      for (var item in subcartItems) {
        if (item.productPrice != null) {
          total += (item.productPrice! * item.quantity);
        }
      }

      setState(() {
        _subcart = subcart;
        _subcartItems = subcartItems;
        _totalPrice = total;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        context.showErrorToast('Erreur lors du chargement du sous-panier');
      }
    }
  }

  Future<void> _updateCartItemQuantity(String cartItemId, int quantity) async {
    try {
      await _subcartService.updateSubcartItemQuantity(
        cartItemId: cartItemId,
        quantity: quantity,
      );
      _loadSubcartData();
    } catch (e) {
      if (mounted) {
        context.showErrorToast('Erreur lors de la mise à jour de la quantité');
      }
    }
  }

  Future<void> _removeCartItem(String cartItemId) async {
    try {
      await _subcartService.removeFromSubcart(cartItemId: cartItemId);
      _loadSubcartData();
      if (mounted) {
        context.showSuccessToast('Article supprimé du sous-panier');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorToast('Erreur lors de la suppression de l\'article');
      }
    }
  }

  Future<void> _deleteSubcart() async {
    try {
      await _subcartService.deleteSubcart(widget.subcartId);
      if (mounted) {
        context.showSuccessToast('Sous-panier supprimé');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        context.showErrorToast('Erreur lors de la suppression du sous-panier');
      }
    }
  }

  Future<void> _moveAllToMainCart() async {
    try {
      await _subcartService.moveAllToMainCart(widget.subcartId);
      if (mounted) {
        context.showSuccessToast('Articles déplacés vers le panier principal');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        context.showErrorToast('Erreur lors du déplacement des articles');
      }
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le sous-panier'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce sous-panier et tous ses articles ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSubcart();
            },
            child: const Text('Supprimer'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  void _showMoveToMainCartConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déplacer vers le panier principal'),
        content: const Text('Déplacer tous les articles vers le panier principal ? Le sous-panier sera supprimé.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _moveAllToMainCart();
            },
            child: const Text('Déplacer'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryOrange,
            ),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog() {
    final TextEditingController controller = TextEditingController(text: _subcart?['name']);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renommer le sous-panier'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nom du sous-panier',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _renameSubcart(controller.text);
            },
            child: const Text('Renommer'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryOrange,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _renameSubcart(String newName) async {
    try {
      await _subcartService.renameSubcart(
        subcartId: widget.subcartId,
        name: newName,
      );
      _loadSubcartData();
      if (mounted) {
        context.showSuccessToast('Sous-panier renommé');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorToast('Erreur lors du renommage du sous-panier');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoading ? 'Chargement...' : _subcart?['name'] ?? 'Sous-panier'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'rename':
                  _showRenameDialog();
                  break;
                case 'move':
                  _showMoveToMainCartConfirmation();
                  break;
                case 'delete':
                  _showDeleteConfirmation();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'rename',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('Renommer'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'move',
                child: Row(
                  children: [
                    Icon(Icons.shopping_cart, size: 20),
                    SizedBox(width: 8),
                    Text('Déplacer vers le panier principal'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Supprimer', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _subcartItems.isEmpty
              ? const EmptyCart(
                  message: 'Sous-panier vide',
                  subMessage: 'Ce sous-panier ne contient aucun article',
                )
              : RefreshIndicator(
                  onRefresh: _loadSubcartData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _subcartItems.length,
                    itemBuilder: (context, index) {
                      final item = _subcartItems[index];
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
                ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    if (_subcartItems.isEmpty) {
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
              onPressed: _showMoveToMainCartConfirmation,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Déplacer vers le panier principal'),
            ),
          ],
        ),
      ),
    );
  }
}
