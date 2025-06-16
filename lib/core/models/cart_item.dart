class CartItem {
  final String id;
  final String userId;
  final String productId;
  final int quantity;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String productName;
  final String? productDescription;
  final double? productPrice;
  final String? productImage;
  final double? productSize;
  final String? productUnit;
  final String? subcartId;

  CartItem({
    required this.id,
    required this.userId,
    required this.productId,
    required this.quantity,
    required this.createdAt,
    required this.updatedAt,
    required this.productName,
    this.productDescription,
    this.productPrice,
    this.productImage,
    this.productSize,
    this.productUnit,
    this.subcartId,
  });

  double get totalPrice => (productPrice ?? 0) * quantity;

  String get formattedPrice => '${productPrice?.toStringAsFixed(0) ?? "0"} FCFA';
  
  String get formattedProductPrice => '${productPrice?.toStringAsFixed(0) ?? "0"} FCFA';

  String get formattedTotalPrice => '${totalPrice.toStringAsFixed(0)} FCFA';

  String get formattedSize {
    if (productSize == null || productUnit == null) return '';
    return '${productSize!.toStringAsFixed(productSize!.truncateToDouble() == productSize ? 0 : 1)} $productUnit';
  }
}
