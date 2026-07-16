import 'package:dotenv/dotenv.dart';

class Env {
  factory Env() {
    return _instance ??= Env._(DotEnv(includePlatformEnvironment: true)..load());
  }

  Env._(this._vars);

  static Env? _instance;

  final DotEnv _vars;

  String _require(String key) {
    final value = _vars[key];
    if (value == null || value.isEmpty) {
      throw StateError('Variável de ambiente ausente: defina $key no arquivo .env.');
    }
    return value;
  }

  String get databaseUrl => _require('DATABASE_URL');

  String get sessionSecret => _require('SESSION_SECRET');
}
