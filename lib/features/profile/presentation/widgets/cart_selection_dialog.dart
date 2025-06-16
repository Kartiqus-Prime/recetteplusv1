import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class CartSelectionDialog extends StatefulWidget {
  final List<Map<String, dynamic>> subcarts;
  final String recipeName;
  final int defaultServings;
  final Function(String?) onSubcartSelected;
  final Function(String, int) onNewSubcartCreated;
  final VoidCallback onMainCartSelected;

  const CartSelectionDialog({
    super.key,
    required this.subcarts,
    required this.recipeName,
    required this.defaultServings,
    required this.onSubcartSelected,
    required this.onNewSubcartCreated,
    required this.onMainCartSelected,
  });

  @override
  State<CartSelectionDialog> createState() => _CartSelectionDialogState();
}

class _CartSelectionDialogState extends State<CartSelectionDialog> {
  String _selectedOption = 'main';
  String? _selectedSubcartId;
  final TextEditingController _nameController = TextEditingController();
  int _servings = 4;

  @override
  void initState() {
    super.initState();
    _nameController.text = 'Recette: ${widget.recipeName}';
    _servings = widget.defaultServings;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter au panier'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOptionTile(
              title: 'Panier principal',
              subtitle: 'Ajouter tous les ingrédients au panier principal',
              value: 'main',
              icon: Icons.shopping_cart_outlined,
            ),
            if (widget.subcarts.isNotEmpty) ...[
              _buildOptionTile(
                title: 'Sous-panier existant',
                subtitle: 'Ajouter à un sous-panier existant',
                value: 'existing',
                icon: Icons.shopping_basket_outlined,
              ),
              if (_selectedOption == 'existing')
                _buildSubcartDropdown(),
            ],
            _buildOptionTile(
              title: 'Nouveau sous-panier',
              subtitle: 'Créer un nouveau sous-panier pour cette recette',
              value: 'new',
              icon: Icons.add_shopping_cart_outlined,
            ),
            if (_selectedOption == 'new')
              _buildNewSubcartForm(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            if (_selectedOption == 'main') {
              widget.onMainCartSelected();
            } else if (_selectedOption == 'existing' && _selectedSubcartId != null) {
              widget.onSubcartSelected(_selectedSubcartId);
            } else if (_selectedOption == 'new') {
              widget.onNewSubcartCreated(_nameController.text, _servings);
            }
          },
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.primaryOrange,
          ),
          child: const Text('Ajouter'),
        ),
      ],
    );
  }

  Widget _buildOptionTile({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
  }) {
    return RadioListTile<String>(
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      value: value,
      groupValue: _selectedOption,
      onChanged: (newValue) {
        setState(() {
          _selectedOption = newValue!;
        });
      },
      secondary: Icon(icon, color: AppTheme.primaryOrange),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSubcartDropdown() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 8, bottom: 16),
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          labelText: 'Sélectionner un sous-panier',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        value: _selectedSubcartId,
        items: widget.subcarts.map((subcart) {
          return DropdownMenuItem<String>(
            value: subcart['id'],
            child: Text(
              subcart['name'] ?? 'Sous-panier sans nom',
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedSubcartId = value;
          });
        },
      ),
    );
  }

  Widget _buildNewSubcartForm() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nom du sous-panier',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Nombre de portions:'),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: _servings > 1
                    ? () {
                        setState(() {
                          _servings--;
                        });
                      }
                    : null,
              ),
              Text(
                '$_servings',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  setState(() {
                    _servings++;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
