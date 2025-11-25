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
import '../../../../core/accessibility/responsive_utils.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_typography.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_borders.dart';
import '../../../../core/accessibility/accessible_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/due_item_service.dart';
import '../../data/models/due_item.dart';
import 'package:intl/date_symbol_data_local.dart';

class DueItemsPage extends ConsumerStatefulWidget {
  const DueItemsPage({super.key});

  @override
  ConsumerState<DueItemsPage> createState() => _DueItemsPageState();
}

class _DueItemsPageState extends ConsumerState<DueItemsPage> {
  List<DueItem> _dueItems = [];
  bool _isLoading = true;
  String? _error;
  String? _filterStatus;
  int? _filterAccountId;
  int? _filterCategoryId;
  DateTime _selectedMonth = DateTime.now();
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    _loadDueItems();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uri = GoRouterState.of(context).uri;
    if (uri.queryParameters['action'] == 'create' && !_isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showCreateDialog();
        }
      });
    }
  }

  Future<void> _loadDueItems({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      // Calcular início e fim do mês selecionado
      final monthStart = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      final monthEnd = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
      
      final response = await DueItemService.list(
        status: _filterStatus,
        accountId: _filterAccountId,
        categoryId: _filterCategoryId,
        from: monthStart.toIso8601String().split('T')[0],
        to: monthEnd.toIso8601String().split('T')[0],
        page: _currentPage,
        perPage: 100, // Mais itens para o calendário
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final itemsData = data['data'] as List<dynamic>;
        final meta = data['meta'] ?? {};

        setState(() {
          if (_currentPage == 1) {
            _dueItems = itemsData.map((json) => DueItem.fromJson(json)).toList();
          } else {
            _dueItems.addAll(
              itemsData.map((json) => DueItem.fromJson(json)).toList(),
            );
          }
          _totalPages = meta['last_page'] ?? 1;
          _hasMore = _currentPage < (_totalPages);
          _isLoading = false;
        });

        // Ordenar: overdue primeiro, depois pending, depois paid
        _dueItems.sort((a, b) {
          if (a.isOverdue && !b.isOverdue) return -1;
          if (!a.isOverdue && b.isOverdue) return 1;
          if (a.isPending && !b.isPending) return -1;
          if (!a.isPending && b.isPending) return 1;
          return a.dueDate.compareTo(b.dueDate);
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
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    final typeController = TextEditingController(text: 'pay');
    DateTime? selectedDate = DateTime.now();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Novo Vencimento'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Título *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Título é obrigatório' : null,
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
                  DropdownButtonFormField<String>(
                    value: typeController.text,
                    decoration: const InputDecoration(
                      labelText: 'Tipo *',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'pay', child: Text('A Pagar')),
                      DropdownMenuItem(value: 'receive', child: Text('A Receber')),
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
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        selectedDate = date;
                        setDialogState(() {});
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Data de Vencimento *',
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
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Descrição',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                titleController.dispose();
                amountController.dispose();
                descriptionController.dispose();
                typeController.dispose();
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                if (formKey.currentState!.validate() && selectedDate != null) {
                  await _createDueItem(
                    titleController.text,
                    double.parse(amountController.text.replaceAll(',', '.')),
                    selectedDate!,
                    typeController.text,
                    descriptionController.text.isNotEmpty
                        ? descriptionController.text
                        : null,
                  );
                  titleController.dispose();
                  amountController.dispose();
                  descriptionController.dispose();
                  typeController.dispose();
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                }
              },
              child: const Text('Criar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createDueItem(
    String title,
    double amount,
    DateTime dueDate,
    String type,
    String? description,
  ) async {
    try {
      await DueItemService.create(
        title: title,
        amount: amount,
        dueDate: dueDate,
        type: type,
        description: description,
      );
      if (mounted) {
        ToastService.showSuccess(context, 'Vencimento criado com sucesso!');
        setState(() {
          _currentPage = 1;
        });
        _loadDueItems();
      }
    } on DioException catch (e) {
      if (mounted) {
        ToastService.showError(
          context,
          e.response?.data['message'] ?? 'Erro ao criar vencimento',
        );
      }
    } catch (e) {
      if (mounted) {
        ToastService.showError(context, 'Erro ao criar vencimento: ${e.toString()}');
      }
    }
  }

  Future<void> _markAsPaid(DueItem item) async {
    try {
      await DueItemService.markPaid(item.id);
      if (mounted) {
        ToastService.showSuccess(context, 'Vencimento marcado como pago!');
        _loadDueItems();
      }
    } catch (e) {
      if (mounted) {
        ToastService.showError(context, 'Erro ao marcar como pago');
      }
    }
  }

  Future<void> _deleteDueItem(DueItem item) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Confirmar Exclusão',
      message: 'Deseja realmente excluir o vencimento "${item.title}"?',
      confirmLabel: 'Excluir',
      cancelLabel: 'Cancelar',
      icon: Icons.delete,
      isDestructive: true,
    );

    if (confirmed) {
      try {
        await DueItemService.delete(item.id);
        if (mounted) {
          ToastService.showSuccess(context, 'Vencimento excluído!');
          setState(() {
            _currentPage = 1;
          });
          _loadDueItems();
        }
      } catch (e) {
        if (mounted) {
          ToastService.showError(context, 'Erro ao excluir vencimento');
        }
      }
    }
  }

  String _formatCurrency(double amount, String currency) {
    return NumberFormat.currency(symbol: 'R\$ ', decimalDigits: 2).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final canEdit = authState.role == 'owner' || authState.role == 'admin';

    final overdueItems = _dueItems.where((item) => item.isOverdue || item.isOverdueStatus).toList();
    final pendingItems = _dueItems.where((item) => item.isPending && !item.isOverdue).toList();
    final paidItems = _dueItems.where((item) => item.isPaid).toList();

    // Calcular itens desta semana
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    final thisWeekItems = _dueItems.where((item) {
      return item.dueDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
          item.dueDate.isBefore(weekEnd.add(const Duration(days: 1)));
    }).toList();
    thisWeekItems.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    final hasFilters = _filterStatus != null || _filterAccountId != null || _filterCategoryId != null;

    // Calcular totais
    final totalToPay = overdueItems
        .where((item) => item.isPay)
        .fold<double>(0.0, (sum, item) => sum + item.amount);
    final totalToReceive = overdueItems
        .where((item) => item.isReceive)
        .fold<double>(0.0, (sum, item) => sum + item.amount);
    final totalOverdue = totalToPay + totalToReceive;

    return Column(
      children: [
        PageHeader(
          title: 'Vencimentos',
          subtitle: 'Controle pagamentos e recebimentos a vencer',
          actions: [
            if (hasFilters)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _filterStatus = null;
                    _filterAccountId = null;
                    _filterCategoryId = null;
                    _currentPage = 1;
                  });
                  _loadDueItems();
                },
                tooltip: 'Remover filtros',
                color: AppColors.textSecondary,
              ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list),
              tooltip: 'Filtros rápidos',
              color: AppColors.textSecondary,
              onSelected: (value) {
                setState(() {
                  if (value == 'overdue') {
                    _filterStatus = 'overdue';
                  } else if (value == 'pending') {
                    _filterStatus = 'pending';
                  } else if (value == 'paid') {
                    _filterStatus = 'paid';
                  } else {
                    _filterStatus = null;
                  }
                  _currentPage = 1;
                });
                _loadDueItems();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'all', child: Text('Todos')),
                const PopupMenuItem(value: 'overdue', child: Text('Atrasados')),
                const PopupMenuItem(value: 'pending', child: Text('Pendentes')),
                const PopupMenuItem(value: 'paid', child: Text('Pagas')),
              ],
            ),
          ],
        ),
        ActionBar(
          actions: [
            if (canEdit)
              ActionItem(
                label: 'Adicionar',
                icon: Icons.add_circle,
                onPressed: _showCreateDialog,
                type: ActionType.primary,
              ),
          ],
        ),
        Expanded(
          child: _isLoading
              ? const LoadingState(message: 'Carregando vencimentos...')
              : _error != null
                  ? ErrorState(
                      message: _error!,
                      onRetry: _loadDueItems,
                    )
                  : _dueItems.isEmpty
                      ? EmptyState(
                          icon: Icons.calendar_today,
                          title: 'Nenhum vencimento encontrado',
                          message: 'Cadastre pagamentos e recebimentos para acompanhar seus vencimentos.',
                          actionLabel: 'Adicionar',
                          onAction: canEdit ? _showCreateDialog : null,
                        )
                      : RefreshIndicator(
                          onRefresh: () {
                            setState(() {
                              _currentPage = 1;
                            });
                            return _loadDueItems();
                          },
                          child: CustomScrollView(
                            slivers: [
                              // Cards de resumo
                              if (_dueItems.isNotEmpty)
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: EdgeInsets.all(AppSpacing.pagePadding(context).horizontal),
                                    child: _buildSummaryCards(totalOverdue, totalToPay, totalToReceive),
                                  ),
                                ),
                              // Calendário mensal
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: AppSpacing.pagePadding(context).horizontal,
                                    vertical: AppSpacing.md,
                                  ),
                                  child: _buildMonthlyCalendar(context, _dueItems),
                                ),
                              ),
                              // Lista "Esta semana"
                              if (thisWeekItems.isNotEmpty)
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: AppSpacing.pagePadding(context).horizontal,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Esta semana',
                                          style: AppTypography.sectionTitle,
                                        ),
                                        const SizedBox(height: AppSpacing.sm),
                                      ],
                                    ),
                                  ),
                                ),
                              SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final item = thisWeekItems[index];
                                    return Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: AppSpacing.pagePadding(context).horizontal,
                                        vertical: AppSpacing.xs,
                                      ),
                                      child: _buildDueItemCard(item, canEdit),
                                    );
                                  },
                                  childCount: thisWeekItems.length,
                                ),
                              ),
                              // Lista completa (se não estiver mostrando apenas esta semana)
                              if (thisWeekItems.length < _dueItems.length)
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: AppSpacing.pagePadding(context).horizontal,
                                      vertical: AppSpacing.md,
                                    ),
                                    child: Text(
                                      'Todos os vencimentos',
                                      style: AppTypography.sectionTitle,
                                    ),
                                  ),
                                ),
                              SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final item = _dueItems[index];
                                    // Pular itens já mostrados em "Esta semana"
                                    if (thisWeekItems.contains(item)) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: AppSpacing.pagePadding(context).horizontal,
                                        vertical: AppSpacing.xs,
                                      ),
                                      child: _buildDueItemCard(item, canEdit),
                                    );
                                  },
                                  childCount: _dueItems.length,
                                ),
                              ),
                            ],
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _buildMonthlyCalendar(BuildContext context, List<DueItem> items) {
    final firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDay = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final firstWeekday = firstDay.weekday;
    final daysInMonth = lastDay.day;

    // Agrupar itens por data
    final itemsByDate = <DateTime, List<DueItem>>{};
    for (var item in items) {
      final date = DateTime(item.dueDate.year, item.dueDate.month, item.dueDate.day);
      itemsByDate.putIfAbsent(date, () => []).add(item);
    }

    return AccessibleCard(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            // Header do calendário
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
                      _currentPage = 1;
                    });
                    _loadDueItems();
                  },
                  color: AppColors.textSecondary,
                ),
                Text(
                  DateFormat('MMMM yyyy', 'pt_BR').format(_selectedMonth),
                  style: AppTypography.sectionTitle,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                      _currentPage = 1;
                    });
                    _loadDueItems();
                  },
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Dias da semana
            Row(
              children: ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb']
                  .map((day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            // Grid de dias
            ...List.generate(
              (firstWeekday + daysInMonth + 6) ~/ 7,
              (weekIndex) {
                return Row(
                  children: List.generate(7, (dayIndex) {
                    final dayNumber = weekIndex * 7 + dayIndex - firstWeekday + 1;
                    if (dayNumber < 1 || dayNumber > daysInMonth) {
                      return const Expanded(child: SizedBox());
                    }
                    final date = DateTime(_selectedMonth.year, _selectedMonth.month, dayNumber);
                    final dayItems = itemsByDate[date] ?? [];
                    final hasOverdue = dayItems.any((item) => item.isOverdue || item.isOverdueStatus);
                    final hasPending = dayItems.any((item) => item.isPending && !item.isOverdue);
                    final hasPaid = dayItems.any((item) => item.isPaid);

                    final isToday = date.day == DateTime.now().day &&
                        _selectedMonth.month == DateTime.now().month &&
                        _selectedMonth.year == DateTime.now().year;

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.border,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(AppBorders.smallRadius),
                            color: isToday
                                ? AppColors.primary.withOpacity(0.1)
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$dayNumber',
                                style: AppTypography.bodySmall.copyWith(
                                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                  color: isToday ? AppColors.primary : AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (hasOverdue)
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: AppColors.error,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  if (hasPending && !hasOverdue)
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: AppColors.warning,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  if (hasPaid && !hasOverdue && !hasPending)
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: AppColors.success,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Cards de resumo no topo
  Widget _buildSummaryCards(double totalOverdue, double totalToPay, double totalToReceive) {
    final isMobile = ResponsiveUtils.isMobile(context);
    
    if (isMobile) {
      return Column(
        children: [
          _buildSummaryCard(
            'Total Vencido',
            totalOverdue,
            AppColors.error,
            Icons.warning,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildSummaryCard(
            'A Pagar',
            totalToPay,
            AppColors.expense,
            Icons.arrow_upward,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildSummaryCard(
            'A Receber',
            totalToReceive,
            AppColors.income,
            Icons.arrow_downward,
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Total Vencido',
              totalOverdue,
              AppColors.error,
              Icons.warning,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _buildSummaryCard(
              'A Pagar',
              totalToPay,
              AppColors.expense,
              Icons.arrow_upward,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _buildSummaryCard(
              'A Receber',
              totalToReceive,
              AppColors.income,
              Icons.arrow_downward,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildSummaryCard(String label, double value, Color color, IconData icon) {
    return AccessibleCard(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppBorders.smallRadius),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs / 2),
                  Text(
                    _formatCurrency(value, 'BRL'),
                    style: AppTypography.kpiValue.copyWith(
                      fontSize: 20,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDueItemCard(DueItem item, bool canEdit) {
    final daysUntilDue = item.dueDate.difference(DateTime.now()).inDays;
    final isPastDue = daysUntilDue < 0;
    final isOverdue = item.isOverdue || item.isOverdueStatus;
    final isPending = item.isPending && !isOverdue;
    final isPaid = item.isPaid;

    Color statusColor;
    if (isOverdue) {
      statusColor = AppColors.error;
    } else if (isPending) {
      statusColor = AppColors.warning;
    } else {
      statusColor = AppColors.success;
    }

    return AccessibleCard(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppBorders.cardRadius),
          onTap: () {
            // TODO: Navegar para detalhes do vencimento
          },
          child: Container(
            decoration: isOverdue
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(AppBorders.cardRadius),
                    border: Border.all(
                      color: AppColors.error.withOpacity(0.3),
                      width: 2,
                    ),
                    color: AppColors.error.withOpacity(0.05),
                  )
                : null,
            padding: EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // Ícone
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppBorders.smallRadius),
                  ),
                  child: Icon(
                    item.isPay ? Icons.arrow_upward : Icons.arrow_downward,
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Conteúdo
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: AppTypography.cardTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs / 2),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs / 2,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: (item.isPay ? AppColors.expense : AppColors.income)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppBorders.smallRadius),
                            ),
                            child: Text(
                              item.isPay ? 'A Pagar' : 'A Receber',
                              style: AppTypography.caption.copyWith(
                                color: item.isPay ? AppColors.expense : AppColors.income,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            DateFormat('dd/MM/yyyy').format(item.dueDate),
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (isPastDue)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(AppBorders.smallRadius),
                              ),
                              child: Text(
                                '${-daysUntilDue} dias atrasado',
                                style: AppTypography.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Valor e ações
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatCurrency(item.amount, 'BRL'),
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: item.isPay ? AppColors.expense : AppColors.income,
                      ),
                    ),
                    if (canEdit && item.isPending) ...[
                      const SizedBox(height: AppSpacing.xs),
                      TextButton.icon(
                        icon: const Icon(Icons.check_circle, size: 16),
                        label: Text(
                          'Pago',
                          style: AppTypography.labelSmall,
                        ),
                        onPressed: () => _markAsPaid(item),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
}
