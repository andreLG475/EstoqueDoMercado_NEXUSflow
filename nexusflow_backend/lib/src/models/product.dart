import '../utils.dart';

class Product {
  Product({
    required this.id,
    required this.barcode,
    required this.name,
    required this.description,
    required this.category,
    required this.purchasePrice,
    required this.saleprice,
    required this.minSalePrice,
    required this.profitMargin,
    required this.stockQuantity,
    required this.minStock,
  });

  factory Product.fromRow(Map<String, dynamic> row) => Product(
        id: row['id'] as String,
        barcode: row['barcode'] as String,
        name: row['name'] as String,
        description: row['description'] as String?,
        category: row['category'] as String?,
        purchasePrice: parseNum(row['purchase_price']),
        saleprice: parseNum(row['sale_price']),
        minSalePrice: parseNum(row['min_sale_price']),
        profitMargin: parseNum(row['profit_margin']),
        stockQuantity: row['stock_quantity'] as int,
        minStock: row['min_stock'] as int,
      );

  final String id;
  final String barcode;
  final String name;
  final String? description;
  final String? category;
  final double purchasePrice;
  final double saleprice;
  final double minSalePrice;
  final double profitMargin;
  final int stockQuantity;
  final int minStock;

  Map<String, dynamic> toJson() => {
        'id': id,
        'barcode': barcode,
        'name': name,
        'description': description,
        'category': category,
        'purchase_price': purchasePrice,
        'sale_price': saleprice,
        'min_sale_price': minSalePrice,
        'profit_margin': profitMargin,
        'stock_quantity': stockQuantity,
        'min_stock': minStock,
      };
}
