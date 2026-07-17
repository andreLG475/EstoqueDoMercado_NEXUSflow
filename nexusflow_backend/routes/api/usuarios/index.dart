import 'package:dart_frog/dart_frog.dart';
import 'package:nexusflow_backend/src/auth/guards.dart';
import 'package:nexusflow_backend/src/db.dart';
import 'package:nexusflow_backend/src/models/profile.dart';
import 'package:nexusflow_backend/src/models/role.dart';

const _usuariosRoles = {Role.gerenteGeral};

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405);
  }

  final profile = currentProfile(context);
  if (profile == null) return unauthorizedResponse();
  if (!_usuariosRoles.contains(profile.role)) {
    return forbiddenResponse('Sem permissão para gerenciar usuários');
  }

  final result = await db.execute('SELECT id, name, email, role FROM profiles ORDER BY name ASC');

  final users = result.map((row) {
    final r = row.toColumnMap();
    return Profile(
      id: r['id'] as String,
      name: r['name'] as String,
      email: r['email'] as String,
      role: Role.fromString(r['role'] as String),
    );
  }).toList();

  return Response.json(body: users.map((u) => u.toJson()).toList());
}
