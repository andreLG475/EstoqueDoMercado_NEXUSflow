import 'package:dart_frog/dart_frog.dart';

Response onRequest(RequestContext context) {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405);
  }
  return Response.json(body: {'message': 'Sessão encerrada'});
}
