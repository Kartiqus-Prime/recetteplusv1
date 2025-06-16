import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order.dart';
import '../../main.dart';

class OrdersService {
  Future<List<Order>> getUserOrders() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Utilisateur non connecté');

      final response = await supabase
          .from('orders')
          .select('''
            id,
            user_id,
            total,
            status,
            created_at,
            updated_at,
            shipping_address,
            payment_info,
            tracking_number,
            notes,
            currency,
            items:order_items(
              id,
              order_id,
              product_id,
              quantity,
              price,
              currency
            )
          ''')
          .eq('user_id', userId)
          .filter('deleted_at', 'is', null)
          .order('created_at', ascending: false);

      return response.map<Order>((json) => Order.fromJson(json)).toList();
    } catch (e) {
      print('Erreur lors de la récupération des commandes: $e');
      throw Exception('Impossible de charger les commandes');
    }
  }

  Future<Order?> getOrderById(String orderId) async {
    try {
      final response = await supabase
          .from('orders')
          .select('''
            id,
            user_id,
            total,
            status,
            created_at,
            updated_at,
            shipping_address,
            payment_info,
            tracking_number,
            notes,
            currency,
            items:order_items(
              id,
              order_id,
              product_id,
              quantity,
              price,
              currency
            )
          ''')
          .eq('id', orderId)
          .filter('deleted_at', 'is', null)
          .single();

      return Order.fromJson(response);
    } catch (e) {
      print('Erreur lors de la récupération de la commande: $e');
      return null;
    }
  }
}
