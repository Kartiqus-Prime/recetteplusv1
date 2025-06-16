import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/activity_log.dart';
import '../../main.dart';

class ActivityHistoryService {
  Future<List<ActivityLog>> getUserActivityHistory({
    int limit = 20,
    int offset = 0,
    String? activityType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final userId = supabase.auth.currentUser!.id;
    
      var query = supabase
          .from('user_activity_log')
          .select('''
            id,
            user_id,
            action_type,
            entity_type,
            entity_id,
            action_description,
            metadata,
            ip_address,
            user_agent,
            session_id,
            location,
            created_at
          ''')
          .eq('user_id', userId);
    
      if (activityType != null && activityType != 'all') {
        query = query.eq('action_type', activityType);
      }
    
      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }
    
      if (endDate != null) {
        final endOfDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
        query = query.lte('created_at', endOfDay.toIso8601String());
      }
    
      final data = await query
          .order('created_at', ascending: false)
          .limit(limit)
          .range(offset, offset + limit - 1);
    
      // Enrichir les données avec les détails des produits
      final enrichedActivities = <ActivityLog>[];
      for (final json in data) {
        try {
          final activity = ActivityLog.fromJson(json);
          final enrichedActivity = await _enrichActivityWithProductDetails(activity);
          enrichedActivities.add(enrichedActivity);
        } catch (e) {
          print('Error processing activity ${json['id']}: $e');
          // Ajouter l'activité sans enrichissement en cas d'erreur
          enrichedActivities.add(ActivityLog.fromJson(json));
        }
      }
    
      return enrichedActivities;
    } catch (e) {
      print('Error fetching activity history: $e');
      return [];
    }
  }

  Future<ActivityLog> _enrichActivityWithProductDetails(ActivityLog activity) async {
    try {
      // Si l'activité concerne un produit dans les métadonnées
      if (activity.metadata.containsKey('product_id')) {
        final productId = activity.metadata['product_id'];
        if (productId != null && productId.toString().isNotEmpty) {
          final productDetails = await _getProductDetails(productId.toString());
          
          if (productDetails != null) {
            // Créer une nouvelle instance avec les détails du produit enrichis
            final enrichedMetadata = Map<String, dynamic>.from(activity.metadata);
            enrichedMetadata['product_details'] = productDetails;
            
            return ActivityLog(
              id: activity.id,
              userId: activity.userId,
              type: activity.type,
              timestamp: activity.timestamp,
              metadata: enrichedMetadata,
              entityId: activity.entityId,
              entityType: activity.entityType,
              ipAddress: activity.ipAddress,
              deviceInfo: activity.deviceInfo,
              sessionId: activity.sessionId,
              actionDescription: activity.actionDescription,
              location: activity.location,
            );
          }
        }
      }
      
      // Si l'activité concerne directement un produit
      if (activity.entityType == 'products' && activity.entityId != null && activity.entityId!.isNotEmpty) {
        final productDetails = await _getProductDetails(activity.entityId!);
        
        if (productDetails != null) {
          final enrichedMetadata = Map<String, dynamic>.from(activity.metadata);
          enrichedMetadata['product_details'] = productDetails;
          
          return ActivityLog(
            id: activity.id,
            userId: activity.userId,
            type: activity.type,
            timestamp: activity.timestamp,
            metadata: enrichedMetadata,
            entityId: activity.entityId,
            entityType: activity.entityType,
            ipAddress: activity.ipAddress,
            deviceInfo: activity.deviceInfo,
            sessionId: activity.sessionId,
            actionDescription: activity.actionDescription,
            location: activity.location,
          );
        }
      }
      
      return activity;
    } catch (e) {
      print('Error enriching activity with product details: $e');
      return activity;
    }
  }

  Future<Map<String, dynamic>?> _getProductDetails(String productId) async {
    try {
      // Utiliser uniquement les colonnes qui existent réellement dans la table products
      final data = await supabase
          .from('products')
          .select('''
            id,
            name,
            description,
            long_description,
            price,
            category_id,
            unit,
            unit_type,
            size,
            stock,
            rating,
            reviews,
            image,
            origin,
            nutritional_info,
            conservation,
            is_new,
            is_ingredient,
            slug,
            created_at,
            updated_at
          ''')
          .eq('id', productId)
          .maybeSingle();
      
      // Si on a récupéré des données et qu'il y a un category_id, récupérer le nom de la catégorie
      if (data != null && data['category_id'] != null) {
        try {
          final categoryData = await supabase
              .from('categories')
              .select('id, name')
              .eq('id', data['category_id'])
              .maybeSingle();
          
          if (categoryData != null) {
            data['category_name'] = categoryData['name'];
          }
        } catch (e) {
          print('Error fetching category details: $e');
          // Continuer sans les détails de la catégorie
        }
      }
      
      return data;
    } catch (e) {
      print('Error fetching product details: $e');
      
      // Essayer avec un ensemble plus minimal
      try {
        final data = await supabase
            .from('products')
            .select('id, name, description, price, category_id')
            .eq('id', productId)
            .maybeSingle();
        
        return data;
      } catch (e2) {
        print('Error fetching minimal product details: $e2');
        
        // Dernière tentative avec seulement l'ID et le nom
        try {
          final data = await supabase
              .from('products')
              .select('id, name')
              .eq('id', productId)
              .maybeSingle();
          
          return data;
        } catch (e3) {
          print('Error fetching basic product details: $e3');
          return null;
        }
      }
    }
  }

  Future<List<Map<String, dynamic>>> getAvailableActivityTypes() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      
      final data = await supabase
          .from('user_activity_log')
          .select('action_type, entity_type, metadata')
          .eq('user_id', userId);
      
      final Map<String, Map<String, dynamic>> uniqueTypes = {};
      
      for (final item in data) {
        final actionType = item['action_type'] as String?;
        final entityType = item['entity_type'] as String?;
        final metadata = item['metadata'];
        
        if (actionType != null) {
          // Créer une clé plus spécifique pour les opérations sur les produits
          String key = actionType;
          String displayName = actionType;
          
          if (entityType != null) {
            key = '${actionType}_$entityType';
            
            // Cas spécial pour les opérations sur les produits dans le panier
            if (entityType == 'cart' && metadata != null) {
              try {
                final parsedMetadata = ActivityLog.parseMetadataStatic(metadata);
                if (parsedMetadata.containsKey('product_id')) {
                  key = '${actionType}_cart_product';
                  displayName = ActivityLog.getDisplayNameForCartProductOperation(actionType);
                } else {
                  displayName = ActivityLog.getDisplayNameForType(actionType, entityType);
                }
              } catch (e) {
                displayName = ActivityLog.getDisplayNameForType(actionType, entityType);
              }
            } else {
              displayName = ActivityLog.getDisplayNameForType(actionType, entityType);
            }
          }
          
          if (!uniqueTypes.containsKey(key)) {
            uniqueTypes[key] = {
              'action_type': actionType,
              'entity_type': entityType,
              'display_name': displayName,
              'count': 0,
            };
          }
          uniqueTypes[key]!['count'] = (uniqueTypes[key]!['count'] as int) + 1;
        }
      }
      
      final result = uniqueTypes.values.toList();
      result.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
      
      return result;
    } catch (e) {
      print('Error fetching available activity types: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getActivitySummary() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      
      final data = await supabase
          .from('user_activity_log')
          .select('action_type, entity_type, metadata, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      final Map<String, int> typeCounts = {};
      final Map<String, int> productOperations = {};
      DateTime? firstActivity;
      DateTime? lastActivityDate;
      int totalProductsAffected = 0;
      
      for (final item in data) {
        final actionType = item['action_type'] as String;
        final entityType = item['entity_type'] as String?;
        final metadata = item['metadata'];
        final date = DateTime.parse(item['created_at']);
        
        String key = actionType;
        if (entityType != null) {
          if (entityType == 'cart' && metadata != null) {
            try {
              final parsedMetadata = ActivityLog.parseMetadataStatic(metadata);
              if (parsedMetadata.containsKey('product_id')) {
                key = '${actionType}_cart_product';
                totalProductsAffected++;
                
                // Compter les types d'opérations sur les produits
                switch (actionType) {
                  case 'create':
                    productOperations['added'] = (productOperations['added'] ?? 0) + 1;
                    break;
                  case 'update':
                    productOperations['updated'] = (productOperations['updated'] ?? 0) + 1;
                    break;
                  case 'delete':
                    productOperations['removed'] = (productOperations['removed'] ?? 0) + 1;
                    break;
                }
              } else {
                key = '${actionType}_$entityType';
              }
            } catch (e) {
              key = '${actionType}_$entityType';
            }
          } else {
            key = '${actionType}_$entityType';
          }
        }
        
        typeCounts[key] = (typeCounts[key] ?? 0) + 1;
        
        if (firstActivity == null || date.isBefore(firstActivity)) {
          firstActivity = date;
        }
        
        if (lastActivityDate == null || date.isAfter(lastActivityDate)) {
          lastActivityDate = date;
        }
      }
      
      return {
        'totalActivities': data.length,
        'typeCounts': typeCounts,
        'productOperations': productOperations,
        'totalProductsAffected': totalProductsAffected,
        'firstActivity': firstActivity,
        'lastActivityDate': lastActivityDate,
      };
    } catch (e) {
      print('Error fetching activity summary: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>?> getIpInfo(String ipAddress) async {
    if (ipAddress == '::1' || ipAddress.startsWith('192.168.') || ipAddress.startsWith('10.') || ipAddress.startsWith('172.')) {
      return {
        'ip': ipAddress,
        'type': 'private',
        'location': 'Réseau local',
      };
    }
    
    try {
      final response = await http.get(
        Uri.parse('http://ip-api.com/json/$ipAddress?fields=status,message,country,regionName,city,isp,org,as,query'),
        headers: {'Accept': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return {
            'ip': data['query'],
            'country': data['country'],
            'region': data['regionName'],
            'city': data['city'],
            'isp': data['isp'],
            'org': data['org'],
            'as': data['as'],
            'type': 'public',
          };
        }
      }
    } catch (e) {
      print('Error fetching IP info: $e');
    }
    
    return null;
  }

  Future<String> getCurrentPublicIp() async {
    try {
      final response = await http.get(Uri.parse('https://api.ipify.org?format=json'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['ip'];
      }
    } catch (e) {
      print('Error fetching current IP: $e');
    }
    return '';
  }

  Future<Map<String, dynamic>> getUserActivityStats() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      
      final response = await supabase
          .rpc('get_user_activity_stats', params: {'p_user_id': userId, 'p_period_days': 30});
      
      return response;
    } catch (e) {
      print('Error fetching activity stats: $e');
      return {};
    }
  }

  Future<bool> restoreDeletedEntity(String entityType, String entityId) async {
    try {
      final response = await supabase
          .rpc('restore_deleted_entity', params: {
            'p_table_name': entityType,
            'p_entity_id': entityId
          });
      
      return response == true;
    } catch (e) {
      print('Error restoring deleted entity: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getEntityDetails(String? entityType, String? entityId) async {
    if (entityType == null || entityId == null || entityId.isEmpty) return null;
    
    try {
      switch (entityType) {
        case 'recipes':
          final data = await supabase
              .from('recipes')
              .select('id, title, description')
              .eq('id', entityId)
              .maybeSingle();
          return data;
        case 'products':
          return await _getProductDetails(entityId);
        case 'cart':
          final data = await supabase
              .from('subcarts')
              .select('id, name, created_at')
              .eq('id', entityId)
              .maybeSingle();
          return data;
        default:
          return null;
      }
    } catch (e) {
      print('Error fetching entity details: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getRecentProductOperations({int limit = 10}) async {
    try {
      final userId = supabase.auth.currentUser!.id;
      
      final data = await supabase
          .from('user_activity_log')
          .select('action_type, metadata, created_at')
          .eq('user_id', userId)
          .eq('entity_type', 'cart')
          .order('created_at', ascending: false)
          .limit(limit);
      
      final operations = <Map<String, dynamic>>[];
      
      for (final item in data) {
        try {
          final metadata = ActivityLog.parseMetadataStatic(item['metadata']);
          if (metadata.containsKey('product_id')) {
            final productId = metadata['product_id'];
            if (productId != null && productId.toString().isNotEmpty) {
              final productDetails = await _getProductDetails(productId.toString());
              if (productDetails != null) {
                operations.add({
                  'action_type': item['action_type'],
                  'product': productDetails,
                  'metadata': metadata,
                  'created_at': item['created_at'],
                });
              }
            }
          }
        } catch (e) {
          print('Error processing product operation: $e');
          continue;
        }
      }
      
      return operations;
    } catch (e) {
      print('Error fetching recent product operations: $e');
      return [];
    }
  }

  // Méthode utilitaire pour découvrir la structure de la table products
  Future<List<String>> getProductTableColumns() async {
    try {
      // Essayer de récupérer un produit avec toutes les colonnes possibles
      final data = await supabase
          .from('products')
          .select('*')
          .limit(1)
          .maybeSingle();
      
      if (data != null) {
        return data.keys.toList();
      }
      
      return [];
    } catch (e) {
      print('Error discovering product table structure: $e');
      return [];
    }
  }
}
