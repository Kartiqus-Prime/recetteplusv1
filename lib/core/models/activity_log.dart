import 'package:flutter/material.dart';
import 'dart:convert';

enum ActivityType {
  login,
  registration,
  profileUpdate,
  recipeCreated,
  recipeUpdated,
  recipeDeleted,
  favoriteAdded,
  favoriteRemoved,
  settingsChanged,
  themeChanged,
  passwordChanged,
  productViewed,
  cartUpdated,
  orderPlaced,
  cartCreated,
  cartDeleted,
  productCreated,
  productUpdated,
  productDeleted,
  productAddedToCart,
  productRemovedFromCart,
  productQuantityChanged,
  other
}

class ActivityLog {
  final String id;
  final String userId;
  final ActivityType type;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  final String? entityId;
  final String? entityType;
  final String? ipAddress;
  final String? deviceInfo;
  final String? sessionId;
  final String? actionDescription;
  final String? location;

  const ActivityLog({
    required this.id,
    required this.userId,
    required this.type,
    required this.timestamp,
    required this.metadata,
    this.entityId,
    this.entityType,
    this.ipAddress,
    this.deviceInfo,
    this.sessionId,
    this.actionDescription,
    this.location,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      type: _parseActivityType(
          json['action_type'], json['entity_type'], json['metadata']),
      timestamp: DateTime.parse(json['created_at']),
      metadata: parseMetadataStatic(json['metadata']),
      entityId: json['entity_id'],
      entityType: json['entity_type'],
      ipAddress: json['ip_address'],
      deviceInfo: json['user_agent'],
      sessionId: json['session_id'],
      actionDescription: json['action_description'],
      location: json['location'],
    );
  }

  static Map<String, dynamic> parseMetadataStatic(dynamic metadata) {
    if (metadata == null) return {};
    if (metadata is Map<String, dynamic>) return metadata;
    if (metadata is String) {
      try {
        // Essayer de parser le JSON
        return Map<String, dynamic>.from(json.decode(metadata));
      } catch (e) {
        // Si ce n'est pas du JSON valide, essayer de parser comme une chaîne de requête
        try {
          final cleaned = metadata
              .replaceAll('{', '')
              .replaceAll('}', '')
              .replaceAll('"', '');
          final pairs = cleaned.split(', ');
          final result = <String, dynamic>{};

          for (final pair in pairs) {
            final keyValue = pair.split(': ');
            if (keyValue.length == 2) {
              final key = keyValue[0].trim();
              final value = keyValue[1].trim();

              // Essayer de convertir en nombre si possible
              if (int.tryParse(value) != null) {
                result[key] = int.parse(value);
              } else if (double.tryParse(value) != null) {
                result[key] = double.parse(value);
              } else {
                result[key] = value;
              }
            }
          }

          return result;
        } catch (e2) {
          return {'raw': metadata};
        }
      }
    }
    return {};
  }

  static ActivityType _parseActivityType(
      String? actionType, String? entityType, dynamic metadata) {
    if (actionType == null) return ActivityType.other;
    
    final type = actionType.toLowerCase();
    final entity = entityType?.toLowerCase() ?? '';
    final parsedMetadata = parseMetadataStatic(metadata);

    // Cas spécial pour les opérations sur les produits dans le panier
    if (entity == 'cart' && parsedMetadata.containsKey('product_id')) {
      switch (type) {
        case 'create':
          return ActivityType.productAddedToCart;
        case 'update':
          return ActivityType.productQuantityChanged;
        case 'delete':
          return ActivityType.productRemovedFromCart;
      }
    }

    switch (type) {
      case 'login':
        return ActivityType.login;
      case 'register':
      case 'registration':
        return ActivityType.registration;
      case 'profile_update':
        return ActivityType.profileUpdate;
      case 'create':
        switch (entity) {
          case 'recipes':
            return ActivityType.recipeCreated;
          case 'cart':
            return ActivityType.cartCreated;
          case 'products':
            return ActivityType.productCreated;
          default:
            return ActivityType.other;
        }
      case 'update':
        switch (entity) {
          case 'recipes':
            return ActivityType.recipeUpdated;
          case 'cart':
            return ActivityType.cartUpdated;
          case 'products':
            return ActivityType.productUpdated;
          default:
            return ActivityType.other;
        }
      case 'delete':
        switch (entity) {
          case 'recipes':
            return ActivityType.recipeDeleted;
          case 'cart':
            return ActivityType.cartDeleted;
          case 'products':
            return ActivityType.productDeleted;
          default:
            return ActivityType.other;
        }
      case 'favorite':
      case 'favorite_added':
        return ActivityType.favoriteAdded;
      case 'unfavorite':
      case 'favorite_removed':
        return ActivityType.favoriteRemoved;
      case 'settings_changed':
        return ActivityType.settingsChanged;
      case 'theme_changed':
        return ActivityType.themeChanged;
      case 'password_changed':
        return ActivityType.passwordChanged;
      case 'view':
        if (entity == 'products') return ActivityType.productViewed;
        return ActivityType.other;
      case 'order_placed':
        return ActivityType.orderPlaced;
      default:
        return ActivityType.other;
    }
  }

