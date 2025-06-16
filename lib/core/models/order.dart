import 'dart:math';

class Order {
  final String id;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String status;
  final double total;
  final String currency;
  final String? trackingNumber;
  final Map<String, dynamic>? shippingAddress;
  final Map<String, dynamic>? paymentInfo;
  final String? notes;
  final List<OrderItem> items;
  final double subtotal;
  final double shippingCost;
  final double discount;

  Order({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    required this.total,
    this.currency = 'FCFA',
    this.trackingNumber,
    this.shippingAddress,
    this.paymentInfo,
    this.notes,
    this.items = const [],
    double? subtotal,
    this.shippingCost = 0.0,
    this.discount = 0.0,
  }) : this.subtotal = subtotal ?? _calculateSubtotal(items);

  static double _calculateSubtotal(List<OrderItem> items) {
    return items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  String get formattedOrderNumber {
    return 'CMD-${id.substring(0, 8).toUpperCase()}';
  }

  String get formattedTotal {
    return '${total.toStringAsFixed(0)} $currency';
  }

  String get statusColor {
    switch (status.toLowerCase()) {
      case 'en attente':
        return 'orange';
      case 'confirmée':
        return 'blue';
      case 'expédiée':
        return 'purple';
      case 'livrée':
        return 'green';
      case 'annulée':
        return 'red';
      default:
        return 'grey';
    }
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    List<OrderItem> orderItems = [];
    if (json['items'] != null) {
      orderItems = (json['items'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList();
    }

    return Order(
      id: json['id'],
      userId: json['user_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.parse(json['created_at']),
      status: json['status'] ?? 'En attente',
      total: (json['total'] is int)
          ? (json['total'] as int).toDouble()
          : json['total'],
      currency: json['currency'] ?? 'FCFA',
      trackingNumber: json['tracking_number'],
      shippingAddress: json['shipping_address'],
      paymentInfo: json['payment_info'],
      notes: json['notes'],
      items: orderItems,
      subtotal: json['subtotal'] != null
          ? (json['subtotal'] is int)
              ? (json['subtotal'] as int).toDouble()
              : json['subtotal']
          : null,
      shippingCost: json['shipping_cost'] != null
          ? (json['shipping_cost'] is int)
              ? (json['shipping_cost'] as int).toDouble()
              : json['shipping_cost']
          : 0.0,
      discount: json['discount'] != null
          ? (json['discount'] is int)
              ? (json['discount'] as int).toDouble()
              : json['discount']
          : 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'status': status,
      'total': total,
      'currency': currency,
      'tracking_number': trackingNumber,
      'shipping_address': shippingAddress,
      'payment_info': paymentInfo,
      'notes': notes,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'shipping_cost': shippingCost,
      'discount': discount,
    };
  }
}

class OrderItem {
  final String id;
  final String orderId;
  final String productId;
  final int quantity;
  final double price;
  final String currency;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.price,
    this.currency = 'FCFA',
  });

  double get totalPrice => price * quantity;

  String get formattedPrice {
    return '${price.toStringAsFixed(0)} $currency';
  }

  String get formattedTotalPrice {
    return '${totalPrice.toStringAsFixed(0)} $currency';
  }

  // Méthodes utilitaires pour la compatibilité
  String get productName => 'Produit ${productId.substring(0, min(4, productId.length))}';
  
  String get productDescription => 'Quantité: $quantity';
  
  String get productImage => 'https://via.placeholder.com/60x60?text=Produit';

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      orderId: json['order_id'],
      productId: json['product_id'],
      quantity: json['quantity'] ?? 1,
      price: (json['price'] is int)
          ? (json['price'] as int).toDouble()
          : json['price'],
      currency: json['currency'] ?? 'FCFA',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'quantity': quantity,
      'price': price,
      'currency': currency,
    };
  }
}
