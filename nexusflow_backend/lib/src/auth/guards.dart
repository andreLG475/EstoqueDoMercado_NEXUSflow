import 'package:dart_frog/dart_frog.dart';

import '../models/profile.dart';
import 'session.dart';

Response unauthorizedResponse() =>
    Response.json(statusCode: 401, body: {'error': 'Não autenticado'});

Response forbiddenResponse(String message) =>
    Response.json(statusCode: 403, body: {'error': message});

/// Lê o payload de sessão do contexto (injetado pelo middleware raiz).
Profile? currentProfile(RequestContext context) {
  return context.read<SessionPayload?>()?.toProfile();
}
