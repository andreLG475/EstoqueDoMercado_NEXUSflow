import '../utils.dart';

class SaleItem {
  SaleItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  factory SaleItem.fromRow(Map<String, dynamic> row) => SaleItem(
        productId: row['product_id'] as String,
        productName: row['product_name'] as String,
        quantity: row['quantity'] as int,
        unitPrice: parseNum(row['unit_price']),
        subtotal: parseNum(row['subtotal']),
      );

  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'product_name': productName,
        'quantity': quantity,
        'unit_price': unitPrice,
        'subtotal': subtotal,
      };
}

class Sale {
  Sale({
    required this.id,
    required this.total,
    required this.paymentMethod,
    required this.amountPaid,
    required this.changeAmount,
    required this.invoiceNumber,
    required this.createdAt,
    this.items = const [],
  });

  factory Sale.fromRow(Map<String, dynamic> row) => Sale(
        id: row['id'] as String,
        total: parseNum(row['total']),
        paymentMethod: row['payment_method'] as String,
        amountPaid: parseNum(row['amount_paid']),
        changeAmount: parseNum(row['change_amount']),
        invoiceNumber: row['invoice_number'] as int?,
        createdAt: row['created_at'] as DateTime,
      );

  final String id;
  final double total;
  final String paymentMethod;
  final double amountPaid;
  final double changeAmount;
  final int? invoiceNumber;
  final DateTime createdAt;
  final List<SaleItem> items;

  Sale withItems(List<SaleItem> items) => Sale(
        id: id,
        total: total,
        paymentMethod: paymentMethod,
        amountPaid: amountPaid,
        changeAmount: changeAmount,
        invoiceNumber: invoiceNumber,
        createdAt: createdAt,
        items: items,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'total': total,
        'payment_method': paymentMethod,
        'amount_paid': amountPaid,
        'change_amount': changeAmount,
        'invoice_number': invoiceNumber,
        'created_at': createdAt.toIso8601String(),
        'sale_items': items.map((item) => item.toJson()).toList(),
      };
}
