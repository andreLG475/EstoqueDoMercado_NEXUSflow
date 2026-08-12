import 'package:dart_frog/dart_frog.dart';
import 'package:nexusflow_backend/src/auth/session.dart';

Map<String, String> _corsHeaders(String? origin) {
  final allowedOrigins = {
    'http://localhost:8081',
    'http://127.0.0.1:8081',
    'http://localhost:3000',
    'http://127.0.0.1:3000',
  };

  final resolvedOrigin = origin != null && allowedOrigins.contains(origin)
      ? origin
      : 'http://localhost:8081';

  return {
    'Access-Control-Allow-Origin': resolvedOrigin,
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Requested-With',
    'Access-Control-Allow-Credentials': 'true',
  };
}

Handler middleware(Handler handler) {
  final withSession = handler.use(
    provider<SessionPayload?>((context) {
      final header = context.request.headers['Authorization'];
      if (header == null || !header.startsWith('Bearer ')) return null;
      final token = header.substring('Bearer '.length);
      return verifySessionToken(token);
    }),
  );

  return (context) async {
    final origin = context.request.headers['Origin'];

    if (context.request.method == HttpMethod.options) {
      return Response(
        statusCode: 204,
        headers: _corsHeaders(origin),
      );
    }

    try {
      final response = await withSession(context);
      return response.copyWith(headers: {
        ...response.headers,
        ..._corsHeaders(origin),
      });
    } catch (error, stackTrace) {
      // ignore: avoid_print
      print('Unhandled error: $error\n$stackTrace');
      return Response.json(
        statusCode: 500,
        headers: _corsHeaders(origin),
        body: {'error': 'Erro interno'},
      );
    }
  };
}
