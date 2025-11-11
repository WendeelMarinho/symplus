import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/action_bar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_state.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/toast_service.dart';
import '../../../../core/widgets/list_item_card.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../../core/rbac/permission_helper.dart';
import '../../../../core/rbac/permissions_catalog.dart';
import '../../data/services/transaction_service.dart';
import '../../data/models/transaction.dart';
import '../../../accounts/data/services/account_service.dart';
import '../../../accounts/data/models/account.dart';
import '../../../categories/data/services/category_service.dart';
import '../../../categories/data/models/category.dart';

class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  List<Transaction> _transactions = [];
  List<Account> _accounts = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  String? _error;
  String? _filterType;
  int? _filterAccountId;
  int? _filterCategoryId;
  DateTime? _filterFrom;
  DateTime? _filterTo;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    _loadData();
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

  Future<void> _loadData() async {
    await Future.wait([
      _loadTransactions(),
      _loadAccounts(),
      _loadCategories(),
    ]);
  }

  Future<void> _loadAccounts() async {
    try {
      final response = await AccountService.list();
      if (response.statusCode == 200) {
        final data = response.data;
        final accountsData = data['data'] as List<dynamic>;
        setState(() {
          _accounts = accountsData.map((json) => Account.fromJson(json)).toList();
        });
      }
    } catch (e) {
      // Silently fail - not critical
    }
  }

  Future<void> _loadCategories() async {
    try {
      final response = await CategoryService.list();
      if (response.statusCode == 200) {
        final data = response.data;
        final categoriesData = data['data'] as List<dynamic>;
        setState(() {
          _categories = categoriesData.map((json) => Category.fromJson(json)).toList();
        });
      }
    } catch (e) {
      // Silently fail - not critical
    }
  }

  Future<void> _loadTransactions({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final response = await TransactionService.list(
        type: _filterType,
        accountId: _filterAccountId,
        categoryId: _filterCategoryId,
        from: _filterFrom?.toIso8601String().split('T')[0],
        to: _filterTo?.toIso8601String().split('T')[0],
        page: _currentPage,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final transactionsData = data['data'] as List<dynamic>;
        final meta = data['meta'] ?? {};

        setState(() {
          if (_currentPage == 1) {
            _transactions = transactionsData
                .map((json) => Transaction.fromJson(json))
                .toList();
          } else {
            _transactions.addAll(
              transactionsData.map((json) => Transaction.fromJson(json)).toList(),
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

  void _showCreateDialog() {
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    final typeController = TextEditingController(text: 'expense');
    DateTime? selectedDate = DateTime.now();
    int? selectedAccountId;
    int? selectedCategoryId;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nova Transação'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: typeController.text,
                    decoration: const InputDecoration(
                      labelText: 'Tipo *',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'expense', child: Text('Despesa')),
                      DropdownMenuItem(value: 'income', child: Text('Receita')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        typeController.text = value;
                        setDialogState(() {});
                      }
                    },
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Tipo é obrigatório' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: selectedAccountId,
                    decoration: const InputDecoration(
                      labelText: 'Conta *',
                      border: OutlineInputBorder(),
                    ),
                    items: _accounts.map((account) {
                      return DropdownMenuItem(
                        value: account.id,
                        child: Text(account.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      selectedAccountId = value;
                      setDialogState(() {});
                    },
                    validator: (value) =>
                        value == null ? 'Conta é obrigatória' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Categoria',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text('Sem categoria'),
                      ),
                      ..._categories.map((category) {
                        return DropdownMenuItem(
                          value: category.id,
                          child: Text(category.name),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      selectedCategoryId = value;
                      setDialogState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Descrição *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Descrição é obrigatória' : null,
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: 'Valor *',
                      border: OutlineInputBorder(),
                      prefixText: 'R\$ ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Valor é obrigatório';
                      if (double.tryParse(value!.replaceAll(',', '.')) == null ||
                          double.parse(value.replaceAll(',', '.')) <= 0) {
                        return 'Valor inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        selectedDate = date;
                        setDialogState(() {});
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Data da Transação *',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        selectedDate != null
                            ? DateFormat('dd/MM/yyyy').format(selectedDate!)
                            : 'Selecione uma data',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Dispose controllers após fechar o diálogo
                Future.microtask(() {
                  descriptionController.dispose();
                  amountController.dispose();
                  typeController.dispose();
                });
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                if (formKey.currentState!.validate() &&
                    selectedAccountId != null &&
                    selectedDate != null) {
                  // Salvar valores antes de fechar
                  final accountId = selectedAccountId!;
                  final categoryId = selectedCategoryId;
                  final type = typeController.text;
                  final amount = double.parse(amountController.text.replaceAll(',', '.'));
                  final occurredAt = selectedDate!;
                  final description = descriptionController.text;
                  
                  // Fechar diálogo primeiro
                  Navigator.of(context).pop();
                  // Dispose controllers após fechar
                  Future.microtask(() {
                    descriptionController.dispose();
                    amountController.dispose();
                    typeController.dispose();
                  });
                  // Criar transação com valores salvos
                  await _createTransaction(
                    accountId: accountId,
                    categoryId: categoryId,
                    type: type,
                    amount: amount,
                    occurredAt: occurredAt,
                    description: description,
                  );
                }
              },
              child: const Text('Criar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createTransaction({
    required int accountId,
    int? categoryId,
    required String type,
    required double amount,
    required DateTime occurredAt,
    required String description,
  }) async {
    try {
      await TransactionService.create(
        accountId: accountId,
        categoryId: categoryId,
        type: type,
        amount: amount,
        occurredAt: occurredAt,
        description: description,
      );
      if (mounted) {
        ToastService.showSuccess(context, 'Transação criada com sucesso!');
        setState(() {
          _currentPage = 1;
        });
        _loadTransactions();
      }
    } on DioException catch (e) {
      if (mounted) {
        ToastService.showError(
          context,
          e.response?.data['message'] ?? 'Erro ao criar transação',
        );
      }
    } catch (e) {
      if (mounted) {
        ToastService.showError(context, 'Erro ao criar transação: ${e.toString()}');
      }
    }
  }

  void _showEditDialog(Transaction transaction) {
    final descriptionController = TextEditingController(text: transaction.description);
    final amountController = TextEditingController(text: transaction.amount.toString());
    final typeController = TextEditingController(text: transaction.type);
    DateTime? selectedDate = transaction.occurredAt;
    int? selectedAccountId = transaction.accountId;
    int? selectedCategoryId = transaction.categoryId;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Editar Transação'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: typeController.text,
                    decoration: const InputDecoration(
                      labelText: 'Tipo *',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'expense', child: Text('Despesa')),
                      DropdownMenuItem(value: 'income', child: Text('Receita')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        typeController.text = value;
                        setDialogState(() {});
                      }
                    },
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Tipo é obrigatório' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: selectedAccountId,
                    decoration: const InputDecoration(
                      labelText: 'Conta *',
                      border: OutlineInputBorder(),
                    ),
                    items: _accounts.map((account) {
                      return DropdownMenuItem(
                        value: account.id,
                        child: Text(account.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      selectedAccountId = value;
                      setDialogState(() {});
                    },
                    validator: (value) =>
                        value == null ? 'Conta é obrigatória' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Categoria',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text('Sem categoria'),
                      ),
                      ..._categories.map((category) {
                        return DropdownMenuItem(
                          value: category.id,
                          child: Text(category.name),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      selectedCategoryId = value;
                      setDialogState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Descrição *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Descrição é obrigatória' : null,
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: 'Valor *',
                      border: OutlineInputBorder(),
                      prefixText: 'R\$ ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Valor é obrigatório';
                      if (double.tryParse(value!.replaceAll(',', '.')) == null ||
                          double.parse(value.replaceAll(',', '.')) <= 0) {
                        return 'Valor inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        selectedDate = date;
                        setDialogState(() {});
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Data da Transação *',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        selectedDate != null
                            ? DateFormat('dd/MM/yyyy').format(selectedDate!)
                            : 'Selecione uma data',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Dispose controllers após fechar o diálogo
                Future.microtask(() {
                  descriptionController.dispose();
                  amountController.dispose();
                  typeController.dispose();
                });
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                if (formKey.currentState!.validate() &&
                    selectedAccountId != null &&
                    selectedDate != null) {
                  // Salvar valores antes de fechar
                  final accountId = selectedAccountId!;
                  final categoryId = selectedCategoryId;
                  final type = typeController.text;
                  final amount = double.parse(amountController.text.replaceAll(',', '.'));
                  final occurredAt = selectedDate!;
                  final description = descriptionController.text;
                  
                  // Fechar diálogo primeiro
                  Navigator.of(context).pop();
                  // Dispose controllers após fechar
                  Future.microtask(() {
                    descriptionController.dispose();
                    amountController.dispose();
                    typeController.dispose();
                  });
                  // Atualizar transação com valores salvos
                  await _updateTransaction(
                    transaction.id,
                    accountId: accountId,
                    categoryId: categoryId,
                    type: type,
                    amount: amount,
                    occurredAt: occurredAt,
                    description: description,
                  );
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateTransaction(
    int id, {
    required int accountId,
    int? categoryId,
    required String type,
    required double amount,
    required DateTime occurredAt,
    required String description,
  }) async {
    try {
      await TransactionService.update(
        id,
        accountId: accountId,
        categoryId: categoryId,
        type: type,
        amount: amount,
        occurredAt: occurredAt,
        description: description,
      );
      if (mounted) {
        ToastService.showSuccess(context, 'Transação atualizada com sucesso!');
        _loadTransactions();
      }
    } on DioException catch (e) {
      if (mounted) {
        ToastService.showError(
          context,
          e.response?.data['message'] ?? 'Erro ao atualizar transação',
        );
      }
    } catch (e) {
      if (mounted) {
        ToastService.showError(context, 'Erro ao atualizar transação');
      }
    }
  }

  Future<void> _deleteTransaction(Transaction transaction) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Confirmar Exclusão',
      message: 'Deseja realmente excluir a transação "${transaction.description}"?',
      confirmLabel: 'Excluir',
      cancelLabel: 'Cancelar',
      icon: Icons.delete,
      isDestructive: true,
    );

    if (confirmed) {
      try {
        await TransactionService.delete(transaction.id);
        if (mounted) {
          ToastService.showSuccess(context, 'Transação excluída com sucesso!');
          setState(() {
            _currentPage = 1;
          });
          _loadTransactions();
        }
      } catch (e) {
        if (mounted) {
          ToastService.showError(context, 'Erro ao excluir transação');
        }
      }
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filtrar Transações'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _filterType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Todos')),
                    DropdownMenuItem(value: 'income', child: Text('Receitas')),
                    DropdownMenuItem(value: 'expense', child: Text('Despesas')),
                  ],
                  onChanged: (value) {
                    setState(() => _filterType = value);
                    setDialogState(() {});
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _filterAccountId,
                  decoration: const InputDecoration(
                    labelText: 'Conta',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('Todas'),
                    ),
                    ..._accounts.map((account) {
                      return DropdownMenuItem(
                        value: account.id,
                        child: Text(account.name),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() => _filterAccountId = value);
                    setDialogState(() {});
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _filterCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('Todas'),
                    ),
                    ..._categories.map((category) {
                      return DropdownMenuItem(
                        value: category.id,
                        child: Text(category.name),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() => _filterCategoryId = value);
                    setDialogState(() {});
                  },
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _filterFrom ?? DateTime.now().subtract(const Duration(days: 30)),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _filterFrom = date);
                      setDialogState(() {});
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Data Inicial',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _filterFrom != null
                          ? DateFormat('dd/MM/yyyy').format(_filterFrom!)
                          : 'Não definida',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _filterTo ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _filterTo = date);
                      setDialogState(() {});
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Data Final',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _filterTo != null
                          ? DateFormat('dd/MM/yyyy').format(_filterTo!)
                          : 'Não definida',
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _filterType = null;
                  _filterAccountId = null;
                  _filterCategoryId = null;
                  _filterFrom = null;
                  _filterTo = null;
                });
                Navigator.of(context).pop();
                setState(() {
                  _currentPage = 1;
                });
                _loadTransactions();
              },
              child: const Text('Limpar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _currentPage = 1;
                });
                _loadTransactions();
              },
              child: const Text('Aplicar'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double value) {
    return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(value);
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final canCreate = PermissionHelper.hasPermission(authState, Permission.transactionsCreate);
    final canEdit = PermissionHelper.hasPermission(authState, Permission.transactionsEdit);
    final canDelete = PermissionHelper.hasPermission(authState, Permission.transactionsDelete);

    final hasFilters = _filterType != null ||
        _filterAccountId != null ||
        _filterCategoryId != null ||
        _filterFrom != null ||
        _filterTo != null;

    return Column(
      children: [
        PageHeader(
          title: 'Transações',
          subtitle: 'Visualize e gerencie todas as suas transações financeiras',
          breadcrumbs: const ['Financeiro', 'Transações'],
          actions: [
            if (hasFilters)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _filterType = null;
                    _filterAccountId = null;
                    _filterCategoryId = null;
                    _filterFrom = null;
                    _filterTo = null;
                    _currentPage = 1;
                  });
                  _loadTransactions();
                },
                tooltip: 'Limpar filtros',
              ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
              tooltip: 'Filtrar',
            ),
          ],
        ),
        ActionBar(
          actions: [
            if (canCreate)
              ActionItem(
                label: 'Nova Transação',
                icon: Icons.add,
                onPressed: _showCreateDialog,
                type: ActionType.primary,
              ),
          ],
        ),
        Expanded(
          child: _isLoading
              ? const LoadingState(message: 'Carregando transações...')
              : _error != null
                  ? ErrorState(
                      message: _error!,
                      onRetry: _loadTransactions,
                    )
                  : _transactions.isEmpty
                      ? EmptyState(
                          icon: Icons.swap_horiz,
                          title: 'Nenhuma transação encontrada',
                          message: 'Registre sua primeira transação para começar a acompanhar suas finanças.',
                          actionLabel: 'Nova Transação',
                          onAction: canCreate ? _showCreateDialog : null,
                        )
                      : RefreshIndicator(
                          onRefresh: () {
                            setState(() {
                              _currentPage = 1;
                            });
                            return _loadTransactions();
                          },
                          child: ListView.builder(
                            itemCount: _transactions.length + (_hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _transactions.length) {
                                return Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Center(
                                    child: TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _currentPage++;
                                        });
                                        _loadTransactions(showLoading: false);
                                      },
                                      child: const Text('Carregar mais'),
                                    ),
                                  ),
                                );
                              }

                              final transaction = _transactions[index];
                              return ListItemCard(
                                title: transaction.description,
                                subtitle:
                                    '${transaction.accountName ?? "Sem conta"} • ${transaction.categoryName ?? "Sem categoria"} • ${_formatDate(transaction.occurredAt)}',
                                trailing: Text(
                                  _formatCurrency(transaction.amount),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: transaction.type == 'income'
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                                leadingIcon: transaction.type == 'income'
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                leadingColor: transaction.type == 'income'
                                    ? Colors.green
                                    : Colors.red,
                                onTap: null,
                                actions: [
                                  if (canEdit)
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 20),
                                      onPressed: () => _showEditDialog(transaction),
                                      tooltip: 'Editar',
                                    ),
                                  if (canEdit)
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 20),
                                      onPressed: () => _deleteTransaction(transaction),
                                      tooltip: 'Excluir',
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
        ),
      ],
    );
  }
}
