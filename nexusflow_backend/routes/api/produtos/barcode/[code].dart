import 'package:dart_frog/dart_frog.dart';
import 'package:nexusflow_backend/src/auth/guards.dart';
import 'package:nexusflow_backend/src/db.dart';
import 'package:nexusflow_backend/src/models/product.dart';
import 'package:nexusflow_backend/src/models/role.dart';
import 'package:postgres/postgres.dart';

const _pdvRoles = {Role.gerenteGeral, Role.atendente};

Future<Response> onRequest(RequestContext context, String code) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405);
  }

  final profile = currentProfile(context);
  if (profile == null) return unauthorizedResponse();
  if (!_pdvRoles.contains(profile.role)) {
    return forbiddenResponse('Sem permissão para acessar o PDV');
  }

  final result = await db.execute(
    Sql.named('SELECT * FROM products WHERE barcode = @code'),
    parameters: {'code': code},
  );

  if (result.isEmpty) {
    return Response.json(statusCode: 404, body: {'error': 'Produto não encontrado'});
  }

  final product = Product.fromRow(result.first.toColumnMap());
  return Response.json(body: product.toJson());
}
