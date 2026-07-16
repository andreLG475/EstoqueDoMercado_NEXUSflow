import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core_providers.dart';

final reportPeriodProvider = StateProvider<String>((ref) => 'today');

class TopProduct {
  TopProduct({required this.id, required this.name, required this.quantity, required this.revenue});

  factory TopProduct.fromJson(Map<String, dynamic> json) => TopProduct(
        id: json['id'] as String,
        name: json['name'] as String,
        quantity: json['quantity'] as int,
        revenue: (json['revenue'] as num).toDouble(),
      );

  final String id;
  final String name;
  final int quantity;
  final double revenue;
}

class PaymentMethodStats {
  PaymentMethodStats({required this.count, required this.total});

  factory PaymentMethodStats.fromJson(Map<String, dynamic> json) =>
      PaymentMethodStats(count: json['count'] as int, total: (json['total'] as num).toDouble());

  final int count;
  final double total;
}

class ReportSale {
  ReportSale({
    required this.id,
    required this.total,
    required this.paymentMethod,
    required this.createdAt,
    required this.itemCount,
  });

  factory ReportSale.fromJson(Map<String, dynamic> json) => ReportSale(
        id: json['id'] as String,
        total: (json['total'] as num).toDouble(),
        paymentMethod: json['payment_method'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        itemCount: json['item_count'] as int,
      );

  final String id;
  final double total;
  final String paymentMethod;
  final DateTime createdAt;
  final int itemCount;
}

class LowStockProduct {
  LowStockProduct({
    required this.id,
    required this.name,
    required this.barcode,
    required this.stockQuantity,
    required this.minStock,
  });

  factory LowStockProduct.fromJson(Map<String, dynamic> json) => LowStockProduct(
        id: json['id'] as String,
        name: json['name'] as String,
        barcode: json['barcode'] as String,
        stockQuantity: json['stock_quantity'] as int,
        minStock: json['min_stock'] as int,
      );

  final String id;
  final String name;
  final String barcode;
  final int stockQuantity;
  final int minStock;
}

class ReportData {
  ReportData({
    required this.totalRevenue,
    required this.totalSales,
    required this.avgTicket,
    required this.topProducts,
    required this.paymentMethods,
    required this.recentSales,
    required this.lowStockProducts,
  });

  factory ReportData.fromJson(Map<String, dynamic> json) => ReportData(
        totalRevenue: (json['total_revenue'] as num).toDouble(),
        totalSales: json['total_sales'] as int,
        avgTicket: (json['avg_ticket'] as num).toDouble(),
        topProducts: (json['top_products'] as List<dynamic>)
            .map((e) => TopProduct.fromJson(e as Map<String, dynamic>))
            .toList(),
        paymentMethods: (json['payment_methods'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, PaymentMethodStats.fromJson(value as Map<String, dynamic>)),
        ),
        recentSales: (json['recent_sales'] as List<dynamic>)
            .map((e) => ReportSale.fromJson(e as Map<String, dynamic>))
            .toList(),
        lowStockProducts: (json['low_stock_products'] as List<dynamic>)
            .map((e) => LowStockProduct.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final double totalRevenue;
  final int totalSales;
  final double avgTicket;
  final List<TopProduct> topProducts;
  final Map<String, PaymentMethodStats> paymentMethods;
  final List<ReportSale> recentSales;
  final List<LowStockProduct> lowStockProducts;
}

final reportsProvider = FutureProvider.autoDispose<ReportData>((ref) async {
  final period = ref.watch(reportPeriodProvider);
  final api = ref.watch(apiClientProvider);
  final data = await api.get('/api/relatorios', query: {'period': period}) as Map<String, dynamic>;
  return ReportData.fromJson(data);
});
