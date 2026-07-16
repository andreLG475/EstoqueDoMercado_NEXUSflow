class SaleItem {
  SaleItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  factory SaleItem.fromJson(Map<String, dynamic> json) => SaleItem(
        productId: json['product_id'] as String,
        productName: json['product_name'] as String,
        quantity: json['quantity'] as int,
        unitPrice: (json['unit_price'] as num).toDouble(),
        subtotal: (json['subtotal'] as num).toDouble(),
      );

  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double subtotal;
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
    required this.items,
    required this.itemCount,
  });

  factory Sale.fromJson(Map<String, dynamic> json) => Sale(
        id: json['id'] as String,
        total: (json['total'] as num).toDouble(),
        paymentMethod: json['payment_method'] as String,
        amountPaid: (json['amount_paid'] as num?)?.toDouble() ?? 0,
        changeAmount: (json['change_amount'] as num?)?.toDouble() ?? 0,
        invoiceNumber: json['invoice_number'] as int?,
        createdAt: DateTime.parse(json['created_at'] as String),
        items: (json['sale_items'] as List<dynamic>?)
                ?.map((item) => SaleItem.fromJson(item as Map<String, dynamic>))
                .toList() ??
            const [],
        itemCount: json['item_count'] as int? ?? (json['sale_items'] as List<dynamic>?)?.length ?? 0,
      );

  final String id;
  final double total;
  final String paymentMethod;
  final double amountPaid;
  final double changeAmount;
  final int? invoiceNumber;
  final DateTime createdAt;
  final List<SaleItem> items;
  final int itemCount;
}

const paymentMethodLabels = {
  'dinheiro': 'Dinheiro',
  'credito': 'Cartão de Crédito',
  'debito': 'Cartão de Débito',
  'pix': 'PIX',
};
