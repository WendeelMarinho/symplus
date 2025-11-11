import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/toast_service.dart';
import '../../../../core/widgets/loading_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../data/services/service_request_service.dart';
import '../../data/models/service_request.dart';

class RequestDetailPage extends ConsumerStatefulWidget {
  final int ticketId;

  const RequestDetailPage({super.key, required this.ticketId});

  @override
  ConsumerState<RequestDetailPage> createState() => _RequestDetailPageState();
}

class _RequestDetailPageState extends ConsumerState<RequestDetailPage> {
  ServiceRequest? _ticket;
  bool _isLoading = true;
  String? _error;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTicket();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadTicket() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ServiceRequestService.get(widget.ticketId);
      if (response.statusCode == 200) {
        final data = response.data;
        final ticketData = data['data'] ?? data;
        setState(() {
          _ticket = ServiceRequest.fromJson(ticketData);
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

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) {
      ToastService.showError(context, 'Digite um comentário');
      return;
    }

    try {
      await ServiceRequestService.addComment(
        widget.ticketId,
        comment: _commentController.text.trim(),
      );
      _commentController.clear();
      if (mounted) {
        ToastService.showSuccess(context, 'Comentário adicionado!');
        _loadTicket();
      }
    } catch (e) {
      if (mounted) {
        ToastService.showError(context, 'Erro ao adicionar comentário');
      }
    }
  }

  Future<void> _changeStatus(String newStatus) async {
    try {
      switch (newStatus) {
        case 'in_progress':
          await ServiceRequestService.markInProgress(widget.ticketId);
          break;
        case 'resolved':
          await ServiceRequestService.markResolved(widget.ticketId);
          break;
        case 'closed':
          await ServiceRequestService.markClosed(widget.ticketId);
          break;
      }
      if (mounted) {
        ToastService.showSuccess(context, 'Status atualizado!');
        _loadTicket();
      }
    } catch (e) {
      if (mounted) {
        ToastService.showError(context, 'Erro ao atualizar status');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final canEdit = authState.role == 'owner' || authState.role == 'admin';

    return Column(
      children: [
        PageHeader(
          title: 'Detalhes do Ticket',
          subtitle: _ticket?.title ?? '',
          breadcrumbs: const ['Suporte', 'Tickets', 'Detalhes'],
        ),
        Expanded(
          child: _isLoading
              ? const LoadingState(message: 'Carregando ticket...')
              : _error != null
                  ? ErrorState(
                      message: _error!,
                      onRetry: _loadTicket,
                    )
                  : _ticket == null
                      ? const Center(child: Text('Ticket não encontrado'))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Card de Informações
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _ticket!.title,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headlineSmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: _ticket!.statusColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(color: _ticket!.statusColor),
                                            ),
                                            child: Text(
                                              _ticket!.statusLabel,
                                              style: TextStyle(
                                                color: _ticket!.statusColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _ticket!.description,
                                        style: Theme.of(context).textTheme.bodyLarge,
                                      ),
                                      const SizedBox(height: 16),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          Chip(
                                            label: Text('Prioridade: ${_ticket!.priorityLabel}'),
                                            backgroundColor:
                                                _ticket!.priorityColor.withOpacity(0.1),
                                            side: BorderSide(color: _ticket!.priorityColor),
                                          ),
                                          if (_ticket!.category != null)
                                            Chip(
                                              label: Text(_ticket!.category!),
                                            ),
                                          Chip(
                                            label: Text(
                                                'Criado por: ${_ticket!.createdBy['name']}'),
                                          ),
                                          if (_ticket!.assignedTo != null)
                                            Chip(
                                              label: Text(
                                                  'Atribuído a: ${_ticket!.assignedTo!['name']}'),
                                            ),
                                        ],
                                      ),
                                      if (canEdit && !_ticket!.isClosed) ...[
                                        const SizedBox(height: 16),
                                        Wrap(
                                          spacing: 8,
                                          children: [
                                            if (_ticket!.isOpen)
                                              FilledButton.icon(
                                                onPressed: () => _changeStatus('in_progress'),
                                                icon: const Icon(Icons.play_arrow),
                                                label: const Text('Iniciar'),
                                              ),
                                            if (_ticket!.isInProgress)
                                              FilledButton.icon(
                                                onPressed: () => _changeStatus('resolved'),
                                                icon: const Icon(Icons.check),
                                                label: const Text('Resolver'),
                                                style: FilledButton.styleFrom(
                                                  backgroundColor: Colors.green,
                                                ),
                                              ),
                                            if (_ticket!.isResolved)
                                              FilledButton.icon(
                                                onPressed: () => _changeStatus('closed'),
                                                icon: const Icon(Icons.close),
                                                label: const Text('Fechar'),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Timeline de Comentários
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Comentários (${_ticket!.comments?.length ?? 0})',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 16),

                                      // Timeline
                                      if (_ticket!.comments != null && _ticket!.comments!.isNotEmpty)
                                        ..._ticket!.comments!.map((comment) {
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 16),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                CircleAvatar(
                                                  radius: 16,
                                                  child: Text(
                                                    comment.user['name'][0].toUpperCase(),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Text(
                                                            comment.user['name'],
                                                            style: Theme.of(context)
                                                                .textTheme
                                                                .bodyMedium
                                                                ?.copyWith(
                                                                  fontWeight: FontWeight.bold,
                                                                ),
                                                          ),
                                                          const SizedBox(width: 8),
                                                          Text(
                                                            DateFormat('dd/MM/yyyy HH:mm')
                                                                .format(comment.createdAt),
                                                            style: Theme.of(context)
                                                                .textTheme
                                                                .bodySmall
                                                                ?.copyWith(
                                                                  color: Theme.of(context)
                                                                      .colorScheme
                                                                      .onSurface
                                                                      .withOpacity(0.6),
                                                                ),
                                                          ),
                                                          if (comment.isInternal) ...[
                                                            const SizedBox(width: 8),
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(
                                                                  horizontal: 6, vertical: 2),
                                                              decoration: BoxDecoration(
                                                                color: Colors.orange.withOpacity(0.2),
                                                                borderRadius:
                                                                    BorderRadius.circular(8),
                                                              ),
                                                              child: Text(
                                                                'Interno',
                                                                style: TextStyle(
                                                                  fontSize: 10,
                                                                  color: Colors.orange[700],
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        comment.comment,
                                                        style:
                                                            Theme.of(context).textTheme.bodyMedium,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),

                                      // Adicionar Comentário
                                      if (!_ticket!.isClosed) ...[
                                        const Divider(),
                                        const SizedBox(height: 16),
                                        TextFormField(
                                          controller: _commentController,
                                          decoration: const InputDecoration(
                                            labelText: 'Adicionar comentário',
                                            border: OutlineInputBorder(),
                                            hintText: 'Digite seu comentário...',
                                          ),
                                          maxLines: 3,
                                        ),
                                        const SizedBox(height: 8),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: FilledButton.icon(
                                            onPressed: _addComment,
                                            icon: const Icon(Icons.send),
                                            label: const Text('Enviar'),
                                          ),
                                        ),
                                      ],
                                    ],
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

