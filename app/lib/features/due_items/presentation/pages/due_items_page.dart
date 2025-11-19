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

    return Column(
      children: [
        PageHeader(
          title: 'Vencimentos',
          subtitle: 'Controle pagamentos e recebimentos a vencer',
          breadcrumbs: const ['Financeiro', 'Vencimentos'],
          actions: [
            if (hasFilters)
              IconButton(
                icon: const Icon(Icons.filter_alt),
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
              ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list),
              tooltip: 'Filtros rápidos',
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
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Calendário mensal
                                _buildMonthlyCalendar(context, _dueItems),
                                const SizedBox(height: 16),
                                // Lista "Esta semana"
                                if (thisWeekItems.isNotEmpty) ...[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      'Esta semana',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...thisWeekItems.map((item) => _buildDueItemCard(
                                        item,
                                        canEdit,
                                        item.isOverdue || item.isOverdueStatus
                                            ? Colors.red
                                            : item.isPending
                                                ? Colors.orange
                                                : Colors.green,
                                      )),
                                  const SizedBox(height: 16),
                                ],
                              ],
                            ),
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

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                ),
                Text(
                  DateFormat('MMMM yyyy', 'pt_BR').format(_selectedMonth),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
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
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
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

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                            color: date.day == DateTime.now().day &&
                                    _selectedMonth.month == DateTime.now().month &&
                                    _selectedMonth.year == DateTime.now().year
                                ? Theme.of(context).colorScheme.primaryContainer
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$dayNumber',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: date.day == DateTime.now().day &&
                                          _selectedMonth.month == DateTime.now().month &&
                                          _selectedMonth.year == DateTime.now().year
                                      ? FontWeight.bold
                                      : FontWeight.normal,
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
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  if (hasPending)
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Colors.orange,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  if (hasPaid)
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Colors.green,
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

  Widget _buildDueItemCard(DueItem item, bool canEdit, Color sectionColor) {
    final daysUntilDue = item.dueDate.difference(DateTime.now()).inDays;
    final isPastDue = daysUntilDue < 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: sectionColor.withOpacity(0.2),
          child: Icon(
            item.isPay ? Icons.arrow_upward : Icons.arrow_downward,
            color: sectionColor,
          ),
        ),
        title: Text(
          item.title,
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
                    item.isPay ? 'A Pagar' : 'A Receber',
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: item.isPay ? Colors.red.shade50 : Colors.green.shade50,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                Text(
                  DateFormat('dd/MM/yyyy').format(item.dueDate),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (isPastDue)
                  Chip(
                    label: Text(
                      '${-daysUntilDue} dias atrasado',
                      style: const TextStyle(fontSize: 11, color: Colors.white),
                    ),
                    backgroundColor: Colors.red,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatCurrency(item.amount, 'BRL'),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: item.isPay ? Colors.red : Colors.green,
              ),
            ),
            if (canEdit && item.isPending)
              TextButton.icon(
                icon: const Icon(Icons.check_circle, size: 16),
                label: const Text('Pago'),
                onPressed: () => _markAsPaid(item),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
