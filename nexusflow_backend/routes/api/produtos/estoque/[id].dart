import 'package:dart_frog/dart_frog.dart';
import 'package:nexusflow_backend/src/auth/guards.dart';
import 'package:nexusflow_backend/src/db.dart';
import 'package:nexusflow_backend/src/models/product.dart';
import 'package:nexusflow_backend/src/models/role.dart';
import 'package:nexusflow_backend/src/utils.dart';
import 'package:postgres/postgres.dart';

const _estoqueRoles = {Role.gerenteGeral, Role.gerenteEstoque};

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405);
  }

  final profile = currentProfile(context);
  if (profile == null) return unauthorizedResponse();
  if (!_estoqueRoles.contains(profile.role)) {
    return forbiddenResponse('Sem permissão para ajustar estoque');
  }

  final body = await readJsonBody(context);
  final quantity = (body?['quantity'] as num?)?.toInt();
  if (quantity == null || quantity == 0) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'Informe uma quantidade diferente de zero'},
    );
  }

  // A soma é feita no próprio UPDATE (não lida antes em Dart) para que a
  // operação seja atômica mesmo com ajustes concorrentes no mesmo produto.
  final result = await db.execute(
    Sql.named('''
      UPDATE products
      SET stock_quantity = stock_quantity + @quantity
      WHERE id = @id AND stock_quantity + @quantity >= 0
      RETURNING *
    '''),
    parameters: {'id': id, 'quantity': quantity},
  );

  if (result.isEmpty) {
    final exists = await db.execute(
      Sql.named('SELECT id FROM products WHERE id = @id'),
      parameters: {'id': id},
    );
    if (exists.isEmpty) {
      return Response.json(statusCode: 404, body: {'error': 'Produto não encontrado'});
    }
    return Response.json(
      statusCode: 400,
      body: {'error': 'Estoque insuficiente para essa remoção'},
    );
  }

  final product = Product.fromRow(result.first.toColumnMap());
  return Response.json(body: product.toJson());
}
