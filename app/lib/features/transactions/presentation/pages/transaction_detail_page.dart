import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/loading_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/toast_service.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/accessibility/telemetry_service.dart';
import '../../../../core/accessibility/responsive_utils.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/services/transaction_service.dart';
import '../../data/models/transaction.dart';
import '../../../documents/data/services/document_service.dart';

/// Página de detalhe de uma transação individual
class TransactionDetailPage extends ConsumerStatefulWidget {
  final int transactionId;

  const TransactionDetailPage({
    super.key,
    required this.transactionId,
  });

  @override
  ConsumerState<TransactionDetailPage> createState() =>
      _TransactionDetailPageState();
}

class _TransactionDetailPageState
    extends ConsumerState<TransactionDetailPage> {
  Transaction? _transaction;
  bool _isLoading = true;
  String? _error;
  String? _documentUrl;
  bool _isLoadingDocument = false;

  @override
  void initState() {
    super.initState();
    _loadTransaction();
  }

  Future<void> _loadTransaction() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await TransactionService.get(widget.transactionId);

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        setState(() {
          _transaction = Transaction.fromJson(data);
          _isLoading = false;
        });

        // Carregar URL do documento se houver
        if (_transaction != null) {
          _loadDocumentUrl();
        }
      } else {
        throw Exception('Erro ao carregar transação');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      TelemetryService.logError(e.toString(), context: 'transaction_detail.load');
    }
  }

  Future<void> _loadDocumentUrl() async {
    if (_transaction == null) return;

    setState(() {
      _isLoadingDocument = true;
    });

    try {
      // Buscar documentos associados à transação
      final response = await DocumentService.list(
        documentableType: 'transaction',
        documentableId: widget.transactionId,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List<dynamic>;
        if (data.isNotEmpty) {
          final document = data.first as Map<String, dynamic>;
          final documentId = document['id'] as int;

          // Obter URL temporária do documento
          final urlResponse = await DocumentService.getUrl(documentId);
          if (urlResponse.statusCode == 200) {
            setState(() {
              _documentUrl = urlResponse.data['url'] as String?;
              _isLoadingDocument = false;
            });
          }
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingDocument = false;
      });
      TelemetryService.logError(e.toString(), context: 'transaction_detail.document_url');
    }
  }

  String _formatCurrency(double value, CurrencyState currencyState) {
    return CurrencyFormatter.format(value, currencyState);
  }

  Future<void> _deleteTransaction() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Excluir Transação',
      message: 'Tem certeza que deseja excluir esta transação? Esta ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
      cancelLabel: 'Cancelar',
      icon: Icons.delete_forever,
    );

    if (confirmed && _transaction != null) {
      try {
        await TransactionService.delete(_transaction!.id);
        if (mounted) {
          ToastService.showSuccess(context, 'Transação excluída com sucesso!');
          TelemetryService.logAction('transaction.deleted', metadata: {
            'transaction_id': _transaction!.id.toString(),
          });
          context.go('/app/transactions');
        }
      } catch (e) {
        if (mounted) {
          ToastService.showError(context, 'Erro ao excluir transação: ${e.toString()}');
        }
        TelemetryService.logError(e.toString(), context: 'transaction_detail.delete');
      }
    }
  }

  void _editTransaction() {
    if (_transaction != null) {
      context.go('/app/transactions/${_transaction!.id}/edit');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingState();
    }

    if (_error != null || _transaction == null) {
      return ErrorState(
        message: _error ?? 'Transação não encontrada',
        onRetry: _loadTransaction,
      );
    }

    final isMobile = ResponsiveUtils.isMobile(context);
    final isIncome = _transaction!.type == 'income';

    return Scaffold(
      body: Column(
        children: [
          PageHeader(
            title: 'Detalhes da Transação',
            subtitle: _transaction!.description,
            breadcrumbs: const ['Transações', 'Detalhes'],
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Editar Transação',
                onPressed: _editTransaction,
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                tooltip: 'Excluir Transação',
                onPressed: _deleteTransaction,
                color: Theme.of(context).colorScheme.error,
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: ResponsiveUtils.getResponsivePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card principal com informações
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tipo e valor
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isIncome
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isIncome
                                          ? Icons.arrow_downward
                                          : Icons.arrow_upward,
                                      color: isIncome ? Colors.green : Colors.red,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isIncome ? 'Entrada' : 'Saída',
                                      style: TextStyle(
                                        color: isIncome ? Colors.green : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Consumer(
                                builder: (context, ref, child) {
                                  final currencyState = ref.watch(currencyProvider);
                                  return Text(
                                    _formatCurrency(_transaction!.amount, currencyState),
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: isIncome ? Colors.green : Colors.red,
                                        ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Informações detalhadas
                          _buildInfoRow(
                            'Categoria',
                            _transaction!.categoryName ?? 'Sem categoria',
                            Icons.category,
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            'Conta',
                            _transaction!.accountName ?? 'Sem conta',
                            Icons.account_balance_wallet,
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            'Data',
                            DateFormat('dd/MM/yyyy').format(_transaction!.occurredAt),
                            Icons.calendar_today,
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            'Descrição',
                            _transaction!.description,
                            Icons.description,
                          ),
                          if (_transaction!.createdAt != _transaction!.updatedAt) ...[
                            const SizedBox(height: 16),
                            _buildInfoRow(
                              'Última atualização',
                              DateFormat('dd/MM/yyyy HH:mm').format(_transaction!.updatedAt),
                              Icons.update,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Documento anexado
                  ...[
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.attach_file,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Documento Anexado',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_isLoadingDocument)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else if (_documentUrl != null)
                              Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceVariant,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.picture_as_pdf,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Documento disponível',
                                            style: Theme.of(context).textTheme.bodyMedium,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.icon(
                                      onPressed: () {
                                        // Abrir documento em nova aba (web) ou visualizador
                                        TelemetryService.logAction(
                                          'transaction_detail.document_opened',
                                          metadata: {
                                            'transaction_id': _transaction!.id.toString(),
                                          },
                                        );
                                        // TODO: Implementar abertura de documento
                                        ToastService.showInfo(
                                          context,
                                          'Abrindo documento...',
                                        );
                                      },
                                      icon: const Icon(Icons.open_in_new),
                                      label: const Text('Abrir Documento'),
                                    ),
                                  ),
                                ],
                              )
                            else
                              Text(
                                'Nenhum documento encontrado',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.6),
                                    ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

