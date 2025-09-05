import '../constants/app_strings.dart';

/// Validadores para formulários e entradas do usuário
/// Centralizados para reutilização e consistência
class Validators {
  /// Validador para campos obrigatórios
  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null
          ? '$fieldName é obrigatório'
          : AppStrings.fieldRequired;
    }
    return null;
  }

  /// Validador para email
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fieldRequired;
    }

    final emailRegex = RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$",
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Email inválido';
    }

    return null;
  }

  /// Validador para senha
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.fieldRequired;
    }

    if (value.length < 6) {
      return 'Senha deve ter pelo menos 6 caracteres';
    }

    return null;
  }

  /// Validador para usuário
  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fieldRequired;
    }

    if (value.trim().length < 3) {
      return 'Usuário deve ter pelo menos 3 caracteres';
    }

    // Permitir apenas letras, números e alguns caracteres especiais
    final usernameRegex = RegExp(r'^[a-zA-Z0-9._-]+$');
    if (!usernameRegex.hasMatch(value.trim())) {
      return 'Usuário contém caracteres inválidos';
    }

    return null;
  }

  /// Validador para URL do servidor
  static String? serverUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fieldRequired;
    }

    final url = value.trim();

    // Verificar se começa com http ou https
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return 'URL deve começar com http:// ou https://';
    }

    // Validação básica de URL
    try {
      final uri = Uri.parse(url);
      if (uri.host.isEmpty) {
        return 'URL inválida';
      }
    } catch (e) {
      return 'URL inválida';
    }

    return null;
  }

  /// Validador para código de produto
  static String? productCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.codeRequired;
    }

    final code = value.trim();

    // Verificar comprimento mínimo
    if (code.length < 2) {
      return 'Código deve ter pelo menos 2 caracteres';
    }

    // Verificar comprimento máximo (baseado no padrão Protheus)
    if (code.length > 30) {
      return 'Código muito longo (máximo 30 caracteres)';
    }

    // Permitir apenas caracteres alfanuméricos e alguns especiais
    final codeRegex = RegExp(r'^[a-zA-Z0-9._/-]+$');
    if (!codeRegex.hasMatch(code)) {
      return 'Código contém caracteres inválidos';
    }

    return null;
  }

  /// Validador para quantidade
  static String? quantity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.quantityRequired;
    }

    // Converter para número
    final quantity = double.tryParse(value.trim().replaceAll(',', '.'));

    if (quantity == null) {
      return AppStrings.invalidQuantity;
    }

    if (quantity < 0) {
      return AppStrings.quantityPositive;
    }

    // Verificar precisão decimal (máximo 3 casas)
    final parts = value.trim().replaceAll(',', '.').split('.');
    if (parts.length > 1 && parts[1].length > 3) {
      return 'Quantidade com muitas casas decimais (máximo 3)';
    }

    return null;
  }

  /// Validador para código de TAG
  static String? tagCode(String? value, bool isRequired) {
    // Se não é obrigatória, pode ser vazia
    if (!isRequired && (value == null || value.trim().isEmpty)) {
      return null;
    }

    // Se é obrigatória, deve ser preenchida
    if (isRequired && (value == null || value.trim().isEmpty)) {
      return AppStrings.tagRequired;
    }

    final tag = value!.trim();

    // Verificar formato básico da TAG
    if (tag.length < 3) {
      return 'TAG deve ter pelo menos 3 caracteres';
    }

    if (tag.length > 20) {
      return 'TAG muito longa (máximo 20 caracteres)';
    }

    // Permitir apenas caracteres alfanuméricos
    final tagRegex = RegExp(r'^[a-zA-Z0-9]+$');
    if (!tagRegex.hasMatch(tag)) {
      return 'TAG deve conter apenas letras e números';
    }

    return null;
  }

  /// Validador para código de barras
  static String? barcode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Código de barras é opcional
    }

    final code = value.trim();

    // Verificar se contém apenas números
    final barcodeRegex = RegExp(r'^[0-9]+$');
    if (!barcodeRegex.hasMatch(code)) {
      return 'Código de barras deve conter apenas números';
    }

    // Verificar comprimentos padrão (EAN-8, EAN-13, UPC, etc.)
    final validLengths = [8, 12, 13, 14];
    if (!validLengths.contains(code.length)) {
      return 'Código de barras com comprimento inválido';
    }

    return null;
  }

  /// Validador para localização
  static String? location(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Localização é obrigatória';
    }

    final location = value.trim();

    // Verificar comprimento
    if (location.length < 2) {
      return 'Localização deve ter pelo menos 2 caracteres';
    }

    if (location.length > 20) {
      return 'Localização muito longa (máximo 20 caracteres)';
    }

    // Permitir letras, números e alguns caracteres especiais
    final locationRegex = RegExp(r'^[a-zA-Z0-9._/-]+$');
    if (!locationRegex.hasMatch(location)) {
      return 'Localização contém caracteres inválidos';
    }

    return null;
  }

  /// Validador para observações/notas
  static String? notes(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Observações são opcionais
    }

    final notes = value.trim();

    // Verificar comprimento máximo
    if (notes.length > 500) {
      return 'Observações muito longas (máximo 500 caracteres)';
    }

    return null;
  }

  /// Validador para CPF
  static String? cpf(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fieldRequired;
    }

    // Remover formatação
    final cpf = value.replaceAll(RegExp(r'[^0-9]'), '');

    // Verificar comprimento
    if (cpf.length != 11) {
      return 'CPF deve ter 11 dígitos';
    }

    // Verificar se não são todos iguais
    if (RegExp(r'^(\d)\1{10}$').hasMatch(cpf)) {
      return 'CPF inválido';
    }

    // Validar dígitos verificadores
    if (!_isValidCPF(cpf)) {
      return 'CPF inválido';
    }

    return null;
  }

  /// Validador para CNPJ
  static String? cnpj(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fieldRequired;
    }

    // Remover formatação
    final cnpj = value.replaceAll(RegExp(r'[^0-9]'), '');

    // Verificar comprimento
    if (cnpj.length != 14) {
      return 'CNPJ deve ter 14 dígitos';
    }

    // Verificar se não são todos iguais
    if (RegExp(r'^(\d)\1{13}$').hasMatch(cnpj)) {
      return 'CNPJ inválido';
    }

    // Validar dígitos verificadores
    if (!_isValidCNPJ(cnpj)) {
      return 'CNPJ inválido';
    }

    return null;
  }

  /// Validador para número de telefone
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Telefone é opcional
    }

    // Remover formatação
    final phone = value.replaceAll(RegExp(r'[^0-9]'), '');

    // Verificar comprimento (10 ou 11 dígitos)
    if (phone.length < 10 || phone.length > 11) {
      return 'Telefone deve ter 10 ou 11 dígitos';
    }

    return null;
  }

  /// Validador para CEP
  static String? cep(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // CEP é opcional
    }

    // Remover formatação
    final cep = value.replaceAll(RegExp(r'[^0-9]'), '');

    // Verificar comprimento
    if (cep.length != 8) {
      return 'CEP deve ter 8 dígitos';
    }

    return null;
  }

  /// Validador combinado para múltiplas regras
  static String? combine(List<String? Function()> validators) {
    for (final validator in validators) {
      final result = validator();
      if (result != null) {
        return result;
      }
    }
    return null;
  }

  /// Validação de CPF
  static bool _isValidCPF(String cpf) {
    // Calcular primeiro dígito verificador
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += int.parse(cpf[i]) * (10 - i);
    }
    int firstDigit = (sum * 10) % 11;
    if (firstDigit == 10) firstDigit = 0;

    if (firstDigit != int.parse(cpf[9])) return false;

    // Calcular segundo dígito verificador
    sum = 0;
    for (int i = 0; i < 10; i++) {
      sum += int.parse(cpf[i]) * (11 - i);
    }
    int secondDigit = (sum * 10) % 11;
    if (secondDigit == 10) secondDigit = 0;

    return secondDigit == int.parse(cpf[10]);
  }

  /// Validação de CNPJ
  static bool _isValidCNPJ(String cnpj) {
    // Calcular primeiro dígito verificador
    final weights1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    int sum = 0;
    for (int i = 0; i < 12; i++) {
      sum += int.parse(cnpj[i]) * weights1[i];
    }
    int firstDigit = sum % 11;
    firstDigit = firstDigit < 2 ? 0 : 11 - firstDigit;

    if (firstDigit != int.parse(cnpj[12])) return false;

    // Calcular segundo dígito verificador
    final weights2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    sum = 0;
    for (int i = 0; i < 13; i++) {
      sum += int.parse(cnpj[i]) * weights2[i];
    }
    int secondDigit = sum % 11;
    secondDigit = secondDigit < 2 ? 0 : 11 - secondDigit;

    return secondDigit == int.parse(cnpj[13]);
  }
}