  static String getDisplayNameForType(String actionType, [String? entityType]) {
    final type = actionType.toLowerCase();
    final entity = entityType?.toLowerCase() ?? '';

    switch (type) {
      case 'login':
        return 'Connexions';
      case 'register':
      case 'registration':
        return 'Inscriptions';
      case 'profile_update':
        return 'Profil mis à jour';
      case 'create':
        switch (entity) {
          case 'recipes':
            return 'Recettes créées';
          case 'cart':
            return 'Paniers créés';
          case 'products':
            return 'Produits créés';
          default:
            return 'Créations';
        }
      case 'update':
        switch (entity) {
          case 'recipes':
            return 'Recettes modifiées';
          case 'cart':
            return 'Panier modifié';
          case 'products':
            return 'Produits modifiés';
          default:
            return 'Modifications';
        }
      case 'delete':
        switch (entity) {
          case 'recipes':
            return 'Recettes supprimées';
          case 'cart':
            return 'Paniers supprimés';
          case 'products':
            return 'Produits supprimés';
          default:
            return 'Suppressions';
        }
      case 'favorite':
      case 'favorite_added':
        return 'Favoris ajoutés';
      case 'unfavorite':
      case 'favorite_removed':
        return 'Favoris retirés';
      case 'settings_changed':
        return 'Paramètres modifiés';
      case 'theme_changed':
        return 'Thème modifié';
      case 'password_changed':
        return 'Mot de passe modifié';
      case 'view':
        if (entity == 'products') return 'Produits consultés';
        return 'Consultations';
      case 'order_placed':
        return 'Commandes passées';
      default:
        return 'Autres activités';
    }
  }

  static String getDisplayNameForCartProductOperation(String actionType) {
    switch (actionType.toLowerCase()) {
      case 'create':
        return 'Produits ajoutés au panier';
      case 'update':
        return 'Quantités modifiées';
      case 'delete':
        return 'Produits retirés du panier';
      default:
        return 'Opérations sur les produits';
    }
  }

  String get typeDisplayName {
    switch (type) {
      case ActivityType.login:
        return 'Connexion';
      case ActivityType.registration:
        return 'Inscription';
      case ActivityType.profileUpdate:
        return 'Profil mis à jour';
      case ActivityType.recipeCreated:
        return 'Recette créée';
      case ActivityType.recipeUpdated:
        return 'Recette modifiée';
      case ActivityType.recipeDeleted:
        return 'Recette supprimée';
      case ActivityType.favoriteAdded:
        return 'Favori ajouté';
      case ActivityType.favoriteRemoved:
        return 'Favori retiré';
      case ActivityType.settingsChanged:
        return 'Paramètres modifiés';
      case ActivityType.themeChanged:
        return 'Thème modifié';
      case ActivityType.passwordChanged:
        return 'Mot de passe modifié';
      case ActivityType.productViewed:
        return 'Produit consulté';
      case ActivityType.cartUpdated:
        return 'Panier modifié';
      case ActivityType.cartCreated:
        return 'Panier créé';
      case ActivityType.cartDeleted:
        return 'Panier supprimé';
      case ActivityType.productCreated:
        return 'Produit créé';
      case ActivityType.productUpdated:
        return 'Produit modifié';
      case ActivityType.productDeleted:
        return 'Produit supprimé';
      case ActivityType.productAddedToCart:
        return 'Produit ajouté au panier';
      case ActivityType.productRemovedFromCart:
        return 'Produit retiré du panier';
      case ActivityType.productQuantityChanged:
        return 'Quantité modifiée';
      case ActivityType.orderPlaced:
        return 'Commande passée';
      case ActivityType.other:
        return 'Autre activité';
    }
  }

