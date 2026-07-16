import 'package:dart_frog/dart_frog.dart';
import 'package:nexusflow_backend/src/auth/guards.dart';
import 'package:nexusflow_backend/src/db.dart';
import 'package:nexusflow_backend/src/models/role.dart';
import 'package:nexusflow_backend/src/reports.dart';
import 'package:nexusflow_backend/src/utils.dart';
import 'package:postgres/postgres.dart';

const _relatoriosRoles = {Role.gerenteGeral};

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405);
  }

  final profile = currentProfile(context);
  if (profile == null) return unauthorizedResponse();
  if (!_relatoriosRoles.contains(profile.role)) {
    return forbiddenResponse('Sem permissão para acessar relatórios');
  }

  final period = context.request.uri.queryParameters['period'] ?? 'today';
  final since = periodStart(period);

  final summaryResult = await db.execute(
    Sql.named('''
      SELECT
        COALESCE(SUM(total), 0) AS total_revenue,
        COUNT(*)::int AS total_sales
      FROM sales
      WHERE created_at >= @since
    '''),
    parameters: {'since': since},
  );
  final summary = summaryResult.first.toColumnMap();
  final totalRevenue = parseNum(summary['total_revenue']);
  final totalSales = summary['total_sales'] as int;
  final avgTicket = totalSales > 0 ? totalRevenue / totalSales : 0.0;

  final topProductsResult = await db.execute(
    Sql.named('''
      SELECT si.product_id, si.product_name,
             SUM(si.quantity)::int AS quantity,
             SUM(si.subtotal) AS revenue
      FROM sale_items si
      JOIN sales s ON s.id = si.sale_id
      WHERE s.created_at >= @since
      GROUP BY si.product_id, si.product_name
      ORDER BY quantity DESC
      LIMIT 5
    '''),
    parameters: {'since': since},
  );

  final paymentMethodsResult = await db.execute(
    Sql.named('''
      SELECT payment_method, COUNT(*)::int AS count, SUM(total) AS total
      FROM sales
      WHERE created_at >= @since
      GROUP BY payment_method
    '''),
    parameters: {'since': since},
  );

  final recentSalesResult = await db.execute(
    Sql.named('''
      SELECT s.id, s.total, s.payment_method, s.created_at,
             (SELECT COUNT(*) FROM sale_items si WHERE si.sale_id = s.id)::int AS item_count
      FROM sales s
      WHERE s.created_at >= @since
      ORDER BY s.created_at DESC
      LIMIT 10
    '''),
    parameters: {'since': since},
  );

  final lowStockResult = await db.execute(
    'SELECT id, name, barcode, stock_quantity, min_stock FROM products ORDER BY stock_quantity ASC LIMIT 10',
  );

  return Response.json(
    body: {
      'total_revenue': totalRevenue,
      'total_sales': totalSales,
      'avg_ticket': avgTicket,
      'top_products': topProductsResult.map((row) {
        final r = row.toColumnMap();
        return {
          'id': r['product_id'],
          'name': r['product_name'],
          'quantity': r['quantity'],
          'revenue': parseNum(r['revenue']),
        };
      }).toList(),
      'payment_methods': {
        for (final row in paymentMethodsResult.map((r) => r.toColumnMap()))
          row['payment_method'] as String: {
            'count': row['count'],
            'total': parseNum(row['total']),
          },
      },
      'recent_sales': recentSalesResult.map((row) {
        final r = row.toColumnMap();
        return {
          'id': r['id'],
          'total': parseNum(r['total']),
          'payment_method': r['payment_method'],
          'created_at': (r['created_at'] as DateTime).toIso8601String(),
          'item_count': r['item_count'],
        };
      }).toList(),
      'low_stock_products': lowStockResult.map((row) {
        final r = row.toColumnMap();
        return {
          'id': r['id'],
          'name': r['name'],
          'barcode': r['barcode'],
          'stock_quantity': r['stock_quantity'],
          'min_stock': r['min_stock'],
        };
      }).toList(),
    },
  );
}
