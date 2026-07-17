import 'package:flutter/services.dart';

/// Formata a entrada do usuário como XXX.XXX.XXX-XX enquanto ele digita.
class CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 11 ? digits.substring(0, 11) : digits;

    final buffer = StringBuffer();
    for (var i = 0; i < limited.length; i++) {
      if (i == 3 || i == 6) buffer.write('.');
      if (i == 9) buffer.write('-');
      buffer.write(limited[i]);
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

/// Valida CPF pelo algoritmo de dígito verificador (Módulo 11).
/// Aceita o valor com ou sem máscara.
bool isValidCpf(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
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
