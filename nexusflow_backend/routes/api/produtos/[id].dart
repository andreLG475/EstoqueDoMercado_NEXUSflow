import 'package:dart_frog/dart_frog.dart';
import 'package:nexusflow_backend/src/auth/guards.dart';
import 'package:nexusflow_backend/src/db.dart';
import 'package:nexusflow_backend/src/models/product.dart';
import 'package:nexusflow_backend/src/models/role.dart';
import 'package:nexusflow_backend/src/utils.dart';
import 'package:postgres/postgres.dart';

const _estoqueRoles = {Role.gerenteGeral, Role.gerenteEstoque};

Future<Response> onRequest(RequestContext context, String id) async {
  final profile = currentProfile(context);
  if (profile == null) return unauthorizedResponse();
  if (!_estoqueRoles.contains(profile.role)) {
    return forbiddenResponse('Sem permissão para acessar produtos');
  }

  switch (context.request.method) {
    case HttpMethod.put:
      return _update(context, id);
    case HttpMethod.delete:
      return _delete(context, id);
    case HttpMethod.get:
    case HttpMethod.head:
    case HttpMethod.options:
    case HttpMethod.patch:
    case HttpMethod.post:
      return Response(statusCode: 405);
  }
}

Future<Response> _update(RequestContext context, String id) async {
  final body = await readJsonBody(context);
  if (body == null) {
    return Response.json(statusCode: 400, body: {'error': 'Dados inválidos'});
  }

  final existingResult = await db.execute(
    Sql.named('SELECT * FROM products WHERE id = @id'),
    parameters: {'id': id},
  );
  if (existingResult.isEmpty) {
    return Response.json(statusCode: 404, body: {'error': 'Produto não encontrado'});
  }
  final existing = Product.fromRow(existingResult.first.toColumnMap());

  try {
    final purchasePrice =
        (body['purchase_price'] as num?)?.toDouble() ?? existing.purchasePrice;
    final profitMargin =
        (body['profit_margin'] as num?)?.toDouble() ?? existing.profitMargin;
    final minSalePrice = purchasePrice * (1 + profitMargin / 100);
    final requestedSalePrice =
        (body['sale_price'] as num?)?.toDouble() ?? existing.saleprice;
    final salePrice = requestedSalePrice < minSalePrice ? minSalePrice : requestedSalePrice;

    final result = await db.execute(
      Sql.named('''
        UPDATE products SET
          barcode = @barcode,
          name = @name,
          description = @description,
          category = @category,
          purchase_price = @purchasePrice,
          profit_margin = @profitMargin,
          min_sale_price = @minSalePrice,
          sale_price = @salePrice,
          stock_quantity = @stockQuantity,
          min_stock = @minStock
        WHERE id = @id
        RETURNING *
      '''),
      parameters: {
        'id': id,
        'barcode': body['barcode'] as String? ?? existing.barcode,
        'name': body['name'] as String? ?? existing.name,
        'description': body['description'] as String? ?? existing.description,
        'category': body['category'] as String? ?? existing.category,
        'purchasePrice': purchasePrice,
        'profitMargin': profitMargin,
        'minSalePrice': minSalePrice,
        'salePrice': salePrice,
        'stockQuantity': (body['stock_quantity'] as num?)?.toInt() ?? existing.stockQuantity,
        'minStock': (body['min_stock'] as num?)?.toInt() ?? existing.minStock,
      },
    );

    final product = Product.fromRow(result.first.toColumnMap());
    return Response.json(body: product.toJson());
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

Future<Response> _delete(RequestContext context, String id) async {
  try {
    final result = await db.execute(
      Sql.named('DELETE FROM products WHERE id = @id RETURNING id'),
      parameters: {'id': id},
    );
    if (result.isEmpty) {
      return Response.json(statusCode: 404, body: {'error': 'Produto não encontrado'});
    }
    return Response.json(body: {'message': 'Produto excluído com sucesso'});
  } on ServerException catch (e) {
    if (e.code == '23503') {
      return Response.json(
        statusCode: 409,
        body: {'error': 'Não é possível excluir: produto já possui vendas registradas'},
      );
    }
    rethrow;
  }
}
