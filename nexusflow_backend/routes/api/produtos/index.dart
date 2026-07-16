import 'package:dart_frog/dart_frog.dart';
import 'package:nexusflow_backend/src/auth/guards.dart';
import 'package:nexusflow_backend/src/db.dart';
import 'package:nexusflow_backend/src/models/product.dart';
import 'package:nexusflow_backend/src/models/role.dart';
import 'package:nexusflow_backend/src/utils.dart';
import 'package:postgres/postgres.dart';

const _estoqueRoles = {Role.gerenteGeral, Role.gerenteEstoque};

Future<Response> onRequest(RequestContext context) async {
  final profile = currentProfile(context);
  if (profile == null) return unauthorizedResponse();
  if (!_estoqueRoles.contains(profile.role)) {
    return forbiddenResponse('Sem permissão para acessar produtos');
  }

  switch (context.request.method) {
    case HttpMethod.get:
      return _list(context);
    case HttpMethod.post:
      return _create(context);
    case HttpMethod.delete:
    case HttpMethod.head:
    case HttpMethod.options:
    case HttpMethod.patch:
    case HttpMethod.put:
      return Response(statusCode: 405);
  }
}

Future<Response> _list(RequestContext context) async {
  final search = context.request.uri.queryParameters['search'];

  final result = search == null || search.isEmpty
      ? await db.execute(
          'SELECT * FROM products ORDER BY name ASC LIMIT 500',
        )
      : await db.execute(
          Sql.named('''
            SELECT * FROM products
            WHERE name ILIKE @term OR barcode ILIKE @term OR category ILIKE @term
            ORDER BY name ASC
            LIMIT 500
          '''),
          parameters: {'term': '%$search%'},
        );

  final products = result.map((row) => Product.fromRow(row.toColumnMap())).toList();
  return Response.json(body: products.map((p) => p.toJson()).toList());
}

Future<Response> _create(RequestContext context) async {
  final body = await readJsonBody(context);
  if (body == null) {
    return Response.json(statusCode: 400, body: {'error': 'Dados inválidos'});
  }

  try {
    final barcode = body['barcode'] as String;
    final name = body['name'] as String;
    final purchasePrice = (body['purchase_price'] as num).toDouble();
    final profitMargin = (body['profit_margin'] as num?)?.toDouble() ?? 30;
    final minSalePrice = purchasePrice * (1 + profitMargin / 100);
    final salePrice = (body['sale_price'] as num?)?.toDouble() ?? minSalePrice;

    final result = await db.execute(
      Sql.named('''
        INSERT INTO products (
          barcode, name, description, category,
          purchase_price, profit_margin, min_sale_price, sale_price,
          stock_quantity, min_stock
        ) VALUES (
          @barcode, @name, @description, @category,
          @purchasePrice, @profitMargin, @minSalePrice, @salePrice,
          @stockQuantity, @minStock
        )
        RETURNING *
      '''),
      parameters: {
        'barcode': barcode,
        'name': name,
        'description': body['description'] as String?,
        'category': body['category'] as String?,
        'purchasePrice': purchasePrice,
        'profitMargin': profitMargin,
        'minSalePrice': minSalePrice < salePrice ? minSalePrice : salePrice,
        'salePrice': salePrice < minSalePrice ? minSalePrice : salePrice,
        'stockQuantity': (body['stock_quantity'] as num?)?.toInt() ?? 0,
        'minStock': (body['min_stock'] as num?)?.toInt() ?? 5,
      },
    );

    final product = Product.fromRow(result.first.toColumnMap());
    return Response.json(statusCode: 201, body: product.toJson());
  } on ServerException catch (e) {
    if (e.code == '23505') {
      return Response.json(
        statusCode: 409,
        body: {'error': 'Já existe um produto com esse código de barras'},
      );
    }
    return Response.json(statusCode: 400, body: {'error': 'Não foi possível salvar o produto'});
  } catch (_) {
    return Response.json(statusCode: 400, body: {'error': 'Dados inválidos'});
  }
}
