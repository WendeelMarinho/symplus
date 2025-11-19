import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../providers/locale_provider.dart';

/// Classe de localizações do app
/// 
/// Carrega traduções de arquivos JSON e fornece métodos para acessar strings traduzidas.
class AppLocalizations {
  final Locale locale;
  late Map<String, dynamic> _localizedStrings;

  AppLocalizations(this.locale);

  /// Carrega as strings traduzidas do arquivo JSON
  Future<void> load() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/locales/${locale.languageCode}.json',
      );
      _localizedStrings = json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      // Se falhar, tentar carregar pt como fallback
      try {
        final jsonString = await rootBundle.loadString(
          'assets/locales/pt.json',
        );
        _localizedStrings = json.decode(jsonString) as Map<String, dynamic>;
      } catch (e2) {
        _localizedStrings = {};
      }
    }
  }

  /// Obtém uma string traduzida usando notação de ponto (ex: "dashboard.title")
  String translate(String key, {Map<String, String>? params}) {
    final keys = key.split('.');
    dynamic value = _localizedStrings;

    for (final k in keys) {
      if (value is Map<String, dynamic>) {
        value = value[k];
      } else {
        return key; // Retorna a chave se não encontrar
      }
    }

    if (value is String) {
      // Substituir parâmetros se fornecidos
      if (params != null) {
        var result = value;
        params.forEach((paramKey, paramValue) {
          result = result.replaceAll('{$paramKey}', paramValue);
        });
        return result;
      }
      return value;
    }

    return key; // Retorna a chave se não for string
  }

  /// Método estático para obter a instância atual
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  /// Método estático para verificar se está disponível
  static bool isSupported(Locale locale) {
    return ['pt', 'en'].contains(locale.languageCode);
  }

  /// Método estático para obter o delegate
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();
}

/// Delegate para carregar as localizações
class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.isSupported(locale);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// Extensão para facilitar o acesso às traduções
extension AppLocalizationsExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  
  /// Método helper para traduzir strings
  String t(String key, {Map<String, String>? params}) {
    return l10n.translate(key, params: params);
  }
}

