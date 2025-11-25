import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../../core/providers/currency_provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/accessibility/responsive_utils.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_typography.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_borders.dart';
import '../../../../core/accessibility/accessible_widgets.dart';
import '../../data/services/transaction_service.dart';
import '../../data/models/transaction.dart';
import '../../../accounts/data/services/account_service.dart';
import '../../../accounts/data/models/account.dart';
import '../../../categories/data/services/category_service.dart';
import '../../../categories/data/models/category.dart';
import '../../../documents/data/services/document_service.dart';
import 'package:file_picker/file_picker.dart';
import '../widgets/transaction_document_upload.dart';
import 'transaction_form_page.dart';

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
  String? _searchQuery;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _keyboardFocusNode = FocusNode();
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // Debounce search
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchController.text != _searchQuery) {
        setState(() {
          _searchQuery = _searchController.text.isEmpty ? null : _searchController.text;
          _currentPage = 1;
        });
        _loadTransactions();
      }
    });
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
        search: _searchQuery,
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        insetPadding: ResponsiveUtils.isMobile(context)
            ? const EdgeInsets.all(16)
            : const EdgeInsets.symmetric(horizontal: 100, vertical: 50),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: ResponsiveUtils.isMobile(context) ? double.infinity : 600,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: TransactionFormPage(
            transaction: null,
            transactionId: null,
          ),
        ),
      ),
    ).then((result) {
      if (result == true && mounted) {
        setState(() {
          _currentPage = 1;
        });
        _loadTransactions();
      }
    });
  }

  Future<void> _createTransaction({
    required int accountId,
    int? categoryId,
    required String type,
    required double amount,
    required DateTime occurredAt,
    required String description,
    PlatformFile? file,
  }) async {
    try {
      String? documentPath;
      int? documentId;

      // Fazer upload do documento apenas se houver arquivo selecionado
      if (file != null) {
        final uploadResponse = await DocumentService.upload(
          file: file,
          name: file.name,
          description: 'Documento da transação: $description',
          category: 'transaction',
          documentableType: 'transaction',
        );

        if (uploadResponse.statusCode != 201) {
          throw Exception('Erro ao fazer upload do documento');
        }

        final documentData = uploadResponse.data['data'] as Map<String, dynamic>;
        documentPath = documentData['path'] as String?;
        documentId = documentData['id'] as int;
      }

      // Criar transação com o path do documento (se houver)
      final transactionResponse = await TransactionService.create(
        accountId: accountId,
        categoryId: categoryId,
        type: type,
        amount: amount,
        occurredAt: occurredAt,
        description: description,
        attachmentPath: documentPath,
      );

      // Associar documento à transação após criação (se houver documento)
      if (file != null && documentId != null && transactionResponse.statusCode == 201) {
        final transactionData = transactionResponse.data['data'] as Map<String, dynamic>;
        final transactionId = transactionData['id'] as int;

        // Atualizar documento para associar à transação
        await DocumentService.update(
          documentId,
          description: 'Documento da transação #$transactionId: $description',
        );
      }

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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        insetPadding: ResponsiveUtils.isMobile(context)
            ? const EdgeInsets.all(16)
            : const EdgeInsets.symmetric(horizontal: 100, vertical: 50),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: ResponsiveUtils.isMobile(context) ? double.infinity : 600,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: TransactionFormPage(
            transaction: transaction,
            transactionId: null,
          ),
        ),
      ),
    ).then((result) {
      if (result == true && mounted) {
        setState(() {
          _currentPage = 1;
        });
        _loadTransactions();
      }
    });
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

  String _formatCurrency(double value, CurrencyState currencyState) {
    return CurrencyFormatter.format(value, currencyState);
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Hoje';
    } else if (dateOnly == yesterday) {
      return 'Ontem';
    } else {
      return DateFormat('EEEE, dd/MM/yyyy', 'pt_BR').format(date);
    }
  }

  /// Agrupa transações por data
  Map<String, List<Transaction>> _groupTransactionsByDate(List<Transaction> transactions) {
    final grouped = <String, List<Transaction>>{};
    for (final transaction in transactions) {
      final dateKey = DateFormat('yyyy-MM-dd').format(transaction.occurredAt);
      grouped.putIfAbsent(dateKey, () => []).add(transaction);
    }
    // Ordenar por data (mais recente primeiro)
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    final sorted = <String, List<Transaction>>{};
    for (final key in sortedKeys) {
      sorted[key] = grouped[key]!;
    }
    return sorted;
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
        _filterTo != null ||
        (_searchQuery?.isNotEmpty ?? false);
    final isMobile = ResponsiveUtils.isMobile(context);

    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          // Ctrl+N ou Cmd+N - Nova transação
          if ((event.logicalKey == LogicalKeyboardKey.keyN) &&
              (HardwareKeyboard.instance.isControlPressed ||
                  HardwareKeyboard.instance.isMetaPressed)) {
            if (canCreate) {
              _showCreateDialog();
            }
          }
          // Ctrl+F ou Cmd+F - Abrir filtros
          else if ((event.logicalKey == LogicalKeyboardKey.keyF) &&
              (HardwareKeyboard.instance.isControlPressed ||
                  HardwareKeyboard.instance.isMetaPressed)) {
            _showFilterDialog();
          }
        }
      },
      child: Focus(
        autofocus: true,
        child: Column(
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
                color: AppColors.textSecondary,
              ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
              tooltip: 'Filtrar',
              color: AppColors.textSecondary,
            ),
          ],
        ),
        // Barra de busca
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding(context).horizontal,
            vertical: AppSpacing.sm,
          ),
          child: SizedBox(
            width: double.infinity,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar transações...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = null;
                            _currentPage = 1;
                          });
                          _loadTransactions();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorders.inputRadius),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorders.inputRadius),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorders.inputRadius),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: AppColors.surface,
              ),
            ),
          ),
        ),
        ActionBar(
          actions: [
            if (canCreate)
              ActionItem(
                label: 'Adicionar Transação',
                icon: Icons.add_circle,
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
                          message: hasFilters
                              ? 'Nenhuma transação corresponde aos filtros aplicados.'
                              : 'Registre sua primeira transação para começar a acompanhar suas finanças.',
                          actionLabel: 'Nova Transação',
                          onAction: canCreate ? _showCreateDialog : null,
                        )
                      : isMobile
                          ? RefreshIndicator(
                              onRefresh: () {
                                setState(() {
                                  _currentPage = 1;
                                });
                                return _loadTransactions();
                              },
                              child: _buildTransactionsList(canEdit, canDelete, isMobile),
                            )
                          : _buildTransactionsList(canEdit, canDelete, isMobile),
        ),
          ],
        ),
      ),
    );
  }

  /// Constrói lista de transações agrupadas por data
  Widget _buildTransactionsList(bool canEdit, bool canDelete, bool isMobile) {
    final grouped = _groupTransactionsByDate(_transactions);
    final dates = grouped.keys.toList();
    
    if (isMobile) {
      return ListView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.pagePadding(context).horizontal,
          vertical: AppSpacing.md,
        ),
        itemCount: dates.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == dates.length) {
            return Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _currentPage++;
                    });
                    _loadTransactions(showLoading: false);
                  },
                  icon: const Icon(Icons.expand_more),
                  label: Text(
                    'Carregar mais',
                    style: AppTypography.label,
                  ),
                ),
              ),
            );
          }
          
          final dateKey = dates[index];
          final date = DateTime.parse(dateKey);
          final transactions = grouped[dateKey]!;
          
          return ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: double.infinity,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header da data
                Padding(
                  padding: EdgeInsets.only(
                    top: index > 0 ? AppSpacing.lg : 0,
                    bottom: AppSpacing.sm,
                  ),
                  child: Text(
                    _formatDateHeader(date),
                    style: AppTypography.sectionTitle.copyWith(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                // Transações do dia
                ...transactions.map((transaction) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _buildTransactionCard(transaction, canEdit, canDelete),
                    )),
              ],
            ),
          );
        },
      );
    } else {
      // Desktop: lista agrupada também, mas com layout diferente
      return CustomScrollView(
        slivers: [
          ...dates.map((dateKey) {
            final date = DateTime.parse(dateKey);
            final transactions = grouped[dateKey]!;
            return SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePadding(context).horizontal,
                  vertical: AppSpacing.md,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: double.infinity,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header da data
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Text(
                          _formatDateHeader(date),
                          style: AppTypography.sectionTitle.copyWith(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      // Transações do dia
                      ...transactions.map((transaction) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: _buildTransactionCard(transaction, canEdit, canDelete),
                          )),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
          // Botão carregar mais
          if (_hasMore)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Center(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _currentPage++;
                      });
                      _loadTransactions(showLoading: false);
                    },
                    icon: const Icon(Icons.expand_more),
                    label: Text(
                      'Carregar mais',
                      style: AppTypography.label,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    }
  }

  /// Card de transação modernizado e compacto
  Widget _buildTransactionCard(Transaction transaction, bool canEdit, bool canDelete) {
    final isIncome = transaction.type == 'income';
    final currencyState = ref.watch(currencyProvider);
    
    return AccessibleCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppBorders.cardRadius),
          onTap: () => context.go('/app/transactions/${transaction.id}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Ícone circular
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (isIncome ? AppColors.income : AppColors.expense).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                    color: isIncome ? AppColors.income : AppColors.expense,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Conteúdo
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        transaction.description,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (transaction.categoryName != null) ...[
                            Text(
                              transaction.categoryName!,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '•',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (transaction.accountName != null)
                            Text(
                              transaction.accountName!,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Valor alinhado à direita
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatCurrency(transaction.amount, currencyState),
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isIncome ? AppColors.income : AppColors.expense,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(transaction.occurredAt),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                // Menu de ações
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: AppColors.textSecondary, size: 18),
                  tooltip: 'Ações',
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onSelected: (value) {
                    if (value == 'edit' && canEdit) {
                      _showEditDialog(transaction);
                    } else if (value == 'delete' && canDelete) {
                      _deleteTransaction(transaction);
                    }
                  },
                  itemBuilder: (context) => [
                    if (canEdit)
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Text('Editar', style: AppTypography.bodySmall),
                          ],
                        ),
                      ),
                    if (canDelete)
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: AppColors.error),
                            const SizedBox(width: 8),
                            Text(
                              'Excluir',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, Transaction transaction, bool canEdit, bool isMobile) {
    // Método antigo mantido para compatibilidade, mas não usado mais
    return _buildTransactionCard(transaction, canEdit, canEdit);
  }

  Widget _buildTransactionItemOld(BuildContext context, Transaction transaction, bool canEdit, bool isMobile) {
    if (isMobile) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListTile(
          onTap: () {
            context.go('/app/transactions/${transaction.id}');
          },
          leading: CircleAvatar(
            backgroundColor: transaction.type == 'income'
                ? Colors.green.shade100
                : Colors.red.shade100,
            child: Icon(
              transaction.type == 'income'
                  ? Icons.arrow_downward
                  : Icons.arrow_upward,
              color: transaction.type == 'income'
                  ? Colors.green.shade700
                  : Colors.red.shade700,
            ),
          ),
          title: Text(
            transaction.description,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: [
                  Chip(
                    label: Text(
                      transaction.type == 'income' ? 'Receita' : 'Despesa',
                      style: const TextStyle(fontSize: 11),
                    ),
                    backgroundColor: transaction.type == 'income'
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  if (transaction.accountName != null)
                    Text(
                      transaction.accountName!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  Text(
                    _formatDate(transaction.occurredAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Consumer(
                builder: (context, ref, child) {
                  final currencyState = ref.watch(currencyProvider);
                  return Text(
                    _formatCurrency(transaction.amount, currencyState),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: transaction.type == 'income'
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  );
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18),
                onSelected: (value) {
                  if (value == 'edit' && canEdit) {
                    _showEditDialog(transaction);
                  } else if (value == 'delete' && canEdit) {
                    _deleteTransaction(transaction);
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
                  if (canEdit)
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
              ),
            ],
          ),
        ),
      );
    } else {
      // Desktop: tabela
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: InkWell(
          onTap: () {
            context.go('/app/transactions/${transaction.id}');
          },
          borderRadius: BorderRadius.circular(8),
          child: Table(
          columnWidths: const {
            0: FlexColumnWidth(0.5),
            1: FlexColumnWidth(3),
            2: FlexColumnWidth(1.5),
            3: FlexColumnWidth(1.5),
            4: FlexColumnWidth(1.5),
            5: FlexColumnWidth(1),
          },
          children: [
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: transaction.type == 'income'
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                    child: Icon(
                      transaction.type == 'income'
                          ? Icons.arrow_downward
                          : Icons.arrow_upward,
                      size: 18,
                      color: transaction.type == 'income'
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.description,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        children: [
                          Chip(
                            label: Text(
                              transaction.type == 'income' ? 'Receita' : 'Despesa',
                              style: const TextStyle(fontSize: 10),
                            ),
                            backgroundColor: transaction.type == 'income'
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    transaction.accountName ?? 'Sem conta',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    transaction.categoryName ?? 'Sem categoria',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _formatDate(transaction.occurredAt),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Consumer(
                        builder: (context, ref, child) {
                          final currencyState = ref.watch(currencyProvider);
                          return Text(
                            _formatCurrency(transaction.amount, currencyState),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: transaction.type == 'income'
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                            textAlign: TextAlign.right,
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 18),
                        onSelected: (value) {
                          if (value == 'edit' && canEdit) {
                            _showEditDialog(transaction);
                          } else if (value == 'delete' && canEdit) {
                            _deleteTransaction(transaction);
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
                          if (canEdit)
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
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          ),
        ),
      );
    }
  }
}
