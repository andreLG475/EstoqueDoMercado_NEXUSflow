import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core_providers.dart';

/// 'day' | 'month' | 'year'
final historicoGroupByProvider = StateProvider<String>((ref) => 'day');

class HistoricoBucket {
  HistoricoBucket({required this.bucket, required this.totalSales, required this.totalRevenue});

  factory HistoricoBucket.fromJson(Map<String, dynamic> json) => HistoricoBucket(
        bucket: DateTime.parse(json['bucket'] as String),
        totalSales: json['total_sales'] as int,
        totalRevenue: (json['total_revenue'] as num).toDouble(),
      );

  final DateTime bucket;
  final int totalSales;
  final double totalRevenue;

  /// Exclusive end of this bucket's time range, given the granularity it was grouped by.
  DateTime bucketEnd(String groupBy) {
    switch (groupBy) {
      case 'month':
        return DateTime(bucket.year, bucket.month + 1, 1);
      case 'year':
        return DateTime(bucket.year + 1, 1, 1);
      default:
        return bucket.add(const Duration(days: 1));
    }
  }
}

final historicoProvider = FutureProvider.autoDispose<List<HistoricoBucket>>((ref) async {
  final groupBy = ref.watch(historicoGroupByProvider);
  final api = ref.watch(apiClientProvider);
  final data = await api.get('/api/vendas/historico', query: {'group_by': groupBy}) as Map<String, dynamic>;
  return (data['buckets'] as List<dynamic>)
      .map((e) => HistoricoBucket.fromJson(e as Map<String, dynamic>))
      .toList();
});
