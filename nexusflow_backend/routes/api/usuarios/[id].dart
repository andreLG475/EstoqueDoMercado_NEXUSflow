import 'package:dart_frog/dart_frog.dart';
import 'package:nexusflow_backend/src/auth/guards.dart';
import 'package:nexusflow_backend/src/db.dart';
import 'package:nexusflow_backend/src/models/role.dart';
import 'package:postgres/postgres.dart';

// Segurança: a exclusão de usuários é a ação mais sensível do painel
// administrativo (afeta autenticação e histórico de vendas de terceiros).
// Por isso o papel é checado aqui no backend, e não só escondendo o botão
// na tela — o botão pode ser burlado por qualquer cliente HTTP.
const _usuariosRoles = {Role.gerenteGeral};

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.delete) {
    return Response(statusCode: 405);
  }

  final profile = currentProfile(context);
  if (profile == null) return unauthorizedResponse();
  if (!_usuariosRoles.contains(profile.role)) {
    return forbiddenResponse('Apenas o Gerente Geral pode excluir usuários');
  }

  if (profile.id == id) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'Você não pode excluir seu próprio usuário'},
    );
  }

  try {
    final result = await db.execute(
      Sql.named('DELETE FROM profiles WHERE id = @id RETURNING id'),
      parameters: {'id': id},
    );
    if (result.isEmpty) {
      return Response.json(statusCode: 404, body: {'error': 'Usuário não encontrado'});
    }
    return Response.json(body: {'message': 'Usuário excluído com sucesso'});
  } on ServerException catch (e) {
    if (e.code == '23503') {
      return Response.json(
        statusCode: 409,
        body: {'error': 'Não é possível excluir: usuário possui vendas registradas'},
      );
    }
    rethrow;
  }
}
