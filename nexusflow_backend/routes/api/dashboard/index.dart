import 'package:dart_frog/dart_frog.dart';
import 'package:nexusflow_backend/src/auth/guards.dart';
import 'package:nexusflow_backend/src/db.dart';
import 'package:nexusflow_backend/src/utils.dart';
import 'package:postgres/postgres.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405);
  }

  final profile = currentProfile(context);
  if (profile == null) return unauthorizedResponse();

  final today = DateTime.now();
  final todayStart = DateTime(today.year, today.month, today.day);

  final statsResult = await db.execute(
    Sql.named('''
      SELECT
        (SELECT COUNT(*)::int FROM products) AS total_products,
        (SELECT COUNT(*)::int FROM sales) AS total_sales,
        (SELECT COALESCE(SUM(total), 0) FROM sales WHERE created_at >= @todayStart) AS today_revenue,
        (SELECT COUNT(*)::int FROM products WHERE stock_quantity <= min_stock) AS low_stock_count,
        (SELECT COALESCE(SUM(purchase_price * stock_quantity), 0) FROM products) AS total_stock_value,
        (SELECT COALESCE(SUM(total), 0) FROM sales) AS total_revenue
    '''),
    parameters: {'todayStart': todayStart},
  );
  final stats = statsResult.first.toColumnMap();

  final recentSalesResult = await db.execute(
    'SELECT id, total, created_at FROM sales ORDER BY created_at DESC LIMIT 5',
  );

  return Response.json(
    body: {
      'total_products': stats['total_products'],
      'total_sales': stats['total_sales'],
      'today_revenue': parseNum(stats['today_revenue']),
      'low_stock_count': stats['low_stock_count'],
      'total_stock_value': parseNum(stats['total_stock_value']),
      'total_revenue': parseNum(stats['total_revenue']),
      'recent_sales': recentSalesResult.map((row) {
        final r = row.toColumnMap();
        return {
          'id': r['id'],
          'total': parseNum(r['total']),
          'created_at': (r['created_at'] as DateTime).toIso8601String(),
        };
      }).toList(),
    },
  );
}
