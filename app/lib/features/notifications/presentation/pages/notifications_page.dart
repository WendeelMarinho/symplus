import 'package:flutter/material.dart';
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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/notification_service.dart';
import '../../data/models/notification.dart' as NotificationModel;

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  List<NotificationModel.Notification> _notifications = [];
  bool _isLoading = true;
  String? _error;
  int _unreadCount = 0;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = false;
  String? _filterType; // null = todos, 'read' = lidas, 'unread' = não lidas
  String? _filterNotificationType; // null = todos, ou tipo específico

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final response = await NotificationService.unreadCount();
      if (response.statusCode == 200) {
        setState(() {
          _unreadCount = response.data['count'] as int? ?? 0;
        });
      }
    } catch (e) {
      // Silently fail - not critical
    }
  }

  Future<void> _loadNotifications({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final response = await NotificationService.list(
        read: _filterType == 'read' ? true : (_filterType == 'unread' ? false : null),
        type: _filterNotificationType,
        page: _currentPage,
        perPage: 15,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final notificationsData = data['data'] as List<dynamic>;
        final meta = data['meta'] ?? {};

        setState(() {
          if (_currentPage == 1) {
            _notifications = notificationsData
                .map((json) => NotificationModel.Notification.fromJson(json))
                .toList();
          } else {
            _notifications.addAll(
              notificationsData
                  .map((json) => NotificationModel.Notification.fromJson(json))
                  .toList(),
            );
          }
          _totalPages = meta['last_page'] ?? 1;
          _hasMore = _currentPage < (_totalPages);
          _isLoading = false;
        });
        
        // Ordenar: não lidas primeiro
        _notifications.sort((a, b) {
          if (a.isUnread && !b.isUnread) return -1;
          if (!a.isUnread && b.isUnread) return 1;
          return b.createdAt.compareTo(a.createdAt);
        });

        // Atualizar contagem
        _loadUnreadCount();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(NotificationModel.Notification notification) async {
    if (!notification.isUnread) return;

    try {
      await NotificationService.markAsRead(notification.id);
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] = NotificationModel.Notification(
            id: notification.id,
            type: notification.type,
            title: notification.title,
            message: notification.message,
            data: notification.data,
            readAt: DateTime.now(),
            isUnread: false,
            createdAt: notification.createdAt,
            updatedAt: notification.updatedAt,
          );
          // Reordenar
          _notifications.sort((a, b) {
            if (a.isUnread && !b.isUnread) return -1;
            if (!a.isUnread && b.isUnread) return 1;
            return b.createdAt.compareTo(a.createdAt);
          });
        }
      });
      _loadUnreadCount();
      if (mounted) {
        ToastService.showSuccess(context, 'Notificação marcada como lida');
      }
    } catch (e) {
      if (mounted) {
        ToastService.showError(context, 'Erro ao marcar notificação como lida');
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await NotificationService.markAllAsRead();
      setState(() {
        _notifications = _notifications.map((n) {
          if (n.isUnread) {
            return NotificationModel.Notification(
              id: n.id,
              type: n.type,
              title: n.title,
              message: n.message,
              data: n.data,
              readAt: DateTime.now(),
              isUnread: false,
              createdAt: n.createdAt,
              updatedAt: n.updatedAt,
            );
          }
          return n;
        }).toList();
      });
      _loadUnreadCount();
      if (mounted) {
        ToastService.showSuccess(context, 'Todas as notificações foram marcadas como lidas');
      }
    } catch (e) {
      if (mounted) {
        ToastService.showError(context, 'Erro ao marcar notificações como lidas');
      }
    }
  }

  Future<void> _deleteNotification(NotificationModel.Notification notification) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Confirmar Exclusão',
      message: 'Deseja realmente excluir esta notificação?',
      confirmLabel: 'Excluir',
      cancelLabel: 'Cancelar',
      icon: Icons.delete,
      isDestructive: true,
    );

    if (confirmed) {
      try {
        await NotificationService.delete(notification.id);
        setState(() {
          _notifications.removeWhere((n) => n.id == notification.id);
        });
        _loadUnreadCount();
        if (mounted) {
          ToastService.showSuccess(context, 'Notificação excluída');
        }
      } catch (e) {
        if (mounted) {
          ToastService.showError(context, 'Erro ao excluir notificação');
        }
      }
    }
  }

  void _clearFilters() {
    setState(() {
      _filterType = null;
      _filterNotificationType = null;
      _currentPage = 1;
    });
    _loadNotifications();
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrar Notificações'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Filtro por status (lida/não lida)
                DropdownButtonFormField<String?>(
                  value: _filterType,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Todas')),
                    DropdownMenuItem(value: 'unread', child: Text('Não lidas')),
                    DropdownMenuItem(value: 'read', child: Text('Lidas')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      _filterType = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Filtro por tipo
                DropdownButtonFormField<String?>(
                  value: _filterNotificationType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Todos')),
                    DropdownMenuItem(value: 'due_item_reminder', child: Text('Lembrete de Vencimento')),
                    DropdownMenuItem(value: 'service_request_update', child: Text('Atualização de Solicitação')),
                    DropdownMenuItem(value: 'system_alert', child: Text('Alerta do Sistema')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      _filterNotificationType = value;
                    });
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearFilters();
            },
            child: const Text('Limpar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _currentPage = 1;
              });
              _loadNotifications();
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadNotifications = _notifications.where((n) => n.isUnread).toList();
    final readNotifications = _notifications.where((n) => !n.isUnread).toList();
    final hasFilters = _filterType != null || _filterNotificationType != null;
    final filteredNotifications = _notifications;

    return Column(
      children: [
        PageHeader(
          title: 'Notificações',
          subtitle: 'Visualize todas as suas notificações e alertas',
          breadcrumbs: const ['Sistema', 'Notificações'],
          actions: [
            // Badge com contagem de não lidas
            if (_unreadCount > 0)
              Badge(
                label: Text('$_unreadCount'),
                child: IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () {
                    setState(() {
                      _filterType = 'unread';
                      _currentPage = 1;
                    });
                    _loadNotifications();
                  },
                  tooltip: 'Ver não lidas',
                ),
              ),
            // Botão marcar todas como lidas
            if (unreadNotifications.isNotEmpty)
              FilledButton.icon(
                onPressed: _markAllAsRead,
                icon: const Icon(Icons.done_all, size: 18),
                label: const Text('Marcar Todas como Lidas'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            // Botão de filtros
            IconButton(
              icon: Stack(
                children: [
                  const Icon(Icons.filter_list),
                  if (hasFilters)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: _showFilterDialog,
              tooltip: 'Filtrar',
            ),
            // Botão limpar filtros
            if (hasFilters)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: _clearFilters,
                tooltip: 'Limpar filtros',
              ),
          ],
        ),
        // Barra de filtros ativos
        if (hasFilters)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                Icon(Icons.filter_alt, size: 16, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (_filterType != null)
                        Chip(
                          label: Text(_filterType == 'read' ? 'Lidas' : 'Não lidas'),
                          onDeleted: () {
                            setState(() {
                              _filterType = null;
                              _currentPage = 1;
                            });
                            _loadNotifications();
                          },
                          deleteIcon: const Icon(Icons.close, size: 16),
                        ),
                      if (_filterNotificationType != null)
                        Chip(
                          label: Text(_getNotificationTypeLabel(_filterNotificationType!)),
                          onDeleted: () {
                            setState(() {
                              _filterNotificationType = null;
                              _currentPage = 1;
                            });
                            _loadNotifications();
                          },
                          deleteIcon: const Icon(Icons.close, size: 16),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ActionBar(
          actions: [
            if (unreadNotifications.isNotEmpty)
              ActionItem(
                label: 'Marcar Todas como Lidas',
                icon: Icons.done_all,
                onPressed: _markAllAsRead,
                type: ActionType.secondary,
              ),
          ],
        ),
        Expanded(
          child: _isLoading
              ? const LoadingState(message: 'Carregando notificações...')
              : _error != null
                  ? ErrorState(
                      message: _error!,
                      onRetry: _loadNotifications,
                    )
                  : filteredNotifications.isEmpty
                      ? EmptyState(
                          icon: Icons.notifications_none,
                          title: 'Nenhuma notificação',
                          message: hasFilters
                              ? 'Nenhuma notificação corresponde aos filtros aplicados.'
                              : 'Você está em dia! Quando houver novas notificações, elas aparecerão aqui.',
                          actionLabel: hasFilters ? 'Limpar Filtros' : null,
                          onAction: hasFilters ? _clearFilters : null,
                        )
                      : RefreshIndicator(
                          onRefresh: () {
                            setState(() {
                              _currentPage = 1;
                            });
                            return _loadNotifications();
                          },
                          child: ListView.builder(
                            itemCount: (!hasFilters && unreadNotifications.isNotEmpty ? 1 : 0) +
                                (!hasFilters ? unreadNotifications.length : 0) +
                                (!hasFilters && readNotifications.isNotEmpty ? 1 : 0) +
                                (!hasFilters ? readNotifications.length : filteredNotifications.length) +
                                (_hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              // Seção de não lidas (apenas se não houver filtros)
                              if (!hasFilters && unreadNotifications.isNotEmpty && index == 0) {
                                return Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                  child: Row(
                                    children: [
                                      Badge(
                                        label: Text('${unreadNotifications.length}'),
                                        child: Text(
                                          'Não lidas',
                                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              // Ajustar índice para não lidas
                              int adjustedIndex = index;
                              if (!hasFilters && unreadNotifications.isNotEmpty) {
                                adjustedIndex--;
                                if (adjustedIndex < unreadNotifications.length) {
                                  final notification = unreadNotifications[adjustedIndex];
                                  return _buildNotificationItem(notification);
                                }
                                adjustedIndex -= unreadNotifications.length;
                              }

                              // Seção de lidas (apenas se não houver filtros)
                              if (!hasFilters && readNotifications.isNotEmpty && adjustedIndex == 0) {
                                return Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                  child: Text(
                                    'Lidas (${readNotifications.length})',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                        ),
                                  ),
                                );
                              }

                              // Ajustar índice para lidas ou notificações filtradas
                              if (!hasFilters && readNotifications.isNotEmpty) {
                                adjustedIndex--;
                                if (adjustedIndex < readNotifications.length) {
                                  final notification = readNotifications[adjustedIndex];
                                  return _buildNotificationItem(notification);
                                }
                                adjustedIndex -= readNotifications.length;
                              } else if (hasFilters) {
                                if (adjustedIndex < filteredNotifications.length) {
                                  final notification = filteredNotifications[adjustedIndex];
                                  return _buildNotificationItem(notification);
                                }
                                adjustedIndex -= filteredNotifications.length;
                              }

                              // Load more button
                              return Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Center(
                                  child: TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _currentPage++;
                                      });
                                      _loadNotifications(showLoading: false);
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

  String _getNotificationTypeLabel(String type) {
    switch (type) {
      case 'due_item_reminder':
        return 'Lembrete de Vencimento';
      case 'service_request_update':
        return 'Atualização de Solicitação';
      case 'system_alert':
        return 'Alerta do Sistema';
      default:
        return type;
    }
  }

  Widget _buildNotificationItem(NotificationModel.Notification notification) {
    final timeAgo = _getTimeAgo(notification.createdAt);
    
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.horizontal,
      background: Container(
        color: Colors.green,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Row(
          children: [
            Icon(Icons.check, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Marcar como lida',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Excluir',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 8),
            Icon(Icons.delete, color: Colors.white),
          ],
        ),
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          // Swipe para direita = marcar como lida
          if (notification.isUnread) {
            _markAsRead(notification);
          }
        } else {
          // Swipe para esquerda = excluir
          _deleteNotification(notification);
        }
      },
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Confirmar exclusão
          return await ConfirmDialog.show(
            context,
            title: 'Confirmar Exclusão',
            message: 'Deseja realmente excluir esta notificação?',
            confirmLabel: 'Excluir',
            cancelLabel: 'Cancelar',
            icon: Icons.delete,
            isDestructive: true,
          );
        }
        return true;
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        elevation: notification.isUnread ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: notification.isUnread
              ? BorderSide(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  width: 1.5,
                )
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: notification.isUnread ? () => _markAsRead(notification) : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ícone com badge
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: notification.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        notification.icon,
                        color: notification.color,
                        size: 24,
                      ),
                    ),
                    if (notification.isUnread)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.surface,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                // Conteúdo
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: notification.isUnread
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                            ),
                          ),
                          if (notification.isUnread)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Nova',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeAgo,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                ),
                          ),
                          const Spacer(),
                          // Tipo
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getNotificationTypeLabel(notification.type),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Ações
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    switch (value) {
                      case 'read':
                        if (notification.isUnread) {
                          _markAsRead(notification);
                        }
                        break;
                      case 'delete':
                        _deleteNotification(notification);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    if (notification.isUnread)
                      const PopupMenuItem(
                        value: 'read',
                        child: Row(
                          children: [
                            Icon(Icons.check, size: 20),
                            SizedBox(width: 8),
                            Text('Marcar como lida'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Excluir'),
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

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return years == 1 ? 'há 1 ano' : 'há $years anos';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? 'há 1 mês' : 'há $months meses';
    } else if (difference.inDays > 0) {
      return difference.inDays == 1
          ? 'há 1 dia'
          : 'há ${difference.inDays} dias';
    } else if (difference.inHours > 0) {
      return difference.inHours == 1
          ? 'há 1 hora'
          : 'há ${difference.inHours} horas';
    } else if (difference.inMinutes > 0) {
      return difference.inMinutes == 1
          ? 'há 1 minuto'
          : 'há ${difference.inMinutes} minutos';
    } else {
      return 'agora';
    }
  }
}
