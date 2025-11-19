import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tipos de moeda disponíveis
enum CurrencyType {
  brl,
  usd,
}

/// Estado da moeda selecionada
class CurrencyState {
  final CurrencyType currency;

  const CurrencyState({required this.currency});

  CurrencyState copyWith({CurrencyType? currency}) {
    return CurrencyState(currency: currency ?? this.currency);
  }

  /// Retorna o símbolo da moeda
  String get symbol {
    switch (currency) {
      case CurrencyType.brl:
        return 'R\$';
      case CurrencyType.usd:
        return 'US\$';
    }
  }

  /// Retorna o código da moeda para formatação
  String get locale {
    switch (currency) {
      case CurrencyType.brl:
        return 'pt_BR';
      case CurrencyType.usd:
        return 'en_US';
    }
  }

  /// Retorna o nome da moeda
  String get name {
    switch (currency) {
      case CurrencyType.brl:
        return 'Real Brasileiro';
      case CurrencyType.usd:
        return 'Dólar Americano';
    }
  }

  /// Retorna o código ISO da moeda
  String get code {
    switch (currency) {
      case CurrencyType.brl:
        return 'BRL';
      case CurrencyType.usd:
        return 'USD';
    }
  }
}

/// Provider do filtro de moeda
class CurrencyNotifier extends StateNotifier<CurrencyState> {
  static const String _storageKey = 'selected_currency';

  CurrencyNotifier() : super(const CurrencyState(currency: CurrencyType.brl)) {
    _loadCurrency();
  }

  /// Carrega a moeda salva do storage
  Future<void> _loadCurrency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currencyString = prefs.getString(_storageKey);
      if (currencyString != null) {
        final currency = CurrencyType.values.firstWhere(
          (e) => e.name == currencyString,
          orElse: () => CurrencyType.brl,
        );
        state = CurrencyState(currency: currency);
      }
    } catch (e) {
      // Se houver erro, manter padrão (BRL)
    }
  }

  /// Define a moeda
  Future<void> setCurrency(CurrencyType currency) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, currency.name);
      state = CurrencyState(currency: currency);
    } catch (e) {
      // Se houver erro ao salvar, ainda atualiza o estado
      state = CurrencyState(currency: currency);
    }
  }

  /// Alterna entre BRL e USD
  Future<void> toggleCurrency() async {
    final newCurrency = state.currency == CurrencyType.brl
        ? CurrencyType.usd
        : CurrencyType.brl;
    await setCurrency(newCurrency);
  }
}

/// Provider global da moeda
final currencyProvider =
    StateNotifierProvider<CurrencyNotifier, CurrencyState>((ref) {
  return CurrencyNotifier();
});

