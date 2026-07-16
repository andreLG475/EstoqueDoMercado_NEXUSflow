import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';

/// Colunas NUMERIC/DECIMAL do Postgres chegam como [String] (para preservar
/// precisão exata); colunas inteiras chegam como [int]/[num]. Este helper
/// aceita ambos.
double parseNum(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.parse(value);
  throw ArgumentError('Valor numérico inválido: $value');
}

Future<Map<String, dynamic>?> readJsonBody(RequestContext context) async {
  try {
    final raw = await context.request.body();
    if (raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;
    return decoded;
  } catch (_) {
    return null;
  }
}
