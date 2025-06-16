import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/cart_service.dart';

class CartSelectionDialog extends StatefulWidget {
  final String recipeName;
  final String recipeId;
  final int servings;

  const CartSelectionDialog({
    Key? key,
    required this.recipeName,
    required this.recipeId,
    required this.servings,
  }) : super(key: key);

  @override
  State<CartSelectionDialog> createState() => _CartSelectionDialogState();
}

class _CartSelectionDialogState extends State<CartSelectionDialog> {
  final CartService _cartService = CartService();
  
  String _selectedOption = 'main';
  String? _selectedSubcartId;
  String _newSubcartName = '';
  int _newSubcartServings = 4;
  List<Map<String, dynamic>> _subcarts = [];
  bool _isLoading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _newSubcartName = widget.recipeName;
    _newSubcartServings = widget.servings;
    _loadSubcarts();
  }

  Future<void> _loadSubcarts() async {
    setState(() {
      _isLoading = true;
      _error = false;
    });

    try {
      final subcarts = await _cartService.getSubcarts();
      setState(() {
        _subcarts = subcarts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: Text(
        'Ajouter au panier',
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
      backgroundColor: isDarkMode ? const Color(0xFF252525) : Colors.white,
      content: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _error
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Erreur lors du chargement des sous-paniers',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadSubcarts,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryOrange,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOptionTile(
                        'main',
                        'Panier principal',
                        'Ajouter tous les ingrédients au panier principal',
                        Icons.shopping_cart,
                        isDarkMode,
                      ),
                      if (_subcarts.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildOptionTile(
                          'existing',
                          'Sous-panier existant',
                          'Ajouter à un sous-panier existant',
                          Icons.shopping_bag,
                          isDarkMode,
                        ),
                        if (_selectedOption == 'existing') ...[
                          const SizedBox(height: 16),
                          _buildSubcartDropdown(isDarkMode),
                        ],
                      ],
                      const SizedBox(height: 8),
                      _buildOptionTile(
                        'new',
                        'Nouveau sous-panier',
                        'Créer un nouveau sous-panier pour cette recette',
                        Icons.add_shopping_cart,
                        isDarkMode,
                      ),
                      if (_selectedOption == 'new') ...[
                        const SizedBox(height: 16),
                        _buildNewSubcartForm(isDarkMode),
                      ],
                    ],
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
        ElevatedButton(
          onPressed: _confirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryOrange,
            foregroundColor: Colors.white,
          ),
          child: const Text('Confirmer'),
        ),
      ],
    );
  }

  Widget _buildOptionTile(
    String value,
    String title,
    String subtitle,
    IconData icon,
    bool isDarkMode,
  ) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedOption = value;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _selectedOption == value
              ? (isDarkMode
                  ? AppTheme.primaryOrange.withOpacity(0.2)
                  : AppTheme.primaryOrange.withOpacity(0.1))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _selectedOption == value
                ? AppTheme.primaryOrange
                : isDarkMode
                    ? Colors.grey.shade700
                    : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: _selectedOption,
              onChanged: (value) {
                setState(() {
                  _selectedOption = value!;
                });
              },
              activeColor: AppTheme.primaryOrange,
            ),
            const SizedBox(width: 8),
            Icon(
              icon,
              color: _selectedOption == value
                  ? AppTheme.primaryOrange
                  : isDarkMode
                      ? Colors.white70
                      : Colors.black54,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubcartDropdown(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black12 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedSubcartId,
          hint: Text(
            'Sélectionner un sous-panier',
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
          isExpanded: true,
          dropdownColor: isDarkMode ? const Color(0xFF303030) : Colors.white,
          icon: Icon(
            Icons.arrow_drop_down,
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
          items: _subcarts.map((subcart) {
            return DropdownMenuItem<String>(
              value: subcart['id'],
              child: Text(
                subcart['name'] ?? 'Sous-panier sans nom',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedSubcartId = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildNewSubcartForm(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black12 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nom du sous-panier',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: TextEditingController(text: _newSubcartName),
            onChanged: (value) {
              _newSubcartName = value;
            },
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: 'Nom du sous-panier',
              hintStyle: TextStyle(
                color: isDarkMode ? Colors.white54 : Colors.black38,
              ),
              filled: true,
              fillColor: isDarkMode ? Colors.black26 : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: AppTheme.primaryOrange,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Nombre de portions',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  if (_newSubcartServings > 1) {
                    setState(() {
                      _newSubcartServings--;
                    });
                  }
                },
                icon: Icon(
                  Icons.remove_circle_outline,
                  color: _newSubcartServings > 1
                      ? AppTheme.primaryOrange
                      : isDarkMode
                          ? Colors.grey.shade700
                          : Colors.grey.shade400,
                ),
              ),
              Expanded(
                child: Text(
                  '$_newSubcartServings',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _newSubcartServings++;
                  });
                },
                icon: Icon(
                  Icons.add_circle_outline,
                  color: AppTheme.primaryOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirm() {
    final result = <String, dynamic>{
      'cartType': _selectedOption,
    };

    if (_selectedOption == 'existing') {
      if (_selectedSubcartId == null) {
        // Afficher un message d'erreur
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez sélectionner un sous-panier'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      result['subcartId'] = _selectedSubcartId;
    } else if (_selectedOption == 'new') {
      if (_newSubcartName.trim().isEmpty) {
        // Afficher un message d'erreur
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez entrer un nom pour le sous-panier'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      result['subcartName'] = _newSubcartName;
      result['servings'] = _newSubcartServings;
    }

    Navigator.of(context).pop(result);
  }
}
