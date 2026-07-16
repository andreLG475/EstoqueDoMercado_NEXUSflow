import 'package:dart_frog/dart_frog.dart';
import 'package:nexusflow_backend/src/auth/password.dart';
import 'package:nexusflow_backend/src/auth/session.dart';
import 'package:nexusflow_backend/src/db.dart';
import 'package:nexusflow_backend/src/models/profile.dart';
import 'package:nexusflow_backend/src/models/role.dart';
import 'package:nexusflow_backend/src/utils.dart';
import 'package:postgres/postgres.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405);
  }

  final body = await readJsonBody(context);
  final email = body?['email'] as String?;
  final password = body?['password'] as String?;

  if (email == null || email.isEmpty || password == null || password.isEmpty) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'E-mail e senha são obrigatórios'},
    );
  }

  final result = await db.execute(
    Sql.named(
      'SELECT id, name, email, password_hash, role FROM profiles WHERE email = @email',
    ),
    parameters: {'email': email},
  );

  if (result.isEmpty) {
    return Response.json(
      statusCode: 401,
      body: {'error': 'Credenciais incorretas'},
    );
  }

  final row = result.first.toColumnMap();
  final passwordHash = row['password_hash'] as String;

  if (!verifyPassword(password, passwordHash)) {
    return Response.json(
      statusCode: 401,
      body: {'error': 'Credenciais incorretas'},
    );
  }

  final profile = Profile(
    id: row['id'] as String,
    name: row['name'] as String,
    email: row['email'] as String,
    role: Role.fromString(row['role'] as String),
  );

  final token = createSessionToken(profile);

  return Response.json(
    body: {
      'message': 'Login realizado com sucesso',
      'token': token,
      'user': profile.toJson(),
      'redirect': Role.home[profile.role],
    },
  );
}
