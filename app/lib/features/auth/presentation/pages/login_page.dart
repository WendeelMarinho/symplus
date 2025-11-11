import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../config/api_config.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await DioClient.post(
        ApiConfig.login,
        data: {
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final token = data['token'] as String;
        final user = data['user'] as Map<String, dynamic>;
        
        // Obter primeira organização do usuário
        final organizations = user['organizations'] as List<dynamic>?;
        if (organizations != null && organizations.isNotEmpty) {
          final orgId = organizations[0]['id'].toString();

          // Salvar token e organization ID
          await StorageService.saveToken(token);
          await StorageService.saveOrganizationId(orgId);
          await StorageService.saveUserId(user['id'].toString());

          // Fazer login no provider com dados da API
          await ref.read(authProvider.notifier).login(
                email: _emailController.text.trim(),
                password: _passwordController.text,
                userId: user['id'].toString(),
                organizationId: orgId,
                organizationName: organizations[0]['name'] as String?,
                name: user['name'] as String?,
                // TODO: Buscar role real da API depois
              );

          if (!mounted) return;
          context.go('/app/dashboard');
        } else {
          setState(() {
            _errorMessage = 'Usuário não possui organizações associadas. Execute o seeder.';
            _isLoading = false;
          });
        }
      }
    } on DioException catch (e) {
      setState(() {
        String message;
        
        // Erros de conexão/rede
        if (e.type == DioExceptionType.connectionError || 
            e.type == DioExceptionType.connectionTimeout ||
            e.message?.contains('XMLHttpRequest') == true ||
            e.message?.contains('connection error') == true) {
          message = 'Não foi possível conectar ao servidor.\n\n'
              'Verifique se o backend está rodando:\n'
              '1. cd backend\n'
              '2. make up (ou docker compose up -d)\n'
              '3. make migrate\n'
              '4. make seed\n\n'
              'URL esperada: ${ApiConfig.baseUrl}';
        }
        // Erros de timeout
        else if (e.type == DioExceptionType.receiveTimeout ||
                 e.type == DioExceptionType.sendTimeout) {
          message = 'Tempo de espera esgotado. Tente novamente.';
        }
        // Erros HTTP
        else if (e.response != null) {
          final statusCode = e.response!.statusCode;
          if (statusCode == 401 || statusCode == 403) {
            message = 'Email ou senha incorretos.';
          } else if (statusCode == 422) {
            message = 'Dados inválidos. Verifique suas informações.';
          } else if (statusCode == 500) {
            message = 'Erro no servidor. Tente novamente mais tarde.';
          } else {
            message = 'Erro ao fazer login (código: $statusCode)';
          }
        }
        // Erros desconhecidos
        else {
          message = 'Erro ao fazer login. Verifique sua conexão e tente novamente.';
        }
        
        _errorMessage = message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        final errorMsg = e.toString();
        if (errorMsg.contains('401') || errorMsg.contains('credentials')) {
          _errorMessage = 'Email ou senha incorretos.';
        } else if (errorMsg.contains('organizations')) {
          _errorMessage = 'Usuário não possui organizações. Execute: make seed';
        } else {
          _errorMessage = 'Erro inesperado: ${e.toString()}';
        }
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.account_balance,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Symplus Finance',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira seu email';
                      }
                      if (!value.contains('@')) {
                        return 'Email inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira sua senha';
                      }
                      return null;
                    },
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Theme.of(context).colorScheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onErrorContainer,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Entrar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

