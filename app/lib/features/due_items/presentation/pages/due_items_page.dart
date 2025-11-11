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
  String? _filterType;
  DateTime? _filterFrom;
  DateTime? _filterTo;
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
      final response = await DueItemService.list(
        status: _filterStatus,
        type: _filterType,
        from: _filterFrom?.toIso8601String().split('T')[0],
        to: _filterTo?.toIso8601String().split('T')[0],
        page: _currentPage,
        perPage: 50, // Mais itens para mostrar todas as seções
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

    final hasFilters = _filterStatus != null ||
        _filterType != null ||
        _filterFrom != null ||
        _filterTo != null;

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
                    _filterType = null;
                    _filterFrom = null;
                    _filterTo = null;
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
                label: 'Novo Vencimento',
                icon: Icons.add,
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
                          actionLabel: 'Novo Vencimento',
                          onAction: canEdit ? _showCreateDialog : null,
                        )
                      : RefreshIndicator(
                          onRefresh: () {
                            setState(() {
                              _currentPage = 1;
                            });
                            return _loadDueItems();
                          },
                          child: ListView.builder(
                            itemCount: (overdueItems.isNotEmpty ? 1 : 0) +
                                overdueItems.length +
                                (pendingItems.isNotEmpty ? 1 : 0) +
                                pendingItems.length +
                                (paidItems.isNotEmpty ? 1 : 0) +
                                paidItems.length +
                                (_hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              // Seção Overdue
                              if (overdueItems.isNotEmpty && index == 0) {
                                return Container(
                                  color: Colors.red.withOpacity(0.1),
                                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.warning,
                                        color: Colors.red[700],
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Atrasados (${overdueItems.length})',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              int adjustedIndex = index;
                              if (overdueItems.isNotEmpty) {
                                adjustedIndex--;
                                if (adjustedIndex < overdueItems.length) {
                                  final item = overdueItems[adjustedIndex];
                                  return _buildDueItemCard(item, canEdit, Colors.red);
                                }
                                adjustedIndex -= overdueItems.length;
                              }

                              // Seção Pending
                              if (pendingItems.isNotEmpty && adjustedIndex == 0) {
                                return Container(
                                  color: Colors.orange.withOpacity(0.1),
                                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.schedule,
                                        color: Colors.orange[700],
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Pendentes (${pendingItems.length})',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              if (pendingItems.isNotEmpty) {
                                adjustedIndex--;
                                if (adjustedIndex < pendingItems.length) {
                                  final item = pendingItems[adjustedIndex];
                                  return _buildDueItemCard(item, canEdit, Colors.orange);
                                }
                                adjustedIndex -= pendingItems.length;
                              }

                              // Seção Paid
                              if (paidItems.isNotEmpty && adjustedIndex == 0) {
                                return Container(
                                  color: Colors.green.withOpacity(0.1),
                                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.green[700],
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Pagas (${paidItems.length})',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              if (paidItems.isNotEmpty) {
                                adjustedIndex--;
                                if (adjustedIndex < paidItems.length) {
                                  final item = paidItems[adjustedIndex];
                                  return _buildDueItemCard(item, canEdit, Colors.green);
                                }
                                adjustedIndex -= paidItems.length;
                              }

                              // Load more
                              return Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Center(
                                  child: TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _currentPage++;
                                      });
                                      _loadDueItems(showLoading: false);
                                    },
                                    child: const Text('Carregar mais'),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _buildDueItemCard(DueItem item, bool canEdit, Color sectionColor) {
    final daysUntilDue = item.dueDate.difference(DateTime.now()).inDays;
    final isPastDue = daysUntilDue < 0;

    return ListItemCard(
      title: item.title,
      subtitle:
          '${item.isPay ? "A Pagar" : "A Receber"} • ${DateFormat('dd/MM/yyyy').format(item.dueDate)}${isPastDue ? " (${-daysUntilDue} dias atrasado)" : ""}',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatCurrency(item.amount, 'BRL'),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: item.isPay ? Colors.red : Colors.green,
            ),
          ),
          if (item.isOverdue || item.isOverdueStatus) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'ATRASADO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      leadingIcon: item.isPay ? Icons.arrow_upward : Icons.arrow_downward,
      leadingColor: item.isPay ? Colors.red : Colors.green,
      onTap: null,
      actions: [
        if (canEdit && item.isPending)
          IconButton(
            icon: const Icon(Icons.check_circle, size: 20),
            onPressed: () => _markAsPaid(item),
            tooltip: 'Marcar como pago',
            color: Colors.green,
          ),
        if (canEdit)
          IconButton(
            icon: const Icon(Icons.delete, size: 20),
            onPressed: () => _deleteDueItem(item),
            tooltip: 'Excluir',
          ),
      ],
    );
  }
}
