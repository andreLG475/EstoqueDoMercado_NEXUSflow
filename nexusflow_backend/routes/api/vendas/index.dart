import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:nexusflow_backend/src/auth/guards.dart';
import 'package:nexusflow_backend/src/cpf.dart';
import 'package:nexusflow_backend/src/db.dart';
import 'package:nexusflow_backend/src/models/role.dart';
import 'package:nexusflow_backend/src/models/sale.dart';
import 'package:nexusflow_backend/src/reports.dart';
import 'package:nexusflow_backend/src/utils.dart';
import 'package:postgres/postgres.dart';

const _pdvRoles = {Role.gerenteGeral, Role.atendente};

Future<Response> onRequest(RequestContext context) async {
  final profile = currentProfile(context);
  if (profile == null) return unauthorizedResponse();

  switch (context.request.method) {
    case HttpMethod.get:
      return _list(context);
    case HttpMethod.post:
      if (!_pdvRoles.contains(profile.role)) {
        return forbiddenResponse('Sem permissão para registrar vendas');
      }
      return _create(context, profile.id);
    case HttpMethod.delete:
    case HttpMethod.head:
    case HttpMethod.options:
    case HttpMethod.patch:
    case HttpMethod.put:
      return Response(statusCode: 405);
  }
}

Future<Response> _list(RequestContext context) async {
  final query = context.request.uri.queryParameters;
  final from = query['from'] != null ? DateTime.tryParse(query['from']!) : null;
  final to = query['to'] != null ? DateTime.tryParse(query['to']!) : null;

  final since = from ?? periodStart(query['period'] ?? 'today');
  final until = to;

  final result = await db.execute(
    Sql.named('''
      SELECT * FROM sales
      WHERE created_at >= @since AND (@until::timestamptz IS NULL OR created_at < @until)
      ORDER BY created_at DESC
      LIMIT 100
    '''),
    parameters: {'since': since, 'until': until},
  );

  final sales = <Sale>[];
  for (final row in result) {
    final sale = Sale.fromRow(row.toColumnMap());
    final itemsResult = await db.execute(
      Sql.named('SELECT * FROM sale_items WHERE sale_id = @saleId'),
      parameters: {'saleId': sale.id},
    );
    final items = itemsResult.map((r) => SaleItem.fromRow(r.toColumnMap())).toList();
    sales.add(sale.withItems(items));
  }

  return Response.json(body: sales.map((s) => s.toJson()).toList());
}

Future<Response> _create(RequestContext context, String userId) async {
  final body = await readJsonBody(context);
  if (body == null) {
    return Response.json(statusCode: 400, body: {'error': 'Dados inválidos'});
  }

  final paymentMethod = body['payment_method'] as String?;
  final amountPaid = (body['amount_paid'] as num?)?.toDouble() ?? 0;
  final items = body['items'];

  if (paymentMethod == null || items is! List || items.isEmpty) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'A venda precisa de forma de pagamento e ao menos um item'},
    );
  }

  final customerCpf = normalizeCpf(body['customer_cpf'] as String?);
  if (customerCpf != null && !isValidCpf(customerCpf)) {
    return Response.json(statusCode: 400, body: {'error': 'CPF inválido'});
  }

  try {
    final result = await db.execute(
      Sql.named('''
        SELECT create_sale(
          @userId::uuid, @paymentMethod, @amountPaid, @items::jsonb, @customerCpf
        ) AS result
      '''),
      parameters: {
        'userId': userId,
        'paymentMethod': paymentMethod,
        'amountPaid': amountPaid,
        'items': jsonEncode(items),
        'customerCpf': customerCpf,
      },
    );

    final raw = result.first.toColumnMap()['result'];
    final saleResult = raw is String ? jsonDecode(raw) : raw as Map<String, dynamic>;

    return Response.json(statusCode: 201, body: saleResult);
  } on ServerException catch (e) {
    return Response.json(
      statusCode: 400,
      body: {'error': e.message},
    );
  }
}
