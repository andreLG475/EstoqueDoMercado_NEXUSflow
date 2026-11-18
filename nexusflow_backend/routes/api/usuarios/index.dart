import 'package:dart_frog/dart_frog.dart';
import 'package:nexusflow_backend/src/auth/guards.dart';
import 'package:nexusflow_backend/src/auth/password.dart';
import 'package:nexusflow_backend/src/db.dart';
import 'package:nexusflow_backend/src/models/profile.dart';
import 'package:nexusflow_backend/src/models/role.dart';
import 'package:nexusflow_backend/src/utils.dart';
import 'package:postgres/postgres.dart';

const _usuariosRoles = {Role.gerenteGeral};

Future<Response> onRequest(RequestContext context) async {
  final profile = currentProfile(context);
  if (profile == null) return unauthorizedResponse();
  if (!_usuariosRoles.contains(profile.role)) {
    return forbiddenResponse('Sem permissão para gerenciar usuários');
  }

  switch (context.request.method) {
    case HttpMethod.get:
      return _list();
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

Future<Response> _list() async {
  final result = await db.execute(
    'SELECT id, name, email, role FROM profiles ORDER BY name ASC',
  );

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

Future<Response> _create(RequestContext context) async {
  final body = await readJsonBody(context);
  if (body == null) {
    return Response.json(statusCode: 400, body: {'error': 'Dados inválidos'});
  }

  final name = body['name'] as String?;
  final email = body['email'] as String?;
  final password = body['password'] as String?;
  final requestedRole = body['role'] as String?;

  if (name == null || name.isEmpty) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'Nome é obrigatório'},
    );
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

  Role role;
  try {
    role = requestedRole != null
        ? Role.fromString(requestedRole)
        : Role.atendente;
  } catch (_) {
    return Response.json(statusCode: 400, body: {'error': 'Papel inválido'});
  }

  final existing = await db.execute(
    Sql.named('SELECT id FROM profiles WHERE email = @email'),
    parameters: {'email': email},
  );
  if (existing.isNotEmpty) {
    return Response.json(
      statusCode: 409,
      body: {'error': 'E-mail já cadastrado'},
    );
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
