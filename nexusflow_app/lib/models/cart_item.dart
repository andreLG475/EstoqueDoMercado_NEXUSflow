class CartItem {
  CartItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.stockAvailable,
  });

  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final int stockAvailable;

  double get subtotal => quantity * unitPrice;

  CartItem copyWith({int? quantity}) => CartItem(
        productId: productId,
        productName: productName,
        quantity: quantity ?? this.quantity,
        unitPrice: unitPrice,
        stockAvailable: stockAvailable,
      );
}
