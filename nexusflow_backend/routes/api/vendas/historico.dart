import 'package:dart_frog/dart_frog.dart';
import 'package:nexusflow_backend/src/auth/guards.dart';
import 'package:nexusflow_backend/src/db.dart';
import 'package:nexusflow_backend/src/models/role.dart';
import 'package:nexusflow_backend/src/utils.dart';

const _historicoRoles = {Role.gerenteGeral};

const _truncUnitByGroup = {
  'day': 'day',
  'month': 'month',
  'year': 'year',
};

const _limitByGroup = {
  'day': 90,
  'month': 24,
  'year': 10,
};

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405);
  }

  final profile = currentProfile(context);
  if (profile == null) return unauthorizedResponse();
  if (!_historicoRoles.contains(profile.role)) {
    return forbiddenResponse('Sem permissão para acessar o histórico de vendas');
  }

  final groupBy = context.request.uri.queryParameters['group_by'] ?? 'day';
  final truncUnit = _truncUnitByGroup[groupBy];
  if (truncUnit == null) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'group_by inválido (use day, month ou year)'},
    );
  }
  final limit = _limitByGroup[groupBy]!;

  final result = await db.execute(
    "SELECT DATE_TRUNC('$truncUnit', created_at) AS bucket, "
    'COUNT(*)::int AS total_sales, '
    'COALESCE(SUM(total), 0) AS total_revenue '
    'FROM sales '
    'GROUP BY bucket '
    'ORDER BY bucket DESC '
    'LIMIT $limit',
  );

  final buckets = result.map((row) {
    final r = row.toColumnMap();
    return {
      'bucket': (r['bucket'] as DateTime).toIso8601String(),
      'total_sales': r['total_sales'],
      'total_revenue': parseNum(r['total_revenue']),
    };
  }).toList();

  return Response.json(body: {'group_by': groupBy, 'buckets': buckets});
}
