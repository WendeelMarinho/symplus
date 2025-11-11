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

  @override
  Widget build(BuildContext context) {
    final unreadNotifications = _notifications.where((n) => n.isUnread).toList();
    final readNotifications = _notifications.where((n) => !n.isUnread).toList();

    return Column(
      children: [
        PageHeader(
          title: 'Notificações',
          subtitle: 'Visualize todas as suas notificações e alertas',
          breadcrumbs: const ['Sistema', 'Notificações'],
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
                  : _notifications.isEmpty
                      ? EmptyState(
                          icon: Icons.notifications_none,
                          title: 'Nenhuma notificação',
                          message: 'Você está em dia! Quando houver novas notificações, elas aparecerão aqui.',
                        )
                      : RefreshIndicator(
                          onRefresh: () {
                            setState(() {
                              _currentPage = 1;
                            });
                            return _loadNotifications();
                          },
                          child: ListView.builder(
                            itemCount: (unreadNotifications.length > 0 ? 1 : 0) +
                                unreadNotifications.length +
                                (readNotifications.length > 0 ? 1 : 0) +
                                readNotifications.length +
                                (_hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              // Seção de não lidas
                              if (unreadNotifications.isNotEmpty && index == 0) {
                                return Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                  child: Text(
                                    'Não lidas (${unreadNotifications.length})',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                  ),
                                );
                              }

                              // Ajustar índice para não lidas
                              int adjustedIndex = index;
                              if (unreadNotifications.isNotEmpty) {
                                adjustedIndex--;
                                if (adjustedIndex < unreadNotifications.length) {
                                  final notification = unreadNotifications[adjustedIndex];
                                  return _buildNotificationItem(notification);
                                }
                                adjustedIndex -= unreadNotifications.length;
                              }

                              // Seção de lidas
                              if (readNotifications.isNotEmpty && adjustedIndex == 0) {
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

                              // Ajustar índice para lidas
                              if (readNotifications.isNotEmpty) {
                                adjustedIndex--;
                                if (adjustedIndex < readNotifications.length) {
                                  final notification = readNotifications[adjustedIndex];
                                  return _buildNotificationItem(notification);
                                }
                                adjustedIndex -= readNotifications.length;
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

  Widget _buildNotificationItem(NotificationModel.Notification notification) {
    return ListItemCard(
      title: notification.title,
      subtitle: notification.message,
      leadingIcon: notification.icon,
      leadingColor: notification.color,
      trailing: notification.isUnread
          ? Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            )
          : const SizedBox.shrink(),
      onTap: () => _markAsRead(notification),
      actions: [
        if (notification.isUnread)
          IconButton(
            icon: const Icon(Icons.check, size: 20),
            onPressed: () => _markAsRead(notification),
            tooltip: 'Marcar como lida',
          ),
        IconButton(
          icon: const Icon(Icons.delete, size: 20),
          onPressed: () => _deleteNotification(notification),
          tooltip: 'Excluir',
        ),
      ],
    );
  }
}
