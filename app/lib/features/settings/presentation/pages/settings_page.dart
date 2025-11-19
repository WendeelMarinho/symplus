import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/providers/avatar_provider.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../core/widgets/toast_service.dart';
import '../../../../core/accessibility/telemetry_service.dart';
import '../../../../core/accessibility/responsive_utils.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/services/avatar_service.dart';
import 'package:file_picker/file_picker.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  ThemeMode _themeMode = ThemeMode.system;

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

  Future<void> _pickAndUploadAvatar(
    BuildContext context,
    WidgetRef ref,
    AvatarNotifier avatarNotifier,
  ) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
      );

      if (result != null && result.files.single.path != null || result.files.single.bytes != null) {
        final file = result.files.single;
        
        // Validar tamanho (5MB)
        const maxSize = 5 * 1024 * 1024;
        if (file.size > maxSize) {
          if (context.mounted) {
            ToastService.showError(context, 'Arquivo muito grande. Máximo: 5MB');
          }
          return;
        }

        // Atualizar estado para mostrar loading
        avatarNotifier.setLoading(true);

        try {
          // Fazer upload
          final url = await AvatarService.uploadAvatar(
            file: file,
            ref: ref,
            onSendProgress: (sent, total) {
              // Opcional: mostrar progresso
            },
          );

          // Salvar URL no provider
          await avatarNotifier.setAvatar(url);

          if (context.mounted) {
            ToastService.showSuccess(context, 'Avatar atualizado com sucesso!');
            TelemetryService.logAction('settings.avatar_uploaded');
          }
        } catch (e) {
          if (context.mounted) {
            ToastService.showError(context, 'Erro ao fazer upload: ${e.toString()}');
          }
          TelemetryService.logError(e.toString(), context: 'settings.avatar_upload');
        } finally {
          avatarNotifier.setLoading(false);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ToastService.showError(context, 'Erro ao selecionar arquivo: ${e.toString()}');
      }
      TelemetryService.logError(e.toString(), context: 'settings.avatar_pick');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PageHeader(
          title: context.t('settings.title'),
          subtitle: context.t('settings.subtitle'),
          breadcrumbs: [
            context.t('settings.breadcrumbs_0'),
            context.t('settings.breadcrumbs_1'),
          ],
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
                              context.t('settings.appearance.title'),
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          title: Text(context.t('settings.appearance.theme')),
                          subtitle: Text(context.t('settings.appearance.theme_description')),
                          trailing: DropdownButton<ThemeMode>(
                            value: _themeMode,
                            items: [
                              DropdownMenuItem(
                                value: ThemeMode.system,
                                child: Text(context.t('settings.appearance.system')),
                              ),
                              DropdownMenuItem(
                                value: ThemeMode.light,
                                child: Text(context.t('settings.appearance.light')),
                              ),
                              DropdownMenuItem(
                                value: ThemeMode.dark,
                                child: Text(context.t('settings.appearance.dark')),
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
                              context.t('settings.language.title'),
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Consumer(
                          builder: (context, ref, child) {
                            final localeState = ref.watch(localeProvider);
                            final localeNotifier = ref.read(localeProvider.notifier);

                            return ListTile(
                              title: Text(context.t('settings.language.language')),
                              subtitle: Text(context.t('settings.language.language_description')),
                              trailing: DropdownButton<AppLocale>(
                                value: localeState.locale,
                                items: const [
                                  DropdownMenuItem(
                                    value: AppLocale.pt,
                                    child: Text('Português (Brasil)'),
                                  ),
                                  DropdownMenuItem(
                                    value: AppLocale.en,
                                    child: Text('English (US)'),
                                  ),
                                ],
                                onChanged: (value) async {
                                  if (value != null) {
                                    await localeNotifier.setLocale(value);
                                    TelemetryService.logAction(
                                      'settings.language_changed',
                                      metadata: {'locale': value.code},
                                    );
                                    if (mounted) {
                                      ToastService.showSuccess(
                                        context,
                                        context.t('settings.language.language_changed', params: {
                                          'language': value == AppLocale.pt
                                              ? context.t('settings.language.pt_br')
                                              : context.t('settings.language.en_us'),
                                        }),
                                      );
                                    }
                                  }
                                },
                              ),
                            );
                          },
                        ),
                        const Divider(),
                        // Avatar/Logo
                        Consumer(
                          builder: (context, ref, child) {
                            final authState = ref.watch(authProvider);
                            final avatarState = ref.watch(avatarProvider);
                            final avatarNotifier = ref.read(avatarProvider.notifier);
                            final isCompany = authState.organizationName != null && 
                                             authState.organizationName!.isNotEmpty;

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: UserAvatar(
                                radius: 30,
                                showEditButton: true,
                                onEditTap: () => _pickAndUploadAvatar(context, ref, avatarNotifier),
                              ),
                              title: Text(isCompany ? 'Logo da Empresa' : 'Foto do Usuário'),
                              subtitle: Text(
                                isCompany 
                                    ? 'Clique no ícone para alterar o logo'
                                    : 'Clique no ícone para alterar sua foto',
                              ),
                              trailing: avatarState.isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : null,
                            );
                          },
                        ),
                        const Divider(),
                        Consumer(
                          builder: (context, ref, child) {
                            final currencyState = ref.watch(currencyProvider);
                            final currencyNotifier = ref.read(currencyProvider.notifier);

                            return ListTile(
                              title: const Text('Moeda Padrão'),
                              subtitle: Text('Moeda usada por padrão: ${currencyState.name}'),
                              trailing: DropdownButton<CurrencyType>(
                                value: currencyState.currency,
                                items: const [
                                  DropdownMenuItem(
                                    value: CurrencyType.brl,
                                    child: Text('BRL - Real Brasileiro'),
                                  ),
                                  DropdownMenuItem(
                                    value: CurrencyType.usd,
                                    child: Text('USD - Dólar Americano'),
                                  ),
                                ],
                                onChanged: (value) async {
                                  if (value != null) {
                                    await currencyNotifier.setCurrency(value);
                                    TelemetryService.logAction(
                                      'settings.currency_changed',
                                      metadata: {'currency': value.name},
                                    );
                                    if (mounted) {
                                      ToastService.showSuccess(
                                        context,
                                        'Moeda alterada para ${value == CurrencyType.brl ? 'Real Brasileiro' : 'Dólar Americano'}',
                                      );
                                    }
                                  }
                                },
                              ),
                            );
                          },
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
