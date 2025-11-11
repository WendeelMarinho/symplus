import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/widgets/page_header.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  ThemeMode _themeMode = ThemeMode.system;
  String _language = 'pt_BR';
  String _currency = 'BRL';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final themeIndex = prefs.getInt('theme_mode') ?? 0;
      _themeMode = ThemeMode.values[themeIndex];
      _language = prefs.getString('language') ?? 'pt_BR';
      _currency = prefs.getString('currency') ?? 'BRL';
    });
  }

  Future<void> _saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
    setState(() {
      _themeMode = mode;
    });
    // Notificar mudança de tema (seria necessário um provider para isso)
    // Por enquanto, apenas salvar a preferência
  }

  Future<void> _saveLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language);
    setState(() {
      _language = language;
    });
    // TODO: Implementar mudança de idioma
  }

  Future<void> _saveCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', currency);
    setState(() {
      _currency = currency;
    });
    // TODO: Implementar mudança de moeda
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PageHeader(
          title: 'Configurações',
          subtitle: 'Personalize a experiência do aplicativo',
          breadcrumbs: const ['Conta', 'Configurações'],
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Aparência
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.palette,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Aparência',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          title: const Text('Tema'),
                          subtitle: const Text('Escolha o tema do aplicativo'),
                          trailing: DropdownButton<ThemeMode>(
                            value: _themeMode,
                            items: const [
                              DropdownMenuItem(
                                value: ThemeMode.system,
                                child: Text('Sistema'),
                              ),
                              DropdownMenuItem(
                                value: ThemeMode.light,
                                child: Text('Claro'),
                              ),
                              DropdownMenuItem(
                                value: ThemeMode.dark,
                                child: Text('Escuro'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                _saveThemeMode(value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Idioma e Localização
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.language,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Idioma e Localização',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          title: const Text('Idioma'),
                          subtitle: const Text('Escolha o idioma do aplicativo'),
                          trailing: DropdownButton<String>(
                            value: _language,
                            items: const [
                              DropdownMenuItem(
                                value: 'pt_BR',
                                child: Text('Português (Brasil)'),
                              ),
                              DropdownMenuItem(
                                value: 'en_US',
                                child: Text('English (US)'),
                              ),
                              DropdownMenuItem(
                                value: 'es_ES',
                                child: Text('Español'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                _saveLanguage(value);
                              }
                            },
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          title: const Text('Moeda Padrão'),
                          subtitle: const Text('Moeda usada por padrão'),
                          trailing: DropdownButton<String>(
                            value: _currency,
                            items: const [
                              DropdownMenuItem(
                                value: 'BRL',
                                child: Text('BRL - Real'),
                              ),
                              DropdownMenuItem(
                                value: 'USD',
                                child: Text('USD - Dólar'),
                              ),
                              DropdownMenuItem(
                                value: 'EUR',
                                child: Text('EUR - Euro'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                _saveCurrency(value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
