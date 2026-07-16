import 'package:dart_frog/dart_frog.dart';
import 'package:nexusflow_backend/src/auth/guards.dart';

Response onRequest(RequestContext context) {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405);
  }

  final profile = currentProfile(context);
  if (profile == null) {
    return unauthorizedResponse();
  }

  return Response.json(body: {'user': profile.toJson()});
}
