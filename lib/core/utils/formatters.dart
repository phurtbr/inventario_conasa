import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Formatadores de texto e números para o aplicativo
/// Centraliza formatação de dados para consistência
class Formatters {
  // Formatadores de números
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  static final NumberFormat _numberFormat = NumberFormat('#,##0.###', 'pt_BR');
  static final NumberFormat _integerFormat = NumberFormat('#,##0', 'pt_BR');
  static final NumberFormat _percentFormat = NumberFormat.percentPattern(
    'pt_BR',
  );

  // Formatadores de data
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _isoDateFormat = DateFormat('yyyy-MM-dd');

  /// Formatar moeda brasileira
  static String currency(double? value) {
    if (value == null) return 'R\$ 0,00';
    return _currencyFormat.format(value);
  }

  /// Formatar número decimal
  static String number(double? value, {int? decimalPlaces}) {
    if (value == null) return '0';

    if (decimalPlaces != null) {
      final format = NumberFormat('#,##0.${'0' * decimalPlaces}', 'pt_BR');
      return format.format(value);
    }

    return _numberFormat.format(value);
  }

  /// Formatar número inteiro
  static String integer(int? value) {
    if (value == null) return '0';
    return _integerFormat.format(value);
  }

  /// Formatar porcentagem
  static String percentage(double? value) {
    if (value == null) return '0%';
    return _percentFormat.format(value / 100);
  }

  /// Formatar quantidade com unidade de medida
  static String quantity(double? value, String? unitOfMeasure) {
    if (value == null) return '0';
    final formattedValue = _numberFormat.format(value);
    return unitOfMeasure != null
        ? '$formattedValue $unitOfMeasure'
        : formattedValue;
  }

  /// Formatar data
  static String date(DateTime? date) {
    if (date == null) return '';
    return _dateFormat.format(date);
  }

  /// Formatar data e hora
  static String dateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    return _dateTimeFormat.format(dateTime);
  }

  /// Formatar hora
  static String time(DateTime? time) {
    if (time == null) return '';
    return _timeFormat.format(time);
  }

  /// Formatar data no formato ISO
  static String isoDate(DateTime? date) {
    if (date == null) return '';
    return _isoDateFormat.format(date);
  }

  /// Formatar data relativa (hoje, ontem, etc.)
  static String relativeDate(DateTime? date) {
    if (date == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    final difference = today.difference(dateOnly).inDays;

    if (difference == 0) {
      return 'Hoje';
    } else if (difference == 1) {
      return 'Ontem';
    } else if (difference < 7) {
      return '$difference dias atrás';
    } else if (difference < 30) {
      final weeks = (difference / 7).floor();
      return weeks == 1 ? '1 semana atrás' : '$weeks semanas atrás';
    } else if (difference < 365) {
      final months = (difference / 30).floor();
      return months == 1 ? '1 mês atrás' : '$months meses atrás';
    } else {
      final years = (difference / 365).floor();
      return years == 1 ? '1 ano atrás' : '$years anos atrás';
    }
  }

  /// Formatar CPF
  static String cpf(String? value) {
    if (value == null || value.isEmpty) return '';

    final numbers = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (numbers.length != 11) return value;

    return '${numbers.substring(0, 3)}.${numbers.substring(3, 6)}.${numbers.substring(6, 9)}-${numbers.substring(9)}';
  }

  /// Formatar CNPJ
  static String cnpj(String? value) {
    if (value == null || value.isEmpty) return '';

    final numbers = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (numbers.length != 14) return value;

    return '${numbers.substring(0, 2)}.${numbers.substring(2, 5)}.${numbers.substring(5, 8)}/${numbers.substring(8, 12)}-${numbers.substring(12)}';
  }

  /// Formatar CEP
  static String cep(String? value) {
    if (value == null || value.isEmpty) return '';

    final numbers = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (numbers.length != 8) return value;

    return '${numbers.substring(0, 5)}-${numbers.substring(5)}';
  }

  /// Formatar telefone
  static String phone(String? value) {
    if (value == null || value.isEmpty) return '';

    final numbers = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (numbers.length == 10) {
      return '(${numbers.substring(0, 2)}) ${numbers.substring(2, 6)}-${numbers.substring(6)}';
    } else if (numbers.length == 11) {
      return '(${numbers.substring(0, 2)}) ${numbers.substring(2, 7)}-${numbers.substring(7)}';
    }

    return value;
  }

  /// Formatar código de produto com zeros à esquerda
  static String productCode(String? value, {int? length}) {
    if (value == null || value.isEmpty) return '';

    if (length != null && value.length < length) {
      return value.padLeft(length, '0');
    }

    return value;
  }

  /// Formatar código de barras
  static String barcode(String? value) {
    if (value == null || value.isEmpty) return '';

    final numbers = value.replaceAll(RegExp(r'[^0-9]'), '');

    // EAN-13
    if (numbers.length == 13) {
      return '${numbers.substring(0, 1)} ${numbers.substring(1, 7)} ${numbers.substring(7, 13)}';
    }

    // EAN-8
    if (numbers.length == 8) {
      return '${numbers.substring(0, 4)} ${numbers.substring(4)}';
    }

    return value;
  }

  /// Formatar tamanho de arquivo
  static String fileSize(int? bytes) {
    if (bytes == null || bytes == 0) return '0 B';

    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    int index = 0;
    double size = bytes.toDouble();

    while (size >= 1024 && index < suffixes.length - 1) {
      size /= 1024;
      index++;
    }

    return '${size.toStringAsFixed(index == 0 ? 0 : 1)} ${suffixes[index]}';
  }

  /// Formatar duração
  static String duration(Duration? duration) {
    if (duration == null) return '0s';

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  /// Formatar texto com primeira letra maiúscula
  static String capitalize(String? value) {
    if (value == null || value.isEmpty) return '';
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  /// Formatar título (primeira letra de cada palavra maiúscula)
  static String title(String? value) {
    if (value == null || value.isEmpty) return '';

    return value
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  /// Truncar texto com reticências
  static String truncate(String? value, int maxLength) {
    if (value == null || value.isEmpty) return '';
    if (value.length <= maxLength) return value;
    return '${value.substring(0, maxLength - 3)}...';
  }

  /// Remover acentos e caracteres especiais
  static String removeAccents(String? value) {
    if (value == null || value.isEmpty) return '';

    const withAccents = 'àáäâèéëêìíïîòóöôùúüûñç';
    const withoutAccents = 'aaaaeeeeiiiioooouuuunc';

    String result = value.toLowerCase();

    for (int i = 0; i < withAccents.length; i++) {
      result = result.replaceAll(withAccents[i], withoutAccents[i]);
    }

    return result;
  }

  /// Formatar coordenadas GPS
  static String coordinates(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) return '';
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }

  /// Parse de string para double considerando vírgula como decimal
  static double? parseDouble(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    try {
      final normalizedValue = value.trim().replaceAll(',', '.');
      return double.parse(normalizedValue);
    } catch (e) {
      return null;
    }
  }

  /// Parse de string para int
  static int? parseInt(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    try {
      return int.parse(value.trim());
    } catch (e) {
      return null;
    }
  }

  /// Parse de data no formato brasileiro
  static DateTime? parseDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    try {
      // Tentar formato dd/MM/yyyy
      if (value.contains('/')) {
        return _dateFormat.parse(value.trim());
      }

      // Tentar formato ISO
      return DateTime.parse(value.trim());
    } catch (e) {
      return null;
    }
  }
}

/// Input formatters para campos de texto
class AppInputFormatters {
  /// Formatter para números decimais
  static List<TextInputFormatter> decimal({int? decimalPlaces}) {
    return [
      FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
      TextInputFormatter.withFunction((oldValue, newValue) {
        // Substituir vírgula por ponto
        String text = newValue.text.replaceAll(',', '.');

        // Permitir apenas um ponto decimal
        final parts = text.split('.');
        if (parts.length > 2) {
          text = '${parts[0]}.${parts.sublist(1).join('')}';
        }

        // Limitar casas decimais
        if (decimalPlaces != null && parts.length == 2) {
          if (parts[1].length > decimalPlaces) {
            text = '${parts[0]}.${parts[1].substring(0, decimalPlaces)}';
          }
        }

        return TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      }),
    ];
  }

  /// Formatter para números inteiros
  static List<TextInputFormatter> integer() {
    return [FilteringTextInputFormatter.digitsOnly];
  }

  /// Formatter para código de produto
  static List<TextInputFormatter> productCode() {
    return [
      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9._/-]')),
      LengthLimitingTextInputFormatter(30),
    ];
  }

  /// Formatter para código de barras
  static List<TextInputFormatter> barcode() {
    return [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(14),
    ];
  }

  /// Formatter para TAG
  static List<TextInputFormatter> tag() {
    return [
      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
      LengthLimitingTextInputFormatter(20),
      UpperCaseTextFormatter(),
    ];
  }

  /// Formatter para CPF
  static List<TextInputFormatter> cpf() {
    return [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(11),
      CpfInputFormatter(),
    ];
  }

  /// Formatter para CNPJ
  static List<TextInputFormatter> cnpj() {
    return [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(14),
      CnpjInputFormatter(),
    ];
  }

  /// Formatter para CEP
  static List<TextInputFormatter> cep() {
    return [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(8),
      CepInputFormatter(),
    ];
  }

  /// Formatter para telefone
  static List<TextInputFormatter> phone() {
    return [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(11),
      PhoneInputFormatter(),
    ];
  }
}

