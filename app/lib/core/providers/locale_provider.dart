import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Locales suportados
enum AppLocale {
  pt('pt', 'PT'),
  en('en', 'EN');

  final String code;
  final String name;

  const AppLocale(this.code, this.name);

  Locale get locale => Locale(code);
}

/// Estado do locale
class LocaleState {
  final AppLocale locale;

  const LocaleState({required this.locale});

  LocaleState copyWith({AppLocale? locale}) {
    return LocaleState(locale: locale ?? this.locale);
  }

  Locale get flutterLocale => locale.locale;
}

/// Provider do locale
class LocaleNotifier extends StateNotifier<LocaleState> {
  static const String _storageKey = 'selected_locale';

  LocaleNotifier() : super(const LocaleState(locale: AppLocale.pt)) {
    _loadLocale();
  }

  /// Carrega o locale salvo do storage
  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localeString = prefs.getString(_storageKey);
      if (localeString != null) {
        final locale = AppLocale.values.firstWhere(
          (e) => e.code == localeString,
          orElse: () => AppLocale.pt,
        );
        state = LocaleState(locale: locale);
      }
    } catch (e) {
      // Se houver erro, manter padrão (PT)
    }
  }

  /// Define o locale
  Future<void> setLocale(AppLocale locale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, locale.code);
      state = LocaleState(locale: locale);
    } catch (e) {
      // Se houver erro ao salvar, ainda atualiza o estado
      state = LocaleState(locale: locale);
    }
  }

  /// Alterna entre PT e EN
  Future<void> toggleLocale() async {
    final newLocale = state.locale == AppLocale.pt
        ? AppLocale.en
        : AppLocale.pt;
    await setLocale(newLocale);
  }
}

/// Provider global do locale
final localeProvider =
    StateNotifierProvider<LocaleNotifier, LocaleState>((ref) {
  return LocaleNotifier();
});

