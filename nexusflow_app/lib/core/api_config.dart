import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// URL base da API. Em produção isso viraria uma variável de build
/// (`--dart-define=API_BASE_URL=...`); em desenvolvimento local cada
/// plataforma resolve "localhost" de um jeito diferente.
String get apiBaseUrl {
  const override = String.fromEnvironment('API_BASE_URL');
  if (override.isNotEmpty) return override;

  if (kIsWeb) return 'http://localhost:8080';
  if (Platform.isAndroid) return 'http://10.0.2.2:8080';
  return 'http://localhost:8080';
}