  IconData get typeIcon {
    switch (type) {
      case ActivityType.login:
        return Icons.login;
      case ActivityType.registration:
        return Icons.person_add;
      case ActivityType.profileUpdate:
        return Icons.edit;
      case ActivityType.recipeCreated:
        return Icons.add_circle;
      case ActivityType.recipeUpdated:
        return Icons.edit_note;
      case ActivityType.recipeDeleted:
        return Icons.delete;
      case ActivityType.favoriteAdded:
        return Icons.favorite;
      case ActivityType.favoriteRemoved:
        return Icons.favorite_border;
      case ActivityType.settingsChanged:
        return Icons.settings;
      case ActivityType.themeChanged:
        return Icons.palette;
      case ActivityType.passwordChanged:
        return Icons.password;
      case ActivityType.productViewed:
        return Icons.visibility;
      case ActivityType.cartUpdated:
        return Icons.edit_note;
      case ActivityType.cartCreated:
        return Icons.add_shopping_cart;
      case ActivityType.cartDeleted:
        return Icons.remove_shopping_cart;
      case ActivityType.productCreated:
        return Icons.add_box;
      case ActivityType.productUpdated:
        return Icons.inventory;
      case ActivityType.productDeleted:
        return Icons.delete_outline;
      case ActivityType.productAddedToCart:
        return Icons.add_shopping_cart;
      case ActivityType.productRemovedFromCart:
        return Icons.remove_shopping_cart;
      case ActivityType.productQuantityChanged:
        return Icons.edit;
      case ActivityType.orderPlaced:
        return Icons.shopping_bag;
      case ActivityType.other:
        return Icons.info;
    }
  }

