import 'package:flutter/services.dart';

/// Máscara de telefone brasileiro: (##) ####-#### ou (##) #####-####.
///
/// Aplica-se enquanto o usuário digita, mantendo apenas dígitos e
/// inserindo os separadores automaticamente. Limita a 11 dígitos.
class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 11) digits = digits.substring(0, 11);

    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 0) buffer.write('(');
      if (i == 2) buffer.write(') ');
      // Hífen antes do último bloco de 4 dígitos.
      if ((digits.length == 11 && i == 7) ||
          (digits.length <= 10 && i == 6)) {
        buffer.write('-');
      }
      buffer.write(digits[i]);
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
