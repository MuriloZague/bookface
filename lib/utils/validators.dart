/// Validadores reutilizáveis para os formulários de login e cadastro.
class Validators {
  static final RegExp _emailRegex = RegExp(
    r'^[\w.+-]+@[\w-]+\.[\w.-]+$',
  );

  /// Nome: obrigatório, mínimo duas palavras (nome e sobrenome).
  static String? name(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Informe seu nome';
    if (v.length < 3) return 'Nome muito curto';
    if (!v.contains(' ')) return 'Informe nome e sobrenome';
    return null;
  }

  /// E-mail: obrigatório e em formato válido.
  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Informe seu e-mail';
    if (!_emailRegex.hasMatch(v)) return 'E-mail inválido';
    return null;
  }

  /// Telefone brasileiro: espera 10 (fixo) ou 11 (celular) dígitos.
  static String? phone(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Informe seu telefone';
    if (digits.length < 10) return 'Telefone incompleto';
    if (digits.length > 11) return 'Telefone inválido';
    return null;
  }

  /// Senha: mínimo 6 caracteres, com letra e número.
  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Informe sua senha';
    if (v.length < 6) return 'Mínimo de 6 caracteres';
    if (!RegExp(r'[A-Za-z]').hasMatch(v) || !RegExp(r'\d').hasMatch(v)) {
      return 'Use letras e números';
    }
    return null;
  }

  /// Confirmação de senha: precisa coincidir com [original].
  static String? confirmPassword(String? value, String original) {
    if ((value ?? '').isEmpty) return 'Confirme sua senha';
    if (value != original) return 'As senhas não coincidem';
    return null;
  }

  /// Login: aceita e-mail OU telefone no mesmo campo.
  static String? emailOrPhone(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Informe e-mail ou telefone';
    final digits = v.replaceAll(RegExp(r'\D'), '');
    final looksLikePhone =
        digits.length >= 10 && RegExp(r'^[\d()\s-]+$').hasMatch(v);
    if (looksLikePhone) return null;
    if (!_emailRegex.hasMatch(v)) return 'E-mail ou telefone inválido';
    return null;
  }
}
