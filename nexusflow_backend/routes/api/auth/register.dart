import 'package:dart_frog/dart_frog.dart';
import 'package:nexusflow_backend/src/auth/password.dart';
import 'package:nexusflow_backend/src/db.dart';
import 'package:nexusflow_backend/src/models/role.dart';
import 'package:nexusflow_backend/src/utils.dart';
import 'package:postgres/postgres.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405);
  }

  final body = await readJsonBody(context);
  final name = body?['name'] as String?;
  final email = body?['email'] as String?;
  final password = body?['password'] as String?;
  final requestedRole = body?['role'] as String?;

  if (name == null || name.isEmpty) {
    return Response.json(statusCode: 400, body: {'error': 'Nome é obrigatório'});
  }
  if (email == null || !email.contains('@')) {
    return Response.json(statusCode: 400, body: {'error': 'E-mail inválido'});
  }
  if (password == null || password.length < 6) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'A senha deve ter no mínimo 6 caracteres'},
    );
  }

  // Decisão do dono do sistema: o cadastro público permite escolher
  // qualquer papel (inclusive Gerente Geral), sem exigir um admin
  // autenticado. Só faz sentido porque o app não fica exposto a
  // desconhecidos — quem chega na tela de cadastro é sempre alguém de
  // confiança da própria loja.
  Role role;
  try {
    role = requestedRole != null ? Role.fromString(requestedRole) : Role.atendente;
  } catch (_) {
    return Response.json(statusCode: 400, body: {'error': 'Papel inválido'});
  }

  final existing = await db.execute(
    Sql.named('SELECT id FROM profiles WHERE email = @email'),
    parameters: {'email': email},
  );
  if (existing.isNotEmpty) {
    return Response.json(statusCode: 409, body: {'error': 'E-mail já cadastrado'});
  }

  final passwordHash = hashPassword(password);

  final result = await db.execute(
    Sql.named('''
      INSERT INTO profiles (name, email, password_hash, role)
      VALUES (@name, @email, @passwordHash, @role)
      RETURNING id, name, email, role
    '''),
    parameters: {
      'name': name,
      'email': email,
      'passwordHash': passwordHash,
      'role': role.value,
    },
  );

  final row = result.first.toColumnMap();

  return Response.json(
    statusCode: 201,
    body: {
      'message': 'Usuário cadastrado com sucesso',
      'user': {
        'id': row['id'],
        'name': row['name'],
        'email': row['email'],
        'role': row['role'],
      },
    },
  );
}
