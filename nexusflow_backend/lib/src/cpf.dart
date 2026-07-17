/// Remove formatação do CPF, mantendo só os dígitos (ou `null` se vazio).
String? normalizeCpf(String? value) {
  if (value == null) return null;
  final digits = value.replaceAll(RegExp(r'\D'), '');
  return digits.isEmpty ? null : digits;
}

/// Valida CPF pelo algoritmo de dígito verificador (Módulo 11).
/// Espera a string já normalizada (só dígitos, 11 caracteres).
bool isValidCpf(String digits) {
  if (digits.length != 11) return false;
  if (RegExp(r'^(\d)\1*$').hasMatch(digits)) return false;

  int calcDigit(String base) {
    var sum = 0;
    var weight = base.length + 1;
    for (final char in base.split('')) {
      sum += int.parse(char) * weight;
      weight--;
    }
    final remainder = sum % 11;
    return remainder < 2 ? 0 : 11 - remainder;
  }

  final digit1 = calcDigit(digits.substring(0, 9));
  final digit2 = calcDigit('${digits.substring(0, 9)}$digit1');
  return digits == '${digits.substring(0, 9)}$digit1$digit2';
}
