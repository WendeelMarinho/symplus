import 'package:intl/intl.dart';
import '../providers/currency_provider.dart';

/// Utilitário para formatação de moeda
class CurrencyFormatter {
  /// Formata um valor monetário baseado na moeda selecionada
  static String format(double value, CurrencyState currencyState) {
    return NumberFormat.currency(
      locale: currencyState.locale,
      symbol: currencyState.symbol,
    ).format(value);
  }

  /// Formata um valor monetário sem símbolo (apenas número formatado)
  static String formatNumber(double value, CurrencyState currencyState) {
    return NumberFormat.currency(
      locale: currencyState.locale,
      symbol: '',
      decimalDigits: 2,
    ).format(value);
  }

  /// Formata um valor monetário com símbolo customizado
  static String formatWithSymbol(
    double value,
    CurrencyState currencyState,
    String symbol,
  ) {
    return NumberFormat.currency(
      locale: currencyState.locale,
      symbol: symbol,
    ).format(value);
  }

  /// Formata um percentual
  static String formatPercentage(double value) {
    return '${value.toStringAsFixed(1)}%';
  }
}

