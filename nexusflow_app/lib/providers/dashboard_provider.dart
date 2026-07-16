import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core_providers.dart';

class DashboardData {
  DashboardData({
    required this.totalProducts,
    required this.totalSales,
    required this.todayRevenue,
    required this.lowStockCount,
    required this.totalStockValue,
    required this.totalRevenue,
    required this.recentSales,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) => DashboardData(
        totalProducts: json['total_products'] as int,
        totalSales: json['total_sales'] as int,
        todayRevenue: (json['today_revenue'] as num).toDouble(),
        lowStockCount: json['low_stock_count'] as int,
        totalStockValue: (json['total_stock_value'] as num).toDouble(),
        totalRevenue: (json['total_revenue'] as num).toDouble(),
        recentSales: (json['recent_sales'] as List<dynamic>)
            .map((s) => RecentSale.fromJson(s as Map<String, dynamic>))
            .toList(),
      );

  final int totalProducts;
  final int totalSales;
  final double todayRevenue;
  final int lowStockCount;
  final double totalStockValue;
  final double totalRevenue;
  final List<RecentSale> recentSales;
}

class RecentSale {
  RecentSale({required this.id, required this.total, required this.createdAt});

  factory RecentSale.fromJson(Map<String, dynamic> json) => RecentSale(
        id: json['id'] as String,
        total: (json['total'] as num).toDouble(),
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  final String id;
  final double total;
  final DateTime createdAt;
}

final dashboardProvider = FutureProvider.autoDispose<DashboardData>((ref) async {
  final api = ref.watch(apiClientProvider);
  final data = await api.get('/api/dashboard') as Map<String, dynamic>;
  return DashboardData.fromJson(data);
});