/// Formatter para texto em maiúsculas
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

/// Formatter para CPF
class CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (text.length <= 11) {
      String formatted = text;

      if (text.length > 3) {
        formatted = '${text.substring(0, 3)}.${text.substring(3)}';
      }
      if (text.length > 6) {
        formatted = '${formatted.substring(0, 7)}.${formatted.substring(7)}';
      }
      if (text.length > 9) {
        formatted = '${formatted.substring(0, 11)}-${formatted.substring(11)}';
      }

      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }

    return oldValue;
  }
}

/// Formatter para CNPJ
class CnpjInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (text.length <= 14) {
      String formatted = text;

      if (text.length > 2) {
        formatted = '${text.substring(0, 2)}.${text.substring(2)}';
      }
      if (text.length > 5) {
        formatted = '${formatted.substring(0, 6)}.${formatted.substring(6)}';
      }
      if (text.length > 8) {
        formatted = '${formatted.substring(0, 10)}/${formatted.substring(10)}';
      }
      if (text.length > 12) {
        formatted = '${formatted.substring(0, 15)}-${formatted.substring(15)}';
      }

      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }

    return oldValue;
  }
}

/// Formatter para CEP
class CepInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (text.length <= 8) {
      String formatted = text;

      if (text.length > 5) {
        formatted = '${text.substring(0, 5)}-${text.substring(5)}';
      }

      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }

    return oldValue;
  }
}

/// Formatter para telefone
class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (text.length <= 11) {
      String formatted = text;

      if (text.length > 2) {
        formatted = '(${text.substring(0, 2)}) ${text.substring(2)}';
      }
      if (text.length > 7) {
        final middle = text.length == 11 ? 7 : 6;
        formatted =
            '${formatted.substring(0, formatted.length - (text.length - middle))}-${text.substring(middle)}';
      }

      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }

    return oldValue;
  }
}
