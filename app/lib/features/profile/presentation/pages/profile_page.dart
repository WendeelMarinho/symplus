import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
// Import condicional para File/FileImage (apenas em mobile)
import 'dart:io' if (dart.library.html) 'dart:html' as io;
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/toast_service.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../config/api_config.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _isLoading = false;
  bool _isUploadingAvatar = false;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _avatarUrl;
  ThemeMode _themeMode = ThemeMode.system;
  String _language = 'pt_BR';
  String _currency = 'BRL';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadPreferences();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final authState = ref.read(authProvider);
    _nameController.text = authState.name ?? authState.userName ?? '';
    _emailController.text = authState.email ?? '';
    // TODO: Carregar avatar URL do backend quando disponível
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final themeIndex = prefs.getInt('theme_mode') ?? 0;
      _themeMode = ThemeMode.values[themeIndex];
      _language = prefs.getString('language') ?? 'pt_BR';
      _currency = prefs.getString('currency') ?? 'BRL';
      _avatarUrl = prefs.getString('avatar_url');
    });
  }

  Future<void> _saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
    setState(() {
      _themeMode = mode;
    });
    ToastService.showSuccess(context, 'Tema alterado. Reinicie o app para aplicar.');
  }

  Future<void> _saveLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language);
    setState(() {
      _language = language;
    });
    ToastService.showSuccess(context, 'Idioma alterado. Reinicie o app para aplicar.');
  }

  Future<void> _saveCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', currency);
    setState(() {
      _currency = currency;
    });
    ToastService.showSuccess(context, 'Moeda padrão alterada');
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _isUploadingAvatar = true;
        });

        // TODO: Implementar upload real para o backend
        // Por enquanto, apenas simular
        await Future.delayed(const Duration(seconds: 1));

        // Salvar URL localmente (placeholder)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('avatar_url', result.files.single.path!);
        
        setState(() {
          _avatarUrl = result.files.single.path;
          _isUploadingAvatar = false;
        });

        if (mounted) {
          ToastService.showSuccess(context, 'Avatar atualizado com sucesso');
        }
      }
    } catch (e) {
      setState(() {
        _isUploadingAvatar = false;
      });
      if (mounted) {
        ToastService.showError(context, 'Erro ao fazer upload do avatar: ${e.toString()}');
      }
    }
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          backgroundImage: _avatarUrl != null
              ? (_avatarUrl!.startsWith('http') || _avatarUrl!.startsWith('https')
                  ? NetworkImage(_avatarUrl!)
                  : kIsWeb
                      ? NetworkImage(_avatarUrl!)
                      : io.File(_avatarUrl!) as ImageProvider)
              : null,
          child: _avatarUrl == null
              ? Text(
                  (_nameController.text.isNotEmpty
                      ? _nameController.text[0].toUpperCase()
                      : 'U'),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                )
              : null,
        ),
        if (_isUploadingAvatar)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.surface,
                width: 2,
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
              onPressed: _isUploadingAvatar ? null : _pickAndUploadAvatar,
              tooltip: 'Alterar foto',
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Atualizar no backend (se houver endpoint)
      // Por enquanto, apenas atualizar localmente
      ToastService.showInfo(context, 'Funcionalidade de edição de perfil em breve');
      
      // TODO: Implementar quando houver endpoint PATCH /api/me
      // await DioClient.put(ApiConfig.me, data: {
      //   'name': _nameController.text,
      // });
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ToastService.showError(context, 'Erro ao atualizar perfil');
      }
    }
  }

  Future<void> _changePassword() async {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.lock_reset, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              const Text('Alterar Senha'),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Para sua segurança, confirme sua senha atual e defina uma nova senha.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: oldPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Senha Atual *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_outline),
                      helperText: 'Digite sua senha atual',
                    ),
                    obscureText: true,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Senha atual é obrigatória' : null,
                    autofocus: true,
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: newPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Nova Senha *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                      helperText: 'Mínimo de 8 caracteres',
                    ),
                    obscureText: true,
                    enabled: !isLoading,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Nova senha é obrigatória';
                      if ((value?.length ?? 0) < 8) return 'Senha deve ter no mínimo 8 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: confirmPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Confirmar Nova Senha *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    enabled: !isLoading,
                    validator: (value) {
                      if (value != newPasswordController.text) {
                        return 'Senhas não coincidem';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading
                  ? null
                  : () {
                      oldPasswordController.dispose();
                      newPasswordController.dispose();
                      confirmPasswordController.dispose();
                      Navigator.of(context).pop(false);
                    },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        setDialogState(() {
                          isLoading = true;
                        });

                        try {
                          // TODO: Implementar quando houver endpoint POST /api/me/change-password
                          await Future.delayed(const Duration(seconds: 1));
                          
                          if (context.mounted) {
                            Navigator.of(context).pop(true);
                            ToastService.showSuccess(context, 'Senha alterada com sucesso!');
                          }
                        } catch (e) {
                          setDialogState(() {
                            isLoading = false;
                          });
                          if (context.mounted) {
                            ToastService.showError(context, 'Erro ao alterar senha: ${e.toString()}');
                          }
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Alterar Senha'),
            ),
          ],
        ),
      ),
    );

    if (result != true) {
      oldPasswordController.dispose();
      newPasswordController.dispose();
      confirmPasswordController.dispose();
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Logout'),
        content: const Text('Deseja realmente sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DioClient.post(ApiConfig.logout);
      } catch (e) {
        // Continuar mesmo se houver erro
      }

      // Limpar storage
      await StorageService.clearAll();

      // Resetar auth state
      ref.read(authProvider.notifier).logout();

      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Column(
      children: [
        PageHeader(
          title: 'Perfil',
          subtitle: 'Gerencie suas informações pessoais e preferências',
          breadcrumbs: const ['Conta', 'Perfil'],
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Card de Avatar e Informações Pessoais
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.person,
                                color: Theme.of(context).colorScheme.primary,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Informações Pessoais',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Avatar
                          Center(
                            child: _buildAvatar(),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Nome',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (value) =>
                                value?.isEmpty ?? true ? 'Nome é obrigatório' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'E-mail',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            enabled: false, // Email não pode ser alterado
                            validator: (value) =>
                                value?.isEmpty ?? true ? 'E-mail é obrigatório' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            initialValue: authState.role == 'owner'
                                ? 'Proprietário'
                                : authState.role == 'admin'
                                    ? 'Administrador'
                                    : 'Usuário',
                            decoration: const InputDecoration(
                              labelText: 'Papel',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                            enabled: false,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _isLoading ? null : _updateProfile,
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.save),
                              label: const Text('Salvar Alterações'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Card de Preferências
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.settings,
                                color: Theme.of(context).colorScheme.primary,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Preferências',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Tema
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.palette),
                            title: const Text('Tema'),
                            subtitle: Text(_getThemeModeLabel(_themeMode)),
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
                          const Divider(),
                          // Idioma
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.language),
                            title: const Text('Idioma'),
                            subtitle: Text(_getLanguageLabel(_language)),
                            trailing: DropdownButton<String>(
                              value: _language,
                              items: const [
                                DropdownMenuItem(
                                  value: 'pt_BR',
                                  child: Text('Português (BR)'),
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
                          // Moeda
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.attach_money),
                            title: const Text('Moeda Padrão'),
                            subtitle: Text(_getCurrencyLabel(_currency)),
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
                                DropdownMenuItem(
                                  value: 'GBP',
                                  child: Text('GBP - Libra'),
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
                  const SizedBox(height: 16),

                  // Card de Segurança
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lock,
                                color: Theme.of(context).colorScheme.primary,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Segurança',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _changePassword,
                              icon: const Icon(Icons.lock_reset),
                              label: const Text('Alterar Senha'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Botão de Logout
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Sair'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getThemeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Segue o sistema';
      case ThemeMode.light:
        return 'Tema claro';
      case ThemeMode.dark:
        return 'Tema escuro';
    }
  }

  String _getLanguageLabel(String language) {
    switch (language) {
      case 'pt_BR':
        return 'Português (Brasil)';
      case 'en_US':
        return 'English (United States)';
      case 'es_ES':
        return 'Español (España)';
      default:
        return language;
    }
  }

  String _getCurrencyLabel(String currency) {
    switch (currency) {
      case 'BRL':
        return 'Real Brasileiro';
      case 'USD':
        return 'Dólar Americano';
      case 'EUR':
        return 'Euro';
      case 'GBP':
        return 'Libra Esterlina';
      default:
        return currency;
    }
  }
}
