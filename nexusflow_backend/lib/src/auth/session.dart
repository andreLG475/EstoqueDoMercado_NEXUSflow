import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

import '../env.dart';
import '../models/profile.dart';
import '../models/role.dart';

const sessionMaxAge = Duration(days: 7);

class SessionPayload {
  SessionPayload({
    required this.sub,
    required this.name,
    required this.email,
    required this.role,
  });

  final String sub;
  final String name;
  final String email;
  final Role role;

  Profile toProfile() => Profile(id: sub, name: name, email: email, role: role);
}

String createSessionToken(Profile profile) {
  final jwt = JWT(
    {
      'sub': profile.id,
      'name': profile.name,
      'email': profile.email,
      'role': profile.role.value,
    },
  );
  return jwt.sign(
    SecretKey(Env().sessionSecret),
    expiresIn: sessionMaxAge,
  );
}

SessionPayload? verifySessionToken(String token) {
  try {
    final jwt = JWT.verify(token, SecretKey(Env().sessionSecret));
    final payload = jwt.payload as Map<String, dynamic>;
    return SessionPayload(
      sub: payload['sub'] as String,
      name: payload['name'] as String,
      email: payload['email'] as String,
      role: Role.fromString(payload['role'] as String),
    );
  } catch (_) {
    return null;
  }
}
