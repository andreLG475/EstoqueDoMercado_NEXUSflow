import 'package:dart_frog/dart_frog.dart';
import 'package:nexusflow_backend/src/auth/session.dart';

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
    try {
      return await withSession(context);
    } catch (error, stackTrace) {
      // ignore: avoid_print
      print('Unhandled error: $error\n$stackTrace');
      return Response.json(statusCode: 500, body: {'error': 'Erro interno'});
    }
  };
}
