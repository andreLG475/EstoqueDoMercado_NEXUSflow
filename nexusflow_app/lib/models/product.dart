class Product {
  Product({
    required this.id,
    required this.barcode,
    required this.name,
    required this.description,
    required this.category,
    required this.purchasePrice,
    required this.salePrice,
    required this.minSalePrice,
    required this.profitMargin,
    required this.stockQuantity,
    required this.minStock,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        barcode: json['barcode'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        category: json['category'] as String?,
        purchasePrice: (json['purchase_price'] as num).toDouble(),
        salePrice: (json['sale_price'] as num).toDouble(),
        minSalePrice: (json['min_sale_price'] as num).toDouble(),
        profitMargin: (json['profit_margin'] as num).toDouble(),
        stockQuantity: json['stock_quantity'] as int,
        minStock: json['min_stock'] as int,
      );

  final String id;
  final String barcode;
  final String name;
  final String? description;
  final String? category;
  final double purchasePrice;
  final double salePrice;
  final double minSalePrice;
  final double profitMargin;
  final int stockQuantity;
  final int minStock;

  bool get isLowStock => stockQuantity <= minStock;

  Map<String, dynamic> toRequestJson() => {
        'barcode': barcode,
        'name': name,
        'description': description,
        'category': category,
        'purchase_price': purchasePrice,
        'profit_margin': profitMargin,
        'sale_price': salePrice,
        'stock_quantity': stockQuantity,
        'min_stock': minStock,
      };
}
