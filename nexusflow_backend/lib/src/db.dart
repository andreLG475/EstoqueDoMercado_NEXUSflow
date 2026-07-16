import 'package:postgres/postgres.dart';

import 'env.dart';

Pool<void>? _pool;

Pool<void> get db {
  return _pool ??= Pool<void>.withUrl(Env().databaseUrl);
}
