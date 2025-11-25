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
import '../../../../core/accessibility/responsive_utils.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_typography.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_borders.dart';
import '../../../../core/accessibility/accessible_widgets.dart';
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
  bool _balanceVisible = true;

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
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 500,
              maxHeight: 700,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header moderno
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.add_circle,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nova Conta',
                                  style: AppTypography.headlineSmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Preencha os dados da nova conta financeira.',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: isSubmitting
                                ? null
                                : () => Navigator.of(context).pop(false),
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                    // Conteúdo com scroll
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: nameController,
                              decoration: InputDecoration(
                                labelText: 'Nome da Conta *',
                                hintText: 'Ex: Conta Corrente, Poupança',
                                filled: true,
                                fillColor: AppColors.background,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppColors.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppColors.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                                ),
                                prefixIcon: Icon(Icons.account_balance_wallet, color: AppColors.primary),
                                helperText: 'Nome que identifica esta conta',
                                helperStyle: AppTypography.caption,
                              ),
                              style: AppTypography.bodyMedium,
                              validator: (value) => value?.isEmpty ?? true ? 'Nome é obrigatório' : null,
                              autofocus: true,
                              enabled: !isSubmitting,
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: currencyController,
                              decoration: InputDecoration(
                                labelText: 'Moeda *',
                                hintText: 'BRL',
                                filled: true,
                                fillColor: AppColors.background,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppColors.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppColors.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                                ),
                                prefixIcon: Icon(Icons.attach_money, color: AppColors.primary),
                                helperText: 'Código da moeda (3 letras)',
                                helperStyle: AppTypography.caption,
                                counterText: '3/3',
                              ),
                              style: AppTypography.bodyMedium,
                              maxLength: 3,
                              textCapitalization: TextCapitalization.characters,
                              validator: (value) {
                                if (value?.isEmpty ?? true) return 'Moeda é obrigatória';
                                if ((value?.length ?? 0) != 3) return 'Moeda deve ter exatamente 3 caracteres';
                                return null;
                              },
                              enabled: !isSubmitting,
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: balanceController,
                              decoration: InputDecoration(
                                labelText: 'Saldo Inicial (opcional)',
                                hintText: '0,00',
                                filled: true,
                                fillColor: AppColors.background,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppColors.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppColors.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                                ),
                                prefixIcon: Icon(Icons.account_balance, color: AppColors.primary),
                                helperText: 'Saldo inicial da conta',
                                helperStyle: AppTypography.caption,
                              ),
                              style: AppTypography.bodyMedium,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              enabled: !isSubmitting,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Botões fixos no rodapé
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.border, width: 1),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: isSubmitting
                                ? null
                                : () => Navigator.of(context).pop(false),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: Text(
                              'Cancelar',
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    if (formKey.currentState!.validate()) {
                                      setDialogState(() {
                                        isSubmitting = true;
                                      });
                                      
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
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    'Criar Conta',
                                    style: AppTypography.labelLarge.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
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

  /// Card de saldo total - compacto
  Widget _buildTotalBalanceCard(double total, String currency, bool visible) {
    final isPositive = total >= 0;
    return AccessibleCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_balance,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saldo Total',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('MMMM yyyy', 'pt_BR').format(DateTime.now()),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(
                    visible ? Icons.visibility : Icons.visibility_off,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _balanceVisible = !_balanceVisible;
                    });
                  },
                  tooltip: visible ? 'Ocultar saldo' : 'Mostrar saldo',
                ),
                Text(
                  visible ? _formatCurrency(total, currency) : '••••••',
                  style: AppTypography.headlineMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isPositive ? AppColors.income : AppColors.expense,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Lista de contas para mobile
  Widget _buildMobileAccountsList(bool canEdit) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final account = _accounts[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _buildAccountCard(account, canEdit),
          );
        },
        childCount: _accounts.length,
      ),
    );
  }

  /// Grid de contas para desktop (2 colunas)
  Widget _buildDesktopAccountsGrid(bool canEdit) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.2,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final account = _accounts[index];
          return _buildAccountCard(account, canEdit);
        },
        childCount: _accounts.length,
      ),
    );
  }

  /// Card individual de conta - compacto
  Widget _buildAccountCard(Account account, bool canEdit) {
    final isPositive = account.balance >= 0;
    return AccessibleCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppBorders.cardRadius),
          onTap: () => context.push('/app/accounts/${account.id}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Ícone circular
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (isPositive ? AppColors.income : AppColors.expense).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    color: isPositive ? AppColors.income : AppColors.expense,
                    size: 24,
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
                        account.name,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        account.currency,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
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
                      _formatCurrency(account.balance, account.currency),
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isPositive ? AppColors.income : AppColors.expense,
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
                    switch (value) {
                      case 'edit':
                        _editAccount(account);
                        break;
                      case 'view':
                        context.push('/app/accounts/${account.id}');
                        break;
                      case 'delete':
                        _deleteAccount(account);
                        break;
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
                    PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Text('Ver detalhes', style: AppTypography.bodySmall),
                        ],
                      ),
                    ),
                    if (canEdit) ...[
                      const PopupMenuDivider(),
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
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Card de adicionar conta (grande, roxo)
  Widget _buildAddAccountCard() {
    return AccessibleCard(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppBorders.cardRadius),
          onTap: _isCreating ? null : _showCreateDialog,
          child: Container(
            padding: EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.secondary.withOpacity(0.1),
                  AppColors.secondary.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(AppBorders.cardRadius),
              border: Border.all(
                color: AppColors.secondary.withOpacity(0.3),
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: _isCreating
                      ? const SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 32,
                        ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  _isCreating ? 'Criando conta...' : 'Adicionar Nova Conta',
                  style: AppTypography.sectionTitle.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Clique para criar uma nova conta financeira',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Calcular saldo total
  double _getTotalBalance() {
    return _accounts.fold<double>(0.0, (sum, account) => sum + account.balance);
  }

  // Obter moeda principal (primeira conta ou BRL)
  String _getMainCurrency() {
    if (_accounts.isEmpty) return 'BRL';
    return _accounts.first.currency;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final canEdit = authState.role == UserRole.owner || authState.role == UserRole.admin;
    final hasFilters = _filterType != null || (_searchQuery?.isNotEmpty ?? false);
    final isMobile = ResponsiveUtils.isMobile(context);
    final totalBalance = _getTotalBalance();
    final mainCurrency = _getMainCurrency();

    return Column(
      children: [
        PageHeader(
          title: 'Contas',
          subtitle: 'Gerencie suas contas bancárias e financeiras',
          actions: [
            if (hasFilters)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: _clearFilters,
                tooltip: 'Limpar filtros',
                color: AppColors.textSecondary,
              ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
              tooltip: 'Filtrar',
              color: AppColors.textSecondary,
            ),
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () {
                ToastService.showInfo(context, 'Exportação em breve');
              },
              tooltip: 'Exportar',
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
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar contas...',
              prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.textSecondary),
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
            ),
          ),
        ),
        // ActionBar
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
                  : RefreshIndicator(
                      onRefresh: () async {
                        setState(() {
                          _currentPage = 1;
                        });
                        await _loadAccounts();
                      },
                      child: CustomScrollView(
                        slivers: [
                          // Bloco de saldo total (se houver contas)
                          if (_accounts.isNotEmpty)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  left: AppSpacing.pagePadding(context).horizontal,
                                  right: AppSpacing.pagePadding(context).horizontal,
                                  top: AppSpacing.md,
                                  bottom: AppSpacing.md,
                                ),
                                child: _buildTotalBalanceCard(totalBalance, mainCurrency, _balanceVisible),
                              ),
                            ),
                          // Lista de contas ou empty state
                          if (_accounts.isEmpty)
                            SliverFillRemaining(
                              child: EmptyState(
                                icon: Icons.account_balance_wallet,
                                title: 'Nenhuma conta encontrada',
                                message: _searchQuery?.isNotEmpty ?? false
                                    ? 'Nenhuma conta corresponde à busca.'
                                    : 'Crie sua primeira conta para começar a gerenciar suas finanças.',
                                actionLabel: canEdit ? 'Criar Primeira Conta' : null,
                                onAction: canEdit ? _showCreateDialog : null,
                              ),
                            )
                          else
                            SliverPadding(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.pagePadding(context).horizontal,
                                vertical: AppSpacing.md,
                              ),
                              sliver: isMobile
                                  ? _buildMobileAccountsList(canEdit)
                                  : _buildDesktopAccountsGrid(canEdit),
                            ),
                          // Card de adicionar conta (se houver contas e permissão)
                          if (_accounts.isNotEmpty && canEdit)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppSpacing.pagePadding(context).horizontal,
                                  vertical: AppSpacing.md,
                                ),
                                child: _buildAddAccountCard(),
                              ),
                            ),
                          // Botão "Carregar mais"
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
                                      _loadAccounts(showLoading: false);
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
                      ),
                    ),
        ),
      ],
    );
  }
}