  Color getTypeColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (type) {
      case ActivityType.login:
      case ActivityType.registration:
        return Colors.green;
      case ActivityType.profileUpdate:
      case ActivityType.settingsChanged:
      case ActivityType.themeChanged:
      case ActivityType.passwordChanged:
        return Colors.blue;
      case ActivityType.recipeCreated:
      case ActivityType.productCreated:
      case ActivityType.cartCreated:
      case ActivityType.productAddedToCart:
        return Colors.purple;
      case ActivityType.recipeUpdated:
      case ActivityType.productUpdated:
      case ActivityType.cartUpdated:
      case ActivityType.productQuantityChanged:
        return Colors.amber;
      case ActivityType.recipeDeleted:
      case ActivityType.productDeleted:
      case ActivityType.cartDeleted:
      case ActivityType.productRemovedFromCart:
        return Colors.red;
      case ActivityType.favoriteAdded:
        return Colors.pink;
      case ActivityType.favoriteRemoved:
        return isDark ? Colors.grey[400]! : Colors.grey[700]!;
      case ActivityType.productViewed:
        return Colors.teal;
      case ActivityType.orderPlaced:
        return Colors.indigo;
      case ActivityType.other:
        return isDark ? Colors.grey[500]! : Colors.grey[600]!;
    }
  }

  String getFormattedDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final activityDate =
        DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (activityDate == today) {
      return "Aujourd'hui à ${_formatTime(timestamp)}";
    } else if (activityDate == yesterday) {
      return "Hier à ${_formatTime(timestamp)}";
    } else {
      return "${_formatDate(timestamp)} à ${_formatTime(timestamp)}";
    }
  }

  String getRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return "À l'instant";
    } else if (difference.inMinutes < 60) {
      return "Il y a ${difference.inMinutes} min";
    } else if (difference.inHours < 24) {
      return "Il y a ${difference.inHours}h";
    } else if (difference.inDays < 7) {
      return "Il y a ${difference.inDays}j";
    } else {
      return _formatDate(timestamp);
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  String _formatTime(DateTime date) {
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  String getDetailText() {
    if (actionDescription != null && actionDescription!.isNotEmpty) {
      return actionDescription!;
    }

    // Utiliser les détails du produit enrichis si disponibles
    final productDetails = metadata['product_details'] as Map<String, dynamic>?;
    final productName = productDetails?['name'] ??
        metadata['product_name'] ??
        metadata['name'] ??
        'Produit inconnu';

    switch (type) {
      case ActivityType.login:
        return "Connexion depuis ${_getDeviceFromUserAgent()}";
      case ActivityType.registration:
        return "Inscription avec ${metadata['method'] ?? 'email'}";
      case ActivityType.profileUpdate:
        final fields = metadata['updated_fields'] as List?;
        return "Champs mis à jour: ${fields?.join(', ') ?? 'informations du profil'}";
      case ActivityType.recipeCreated:
        return "Recette créée: ${metadata['recipe_name'] ?? metadata['title'] ?? 'Sans nom'}";
      case ActivityType.recipeUpdated:
        return "Recette modifiée: ${metadata['recipe_name'] ?? metadata['title'] ?? 'Sans nom'}";
      case ActivityType.recipeDeleted:
        return "Recette supprimée: ${metadata['recipe_name'] ?? metadata['title'] ?? 'Sans nom'}";
      case ActivityType.favoriteAdded:
        return "Ajout aux favoris: ${metadata['recipe_name'] ?? metadata['title'] ?? 'Sans nom'}";
      case ActivityType.favoriteRemoved:
        return "Retiré des favoris: ${metadata['recipe_name'] ?? metadata['title'] ?? 'Sans nom'}";
      case ActivityType.settingsChanged:
        final settings = metadata['settings'] as List?;
        return "Paramètres modifiés: ${settings?.join(', ') ?? 'divers paramètres'}";
      case ActivityType.themeChanged:
        return "Thème changé pour: ${metadata['theme_name'] ?? 'nouveau thème'}";
      case ActivityType.passwordChanged:
        return "Mot de passe modifié avec succès";
      case ActivityType.productViewed:
        return "Produit consulté: $productName";
      case ActivityType.cartUpdated:
        return "Panier mis à jour";
      case ActivityType.cartCreated:
        return "Nouveau panier créé";
      case ActivityType.cartDeleted:
        return "Panier supprimé";
      case ActivityType.productCreated:
        return "Produit créé: $productName";
      case ActivityType.productUpdated:
        return "Produit modifié: $productName";
      case ActivityType.productDeleted:
        return "Produit supprimé: $productName";
      case ActivityType.productAddedToCart:
        final quantity = metadata['new_quantity'] ?? metadata['quantity'] ?? 1;
        return "$productName ajouté au panier (×$quantity)";
      case ActivityType.productRemovedFromCart:
        return "$productName retiré du panier";
      case ActivityType.productQuantityChanged:
        final oldQty = metadata['old_quantity'];
        final newQty = metadata['new_quantity'];
        if (oldQty != null && newQty != null) {
          return "$productName: quantité $oldQty → $newQty";
        }
        return "Quantité de $productName modifiée";
      case ActivityType.orderPlaced:
        return "Commande passée: ${metadata['order_total'] ?? 'montant non spécifié'}";
      case ActivityType.other:
        return metadata['description'] ?? "Activité enregistrée";
    }
  }

  String _getDeviceFromUserAgent() {
    if (deviceInfo == null) return 'un appareil inconnu';

    final userAgent = deviceInfo!.toLowerCase();
    if (userAgent.contains('dart')) {
      return 'application mobile';
    } else if (userAgent.contains('mobile') ||
        userAgent.contains('android') ||
        userAgent.contains('iphone')) {
      return 'mobile';
    } else if (userAgent.contains('tablet') || userAgent.contains('ipad')) {
      return 'tablette';
    } else {
      return 'ordinateur';
    }
  }

  List<Map<String, String>> getDetailItems() {
    final List<Map<String, String>> items = [];

    items.add({
      'label': 'Date et heure',
      'value': getFormattedDate(),
    });

    if (entityType != null) {
      items.add({
        'label': 'Type d\'entité',
        'value': _formatEntityType(entityType!),
      });
    }

    // Détails spécifiques aux produits
    final productDetails = metadata['product_details'] as Map<String, dynamic>?;
    if (productDetails != null) {
      items.add({
        'label': 'Produit',
        'value': productDetails['name'] ?? 'Nom non disponible',
      });

      // Utiliser category_name si disponible, sinon category_id
      if (productDetails['category_name'] != null && productDetails['category_name'].toString().isNotEmpty) {
        items.add({
          'label': 'Catégorie',
          'value': productDetails['category_name'].toString(),
        });
      } else if (productDetails['category_id'] != null) {
        items.add({
          'label': 'ID Catégorie',
          'value': productDetails['category_id'].toString(),
        });
      }

      if (productDetails['price'] != null) {
        items.add({
          'label': 'Prix',
          'value': '${productDetails['price']} FCFA',
        });
      }

      if (productDetails['size'] != null && productDetails['unit'] != null) {
        items.add({
          'label': 'Taille',
          'value': '${productDetails['size']} ${productDetails['unit']}',
        });
      }

      if (productDetails['origin'] != null && productDetails['origin'].toString().isNotEmpty) {
        items.add({
          'label': 'Origine',
          'value': productDetails['origin'].toString(),
        });
      }

      if (productDetails['rating'] != null) {
        items.add({
          'label': 'Note',
          'value': '${productDetails['rating']}/5 (${productDetails['reviews'] ?? 0} avis)',
        });
      }

      if (productDetails['stock'] != null) {
        items.add({
          'label': 'Stock',
          'value': '${productDetails['stock']} unités',
        });
      }
    }

    if (ipAddress != null && ipAddress != '::1') {
      items.add({
        'label': 'Adresse IP',
        'value': ipAddress!,
      });
    }

    if (deviceInfo != null) {
      items.add({
        'label': 'Appareil',
        'value': _getDeviceFromUserAgent(),
      });
    }

    if (location != null && location!.isNotEmpty) {
      items.add({
        'label': 'Localisation',
        'value': location!,
      });
    }

    if (sessionId != null && sessionId!.isNotEmpty) {
      items.add({
        'label': 'Session',
        'value': sessionId!.length > 8
            ? '${sessionId!.substring(0, 8)}...'
            : sessionId!,
      });
    }

    // Ajouter des métadonnées pertinentes (en excluant les détails du produit déjà affichés)
    metadata.forEach((key, value) {
      if (value != null &&
          value.toString().isNotEmpty &&
          !_isInternalMetadata(key) &&
          key != 'product_details') {
        items.add({
          'label': _formatMetadataKey(key),
          'value': _formatMetadataValue(key, value),
        });
      }
    });

    return items;
  }

  bool _isInternalMetadata(String key) {
    return ['raw', 'description', 'product_details'].contains(key);
  }

  String _formatEntityType(String entityType) {
    switch (entityType.toLowerCase()) {
      case 'recipes':
        return 'Recette';
      case 'products':
        return 'Produit';
      case 'cart':
        return 'Panier';
      case 'orders':
        return 'Commande';
      case 'users':
        return 'Utilisateur';
      default:
        return entityType;
    }
  }

  String _formatMetadataKey(String key) {
    switch (key) {
      case 'recipe_name':
        return 'Nom de la recette';
      case 'product_name':
        return 'Nom du produit';
      case 'product_id':
        return 'ID Produit';
      case 'old_quantity':
        return 'Ancienne quantité';
      case 'new_quantity':
        return 'Nouvelle quantité';
      case 'quantity':
        return 'Quantité';
      case 'updated_fields':
        return 'Champs modifiés';
      case 'theme_name':
        return 'Nom du thème';
      case 'method':
        return 'Méthode';
      case 'order_total':
        return 'Total commande';
      case 'action':
        return 'Action';
      case 'price':
        return 'Prix';
      case 'category_id':
        return 'ID Catégorie';
      case 'category_name':
        return 'Catégorie';
      case 'origin':
        return 'Origine';
      case 'rating':
        return 'Note';
      case 'stock':
        return 'Stock';
      default:
        return key
            .replaceAll('_', ' ')
            .split(' ')
            .map((word) => word.isNotEmpty
                ? word[0].toUpperCase() + word.substring(1)
                : word)
            .join(' ');
    }
  }

  String _formatMetadataValue(String key, dynamic value) {
    switch (key) {
      case 'old_quantity':
      case 'new_quantity':
      case 'quantity':
      case 'stock':
        return value.toString();
      case 'price':
        return '${value} FCFA';
      case 'rating':
        return '${value}/5';
      case 'product_id':
      case 'category_id':
        return value.toString().length > 8
            ? '${value.toString().substring(0, 8)}...'
            : value.toString();
      default:
        return value.toString();
    }
  }

  // Méthode pour obtenir un résumé enrichi de l'activité
  Map<String, dynamic> getEnrichedSummary() {
    final productDetails = metadata['product_details'] as Map<String, dynamic>?;

    return {
      'type': typeDisplayName,
      'description': getDetailText(),
      'timestamp': timestamp,
      'relativeTime': getRelativeTime(),
      'product': productDetails != null
          ? {
              'name': productDetails['name'],
              'category_name': productDetails['category_name'],
              'category_id': productDetails['category_id'],
              'price': productDetails['price'],
              'origin': productDetails['origin'],
              'rating': productDetails['rating'],
              'stock': productDetails['stock'],
            }
          : null,
      'quantities': type == ActivityType.productQuantityChanged
          ? {
              'old': metadata['old_quantity'],
              'new': metadata['new_quantity'],
            }
          : null,
      'color': getTypeColor,
      'icon': typeIcon,
    };
  }
}
