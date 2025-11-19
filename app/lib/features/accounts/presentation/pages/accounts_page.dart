import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../../../core/widgets/action_bar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_state.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/toast_service.dart';
import '../../../../core/widgets/list_item_card.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../../core/navigation/menu_catalog.dart';
import '../../../../core/accessibility/telemetry_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/account_service.dart';
import '../../data/models/account.dart';
import 'account_detail_page.dart';

class AccountsPage extends ConsumerStatefulWidget {
  const AccountsPage({super.key});

  @override
  ConsumerState<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends ConsumerState<AccountsPage> {
  List<Account> _accounts = [];
  bool _isLoading = true;
  bool _isCreating = false;
  String? _error;
  String? _searchQuery = '';
  String? _filterType;
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Verificar se há query param para abrir diálogo automaticamente
    final uri = GoRouterState.of(context).uri;
    if (uri.queryParameters['action'] == 'create') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isLoading) {
          _showCreateDialog();
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // Debounce search - recarregar após 500ms sem digitação
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchController.text != _searchQuery) {
        setState(() {
          _searchQuery = _searchController.text;
          _currentPage = 1;
        });
        _loadAccounts();
      }
    });
  }

  Future<void> _loadAccounts({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final response = await AccountService.list(
        search: _searchQuery?.isEmpty ?? true ? null : _searchQuery,
        type: _filterType,
        page: _currentPage,
        perPage: 15,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final accountsData = data['data'] as List<dynamic>;
        final meta = data['meta'] ?? {};

        setState(() {
          if (_currentPage == 1) {
            _accounts = accountsData.map((json) => Account.fromJson(json)).toList();
          } else {
            _accounts.addAll(
              accountsData.map((json) => Account.fromJson(json)).toList(),
            );
          }
          _totalPages = meta['last_page'] ?? 1;
          _hasMore = _currentPage < (_totalPages);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _showCreateDialog() async {
    final nameController = TextEditingController();
    final currencyController = TextEditingController(text: 'BRL');
    final balanceController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: !_isCreating,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.add_circle, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              const Text('Nova Conta'),
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
                    'Preencha os dados da nova conta financeira.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome da Conta *',
                      hintText: 'Ex: Conta Corrente, Poupança',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.account_balance_wallet),
                      helperText: 'Nome que identifica esta conta',
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Nome é obrigatório' : null,
                    autofocus: true,
                    enabled: !isSubmitting,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: currencyController,
                    decoration: const InputDecoration(
                      labelText: 'Moeda *',
                      hintText: 'BRL, USD, EUR',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                      helperText: 'Código da moeda (3 letras)',
                    ),
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 3,
                    enabled: !isSubmitting,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Moeda é obrigatória';
                      if ((value?.length ?? 0) != 3) return 'Moeda deve ter exatamente 3 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: balanceController,
                    decoration: const InputDecoration(
                      labelText: 'Saldo Inicial (opcional)',
                      hintText: '0.00',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.account_balance),
                      helperText: 'Saldo inicial da conta',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    enabled: !isSubmitting,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        setDialogState(() {
                          isSubmitting = true;
                        });
                        
                        // Fechar diálogo e criar conta
                        Navigator.of(context).pop(true);
                        
                        await _createAccount(
                          name: nameController.text.trim(),
                          currency: currencyController.text.toUpperCase().trim(),
                          openingBalance: balanceController.text.isNotEmpty
                              ? double.tryParse(balanceController.text.replaceAll(',', '.'))
                              : null,
                        );
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Criar Conta'),
            ),
          ],
        ),
      ),
    );

    // Limpar controllers após um delay para garantir que o diálogo foi fechado
    Future.delayed(const Duration(milliseconds: 300), () {
      nameController.dispose();
      currencyController.dispose();
      balanceController.dispose();
    });
  }

  Future<void> _createAccount({
    required String name,
    required String currency,
    double? openingBalance,
  }) async {
    setState(() {
      _isCreating = true;
    });

    try {
      final response = await AccountService.create(
        name: name,
        currency: currency,
        openingBalance: openingBalance,
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ToastService.showSuccess(context, 'Conta criada com sucesso!');
          setState(() {
            _currentPage = 1;
            _isCreating = false;
          });
          await _loadAccounts();
        }
      } else {
        if (mounted) {
          setState(() {
            _isCreating = false;
          });
          ToastService.showError(
            context,
            'Erro ao criar conta: Status ${response.statusCode}',
          );
        }
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
        final errorMessage = e.response?.data?['message'] ?? 
                           e.response?.data?['error'] ?? 
                           e.message ?? 
                           'Erro ao criar conta';
        ToastService.showError(context, errorMessage);
        
        // Log de erro
        TelemetryService.logError(
          'Erro ao criar conta: ${e.response?.statusCode}',
          metadata: {'response': e.response?.data?.toString() ?? 'N/A'},
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
        ToastService.showError(context, 'Erro ao criar conta: ${e.toString()}');
        TelemetryService.logError('Erro inesperado ao criar conta: $e');
      }
    }
  }

  Future<void> _editAccount(Account account) async {
    final nameController = TextEditingController(text: account.name);
    final currencyController = TextEditingController(text: account.currency);
    final balanceController = TextEditingController(
      text: account.openingBalance?.toString() ?? '',
    );

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Conta'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome da Conta *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Nome é obrigatório' : null,
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: currencyController,
                  decoration: const InputDecoration(
                    labelText: 'Moeda *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Moeda é obrigatória';
                    if ((value?.length ?? 0) != 3) return 'Moeda deve ter 3 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: balanceController,
                  decoration: const InputDecoration(
                    labelText: 'Saldo Inicial',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(true);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await AccountService.update(
          account.id,
          name: nameController.text,
          currency: currencyController.text.toUpperCase(),
          openingBalance: balanceController.text.isNotEmpty
              ? double.tryParse(balanceController.text.replaceAll(',', '.'))
              : null,
        );
        if (mounted) {
          ToastService.showSuccess(context, 'Conta atualizada com sucesso!');
          _loadAccounts();
        }
      } on DioException catch (e) {
        if (mounted) {
          ToastService.showError(
            context,
            e.response?.data['message'] ?? 'Erro ao atualizar conta',
          );
        }
      } catch (e) {
        if (mounted) {
          ToastService.showError(context, 'Erro ao atualizar conta');
        }
      }
    }

    nameController.dispose();
    currencyController.dispose();
    balanceController.dispose();
  }

  Future<void> _deleteAccount(Account account) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Confirmar Exclusão',
      message: 'Deseja realmente excluir a conta "${account.name}"? Esta ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
      cancelLabel: 'Cancelar',
      icon: Icons.delete,
      isDestructive: true,
    );

    if (confirmed) {
      try {
        await AccountService.delete(account.id);
        if (mounted) {
          ToastService.showSuccess(context, 'Conta excluída com sucesso!');
          setState(() {
            _currentPage = 1;
          });
          _loadAccounts();
        }
      } on DioException catch (e) {
        if (mounted) {
          final message = e.response?.data['message'] ?? 'Erro ao excluir conta';
          ToastService.showError(context, message);
        }
      } catch (e) {
        if (mounted) {
          ToastService.showError(context, 'Erro ao excluir conta');
        }
      }
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrar Contas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String?>(
              title: const Text('Todas'),
              value: null,
              groupValue: _filterType,
              onChanged: (value) {
                setState(() => _filterType = value);
                Navigator.of(context).pop();
                setState(() {
                  _currentPage = 1;
                });
                _loadAccounts();
              },
            ),
            // Nota: Backend não tem tipo ainda, mas podemos adicionar filtros futuros aqui
            // Por enquanto, apenas "Todas"
          ],
        ),
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _filterType = null;
      _searchController.clear();
      _searchQuery = '';
      _currentPage = 1;
    });
    _loadAccounts();
  }

  String _formatCurrency(double value, String currency) {
    return NumberFormat.currency(
      locale: 'pt_BR',
      symbol: currency == 'BRL' ? 'R\$' : currency,
    ).format(value);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    // Permitir criar conta para owner e admin
    final canEdit = authState.role == UserRole.owner || authState.role == UserRole.admin;

    final hasFilters = _filterType != null || (_searchQuery?.isNotEmpty ?? false);

    return Column(
      children: [
        PageHeader(
          title: 'Contas',
          subtitle: 'Gerencie suas contas bancárias e financeiras',
          breadcrumbs: const ['Financeiro', 'Contas'],
          actions: [
            // Botão Adicionar Conta no header (sempre visível, desabilitado se não tiver permissão)
            // Usar ElevatedButton para garantir visibilidade em todas as telas
            ElevatedButton.icon(
              onPressed: (canEdit && !_isCreating) ? _showCreateDialog : null,
              icon: _isCreating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.add_circle, size: 20),
              label: Text(_isCreating ? 'Criando...' : 'Adicionar Conta'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                minimumSize: const Size(140, 40),
              ),
            ),
            if (hasFilters)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: _clearFilters,
                tooltip: 'Limpar filtros',
              ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
              tooltip: 'Filtrar',
            ),
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () {
                ToastService.showInfo(context, 'Exportação em breve');
              },
              tooltip: 'Exportar',
            ),
          ],
        ),
        // Barra de busca
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar contas...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                          _currentPage = 1;
                        });
                        _loadAccounts();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        // ActionBar com botão Adicionar Conta (sempre visível)
        if (!_isCreating)
          ActionBar(
            actions: [
              ActionItem(
                label: 'Adicionar Conta',
                icon: Icons.add_circle,
                onPressed: canEdit ? _showCreateDialog : null,
                type: ActionType.primary,
              ),
            ],
          ),
        Expanded(
          child: _isLoading && _accounts.isEmpty
              ? const LoadingState(message: 'Carregando contas...')
              : _error != null && _accounts.isEmpty
                  ? ErrorState(
                      message: _error!,
                      onRetry: () {
                        setState(() {
                          _currentPage = 1;
                        });
                        _loadAccounts();
                      },
                    )
                  : _accounts.isEmpty
                      ? Column(
                          children: [
                            Expanded(
                              child: EmptyState(
                                icon: Icons.account_balance_wallet,
                                title: 'Nenhuma conta encontrada',
                                message: _searchQuery?.isNotEmpty ?? false
                                    ? 'Nenhuma conta corresponde à busca.'
                                    : 'Crie sua primeira conta para começar a gerenciar suas finanças.',
                                actionLabel: canEdit ? 'Criar Primeira Conta' : null,
                                onAction: canEdit ? _showCreateDialog : null,
                              ),
                            ),
                            // Botão adicional sempre visível no bottom
                            if (canEdit)
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: _isCreating ? null : _showCreateDialog,
                                    icon: _isCreating
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : const Icon(Icons.add_circle, size: 24),
                                    label: Text(
                                      _isCreating ? 'Criando conta...' : 'Adicionar Conta',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            setState(() {
                              _currentPage = 1;
                            });
                            await _loadAccounts();
                          },
                          child: ListView.builder(
                            itemCount: _accounts.length + (_hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _accounts.length) {
                                // Botão "Carregar mais"
                                return Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Center(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          _currentPage++;
                                        });
                                        _loadAccounts(showLoading: false);
                                      },
                                      icon: const Icon(Icons.expand_more),
                                      label: const Text('Carregar mais'),
                                    ),
                                  ),
                                );
                              }

                              final account = _accounts[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: account.balance >= 0 
                                        ? Colors.green.shade100 
                                        : Colors.red.shade100,
                                    child: Icon(
                                      Icons.account_balance_wallet,
                                      color: account.balance >= 0 
                                          ? Colors.green.shade700 
                                          : Colors.red.shade700,
                                    ),
                                  ),
                                  title: Text(
                                    account.name,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  subtitle: Text(
                                    '${account.currency} • Último movimento: ${DateFormat('dd/MM/yyyy').format(account.updatedAt)}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _formatCurrency(account.balance, account.currency),
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: account.balance >= 0 
                                                      ? Colors.green.shade700 
                                                      : Colors.red.shade700,
                                                ),
                                          ),
                                        ],
                                      ),
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert),
                                        tooltip: 'Ações',
                                        onSelected: (value) {
                                          switch (value) {
                                            case 'edit':
                                              _editAccount(account);
                                              break;
                                            case 'view':
                                              context.push('/app/accounts/${account.id}');
                                              break;
                                            case 'archive':
                                              // Placeholder para arquivar
                                              ToastService.showInfo(context, 'Funcionalidade em breve');
                                              break;
                                            case 'open_finance':
                                              // Placeholder para Open Finance
                                              ToastService.showInfo(context, 'Open Finance em breve');
                                              break;
                                            case 'delete':
                                              _deleteAccount(account);
                                              break;
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          if (canEdit)
                                            const PopupMenuItem(
                                              value: 'edit',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit, size: 20),
                                                  SizedBox(width: 8),
                                                  Text('Editar'),
                                                ],
                                              ),
                                            ),
                                          const PopupMenuItem(
                                            value: 'view',
                                            child: Row(
                                              children: [
                                                Icon(Icons.visibility, size: 20),
                                                SizedBox(width: 8),
                                                Text('Ver detalhes'),
                                              ],
                                            ),
                                          ),
                                          if (canEdit) ...[
                                            const PopupMenuItem(
                                              value: 'archive',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.archive, size: 20),
                                                  SizedBox(width: 8),
                                                  Text('Arquivar'),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'open_finance',
                                              enabled: false,
                                              child: Row(
                                                children: [
                                                  Icon(Icons.account_balance, size: 20),
                                                  SizedBox(width: 8),
                                                  Text('Open Finance'),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuDivider(),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.delete, size: 20, color: Colors.red),
                                                  SizedBox(width: 8),
                                                  Text('Excluir', style: TextStyle(color: Colors.red)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                  onTap: () => context.push('/app/accounts/${account.id}'),
                                ),
                              );
                            },
                          ),
                        ),
        ),
      ],
    );
  }
}
