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
import '../../../../core/accessibility/responsive_utils.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_typography.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_borders.dart';
import '../../../../core/accessibility/accessible_widgets.dart';
import '../../data/services/service_request_service.dart';
import '../../data/models/service_request.dart';

class RequestsPage extends ConsumerStatefulWidget {
  const RequestsPage({super.key});

  @override
  ConsumerState<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends ConsumerState<RequestsPage> {
  List<ServiceRequest> _tickets = [];
  bool _isLoading = true;
  String? _error;
  String? _filterStatus;
  String? _filterPriority;
  String? _filterCategory;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final response = await ServiceRequestService.list(
        status: _filterStatus,
        priority: _filterPriority,
        category: _filterCategory,
        page: _currentPage,
        perPage: 15,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final ticketsData = data['data'] as List<dynamic>;
        final meta = data['meta'] ?? {};

        setState(() {
          if (_currentPage == 1) {
            _tickets = ticketsData
                .map((json) => ServiceRequest.fromJson(json))
                .toList();
          } else {
            _tickets.addAll(
              ticketsData.map((json) => ServiceRequest.fromJson(json)).toList(),
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
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final priorityController = TextEditingController(text: 'medium');
    final categoryController = TextEditingController(text: 'other');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Novo Ticket'),
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
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Descrição *',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 5,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Descrição é obrigatória' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: priorityController.text,
                    decoration: const InputDecoration(
                      labelText: 'Prioridade',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('Baixa')),
                      DropdownMenuItem(value: 'medium', child: Text('Média')),
                      DropdownMenuItem(value: 'high', child: Text('Alta')),
                      DropdownMenuItem(value: 'urgent', child: Text('Urgente')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        priorityController.text = value;
                        setDialogState(() {});
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: categoryController.text,
                    decoration: const InputDecoration(
                      labelText: 'Categoria',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'other', child: Text('Outro')),
                      DropdownMenuItem(value: 'finance', child: Text('Financeiro')),
                      DropdownMenuItem(value: 'technical', child: Text('Técnico')),
                      DropdownMenuItem(value: 'billing', child: Text('Cobrança')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        categoryController.text = value;
                        setDialogState(() {});
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                titleController.dispose();
                descriptionController.dispose();
                priorityController.dispose();
                categoryController.dispose();
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  await _createTicket(
                    titleController.text,
                    descriptionController.text,
                    priorityController.text,
                    categoryController.text,
                  );
                  titleController.dispose();
                  descriptionController.dispose();
                  priorityController.dispose();
                  categoryController.dispose();
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

  Future<void> _createTicket(
    String title,
    String description,
    String priority,
    String category,
  ) async {
    try {
      await ServiceRequestService.create(
        title: title,
        description: description,
        priority: priority,
        category: category,
      );
      if (mounted) {
        ToastService.showSuccess(context, 'Ticket criado com sucesso!');
        setState(() {
          _currentPage = 1;
        });
        _loadTickets();
      }
    } on DioException catch (e) {
      if (mounted) {
        ToastService.showError(
          context,
          e.response?.data['message'] ?? 'Erro ao criar ticket',
        );
      }
    } catch (e) {
      if (mounted) {
        ToastService.showError(context, 'Erro ao criar ticket: ${e.toString()}');
      }
    }
  }

  Future<void> _deleteTicket(ServiceRequest ticket) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Confirmar Exclusão',
      message: 'Deseja realmente excluir o ticket "${ticket.title}"?',
      confirmLabel: 'Excluir',
      cancelLabel: 'Cancelar',
      icon: Icons.delete,
      isDestructive: true,
    );

    if (confirmed) {
      try {
        await ServiceRequestService.delete(ticket.id);
        if (mounted) {
          ToastService.showSuccess(context, 'Ticket excluído!');
          setState(() {
            _currentPage = 1;
          });
          _loadTickets();
        }
      } catch (e) {
        if (mounted) {
          ToastService.showError(context, 'Erro ao excluir ticket');
        }
      }
    }
  }

  void _navigateToDetail(int ticketId) {
    context.push('/app/requests/$ticketId');
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filtrar Tickets'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _filterStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Todos')),
                    DropdownMenuItem(value: 'open', child: Text('Aberto')),
                    DropdownMenuItem(value: 'in_progress', child: Text('Em Progresso')),
                    DropdownMenuItem(value: 'resolved', child: Text('Resolvido')),
                    DropdownMenuItem(value: 'closed', child: Text('Fechado')),
                  ],
                  onChanged: (value) {
                    setState(() => _filterStatus = value);
                    setDialogState(() {});
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _filterPriority,
                  decoration: const InputDecoration(
                    labelText: 'Prioridade',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Todas')),
                    DropdownMenuItem(value: 'low', child: Text('Baixa')),
                    DropdownMenuItem(value: 'medium', child: Text('Média')),
                    DropdownMenuItem(value: 'high', child: Text('Alta')),
                    DropdownMenuItem(value: 'urgent', child: Text('Urgente')),
                  ],
                  onChanged: (value) {
                    setState(() => _filterPriority = value);
                    setDialogState(() {});
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _filterCategory,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Todas')),
                    DropdownMenuItem(value: 'finance', child: Text('Financeiro')),
                    DropdownMenuItem(value: 'technical', child: Text('Técnico')),
                    DropdownMenuItem(value: 'billing', child: Text('Cobrança')),
                    DropdownMenuItem(value: 'other', child: Text('Outro')),
                  ],
                  onChanged: (value) {
                    setState(() => _filterCategory = value);
                    setDialogState(() {});
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _filterStatus = null;
                  _filterPriority = null;
                  _filterCategory = null;
                });
                Navigator.of(context).pop();
                setState(() {
                  _currentPage = 1;
                });
                _loadTickets();
              },
              child: const Text('Limpar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _currentPage = 1;
                });
                _loadTickets();
              },
              child: const Text('Aplicar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _moveToStage(ServiceRequest ticket, String newStatus) async {
    try {
      await ServiceRequestService.update(ticket.id, status: newStatus);
      if (mounted) {
        ToastService.showSuccess(context, 'Solicitação movida para ${_getStatusLabel(newStatus)}');
        _loadTickets();
      }
    } catch (e) {
      if (mounted) {
        ToastService.showError(context, 'Erro ao mover solicitação');
      }
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'open':
        return 'Aberto';
      case 'in_progress':
        return 'Em Progresso';
      case 'resolved':
        return 'Resolvido';
      case 'closed':
        return 'Fechado';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final canEdit = authState.role == 'owner' || authState.role == 'admin';
    final isMobile = ResponsiveUtils.isMobile(context);

    final hasFilters =
        _filterStatus != null || _filterPriority != null || _filterCategory != null;

    // Agrupar tickets por status
    final openTickets = _tickets.where((t) => t.isOpen).toList();
    final inProgressTickets = _tickets.where((t) => t.isInProgress).toList();
    final resolvedTickets = _tickets.where((t) => t.isResolved).toList();
    final closedTickets = _tickets.where((t) => t.isClosed).toList();

    return Column(
      children: [
        PageHeader(
          title: 'Solicitações',
          subtitle: 'Gerencie solicitações e acompanhe seus tickets',
          actions: [
            if (hasFilters)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _filterStatus = null;
                    _filterPriority = null;
                    _filterCategory = null;
                    _currentPage = 1;
                  });
                  _loadTickets();
                },
                tooltip: 'Remover filtros',
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
        ActionBar(
          actions: [
            ActionItem(
              label: 'Nova Solicitação',
              icon: Icons.add_circle,
              onPressed: _showCreateDialog,
              type: ActionType.primary,
            ),
          ],
        ),
        Expanded(
          child: _isLoading
              ? const LoadingState(message: 'Carregando solicitações...')
              : _error != null
                  ? ErrorState(
                      message: _error!,
                      onRetry: _loadTickets,
                    )
                  : _tickets.isEmpty
                      ? EmptyState(
                          icon: Icons.support_agent,
                          title: 'Nenhuma solicitação encontrada',
                          message: 'Crie uma solicitação para solicitar suporte ou reportar um problema.',
                          actionLabel: 'Nova Solicitação',
                          onAction: _showCreateDialog,
                        )
                      : isMobile
                          ? _buildMobileList(openTickets, inProgressTickets, resolvedTickets, closedTickets, canEdit)
                          : _buildKanbanView(openTickets, inProgressTickets, resolvedTickets, closedTickets, canEdit),
        ),
      ],
    );
  }

  Widget _buildMobileList(
    List<ServiceRequest> openTickets,
    List<ServiceRequest> inProgressTickets,
    List<ServiceRequest> resolvedTickets,
    List<ServiceRequest> closedTickets,
    bool canEdit,
  ) {
    final allTickets = [
      ...openTickets,
      ...inProgressTickets,
      ...resolvedTickets,
      ...closedTickets,
    ];

    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding(context).horizontal,
        vertical: AppSpacing.md,
      ),
      itemCount: allTickets.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == allTickets.length) {
          return Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentPage++;
                  });
                  _loadTickets(showLoading: false);
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

        final ticket = allTickets[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _buildRequestCard(ticket, canEdit, isMobile: true),
        );
      },
    );
  }

  Widget _buildKanbanView(
    List<ServiceRequest> openTickets,
    List<ServiceRequest> inProgressTickets,
    List<ServiceRequest> resolvedTickets,
    List<ServiceRequest> closedTickets,
    bool canEdit,
  ) {
    return RefreshIndicator(
      onRefresh: () {
        setState(() {
          _currentPage = 1;
        });
        return _loadTickets();
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildKanbanColumn('Aberto', openTickets, AppColors.info, canEdit, 'open'),
          _buildKanbanColumn('Em Progresso', inProgressTickets, AppColors.warning, canEdit, 'in_progress'),
          _buildKanbanColumn('Resolvido', resolvedTickets, AppColors.success, canEdit, 'resolved'),
          _buildKanbanColumn('Fechado', closedTickets, AppColors.textSecondary, canEdit, 'closed'),
        ],
      ),
    );
  }

  Widget _buildKanbanColumn(
    String title,
    List<ServiceRequest> tickets,
    Color color,
    bool canEdit,
    String status,
  ) {
    return Expanded(
      child: AccessibleCard(
        margin: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppBorders.cardRadius),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    title,
                    style: AppTypography.sectionTitle.copyWith(
                      color: color,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppBorders.smallRadius),
                    ),
                    child: Text(
                      '${tickets.length}',
                      style: AppTypography.labelMedium.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: tickets.isEmpty
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: Text(
                          'Nenhuma solicitação',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(AppSpacing.sm),
                      itemCount: tickets.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _buildRequestCard(
                            tickets[index],
                            canEdit,
                            isMobile: false,
                            onStatusChanged: (newStatus) {
                              _moveToStage(tickets[index], newStatus);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(
    ServiceRequest ticket,
    bool canEdit, {
    required bool isMobile,
    Function(String)? onStatusChanged,
  }) {
    return AccessibleCard(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppBorders.cardRadius),
          onTap: () => _navigateToDetail(ticket.id),
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ticket.title,
                        style: AppTypography.cardTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: AppColors.textSecondary, size: 20),
                      tooltip: 'Ações',
                      onSelected: (value) {
                        if (value == 'delete' && canEdit) {
                          _deleteTicket(ticket);
                        } else if (value.startsWith('move_') && onStatusChanged != null) {
                          onStatusChanged(value.replaceFirst('move_', ''));
                        }
                      },
                      itemBuilder: (context) => [
                        if (onStatusChanged != null && !ticket.isOpen)
                          PopupMenuItem(
                            value: 'move_open',
                            child: Row(
                              children: [
                                const Icon(Icons.lock_open, size: 20),
                                const SizedBox(width: AppSpacing.sm),
                                Text('Mover para Aberto', style: AppTypography.bodyMedium),
                              ],
                            ),
                          ),
                        if (onStatusChanged != null && !ticket.isInProgress)
                          PopupMenuItem(
                            value: 'move_in_progress',
                            child: Row(
                              children: [
                                const Icon(Icons.play_arrow, size: 20),
                                const SizedBox(width: AppSpacing.sm),
                                Text('Mover para Em Progresso', style: AppTypography.bodyMedium),
                              ],
                            ),
                          ),
                        if (onStatusChanged != null && !ticket.isResolved)
                          PopupMenuItem(
                            value: 'move_resolved',
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, size: 20),
                                const SizedBox(width: AppSpacing.sm),
                                Text('Mover para Resolvido', style: AppTypography.bodyMedium),
                              ],
                            ),
                          ),
                        if (onStatusChanged != null && !ticket.isClosed)
                          PopupMenuItem(
                            value: 'move_closed',
                            child: Row(
                              children: [
                                const Icon(Icons.close, size: 20),
                                const SizedBox(width: AppSpacing.sm),
                                Text('Mover para Fechado', style: AppTypography.bodyMedium),
                              ],
                            ),
                          ),
                        if (onStatusChanged != null) const PopupMenuDivider(),
                        if (canEdit)
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(Icons.delete, size: 20, color: AppColors.error),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  'Excluir',
                                  style: AppTypography.bodyMedium.copyWith(
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
                const SizedBox(height: AppSpacing.sm),
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
                        color: ticket.statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppBorders.smallRadius),
                      ),
                      child: Text(
                        ticket.statusLabel,
                        style: AppTypography.caption.copyWith(
                          color: ticket.statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: ticket.priorityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppBorders.smallRadius),
                      ),
                      child: Text(
                        ticket.priorityLabel,
                        style: AppTypography.caption.copyWith(
                          color: ticket.priorityColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(Icons.person, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: AppSpacing.xs / 2),
                    Text(
                      ticket.createdBy['name'] ?? 'Usuário',
                      style: AppTypography.caption,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Icon(Icons.comment, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: AppSpacing.xs / 2),
                    Text(
                      '${ticket.commentsCount ?? 0}',
                      style: AppTypography.caption,
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('dd/MM/yyyy').format(ticket.createdAt),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
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
}
