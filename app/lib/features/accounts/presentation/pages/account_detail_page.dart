import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/loading_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/toast_service.dart';
import '../../../../core/widgets/list_item_card.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../data/models/account.dart';
import '../../data/services/account_service.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../../transactions/data/services/transaction_service.dart';

class AccountDetailPage extends StatefulWidget {
  final int accountId;

  const AccountDetailPage({
    super.key,
    required this.accountId,
  });

  @override
  State<AccountDetailPage> createState() => _AccountDetailPageState();
}

class _AccountDetailPageState extends State<AccountDetailPage> {
  Account? _account;
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  bool _isLoadingTransactions = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAccount();
    _loadTransactions();
  }

  Future<void> _loadAccount() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await AccountService.get(widget.accountId);
      if (response.statusCode == 200) {
        final data = response.data;
        // API pode retornar {'data': {...}} ou diretamente {...}
        final accountData = data['data'] ?? data;
        setState(() {
          _account = Account.fromJson(accountData);
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

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoadingTransactions = true;
    });

    try {
      final response = await TransactionService.list(
        accountId: widget.accountId,
        page: 1,
      );
      if (response.statusCode == 200) {
        final data = response.data['data'] as List<dynamic>;
        setState(() {
          _transactions = data
              .map((json) => Transaction.fromJson(json))
              .take(10)
              .toList();
          _isLoadingTransactions = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingTransactions = false;
      });
    }
  }

  Future<void> _deleteAccount() async {
    if (_account == null) return;

    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Confirmar Exclusão',
      message: 'Deseja realmente excluir a conta "${_account!.name}"? Esta ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
      cancelLabel: 'Cancelar',
      icon: Icons.delete,
      isDestructive: true,
    );

    if (confirmed) {
      try {
        await AccountService.delete(_account!.id);
        if (mounted) {
          ToastService.showSuccess(context, 'Conta excluída com sucesso!');
          context.pop();
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

  Future<void> _editAccount() async {
    if (_account == null) return;

    final nameController = TextEditingController(text: _account!.name);
    final currencyController = TextEditingController(text: _account!.currency);
    final balanceController = TextEditingController(
      text: _account!.openingBalance?.toString() ?? '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Conta'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome da Conta',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: currencyController,
                decoration: const InputDecoration(
                  labelText: 'Moeda',
                  hintText: 'BRL, USD, EUR',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: balanceController,
                decoration: const InputDecoration(
                  labelText: 'Saldo Inicial',
                  hintText: '0.00',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await AccountService.update(
          _account!.id,
          name: nameController.text,
          currency: currencyController.text,
          openingBalance: balanceController.text.isNotEmpty
              ? double.tryParse(balanceController.text.replaceAll(',', '.'))
              : null,
        );
        if (mounted) {
          ToastService.showSuccess(context, 'Conta atualizada com sucesso!');
          _loadAccount();
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

  void _navigateToTransactions() {
    context.push('/app/transactions?accountId=${widget.accountId}');
  }

  void _navigateToAddTransaction() {
    context.push('/app/transactions?action=create&accountId=${widget.accountId}');
  }

  String _formatCurrency(double value, String currency) {
    return NumberFormat.currency(
      locale: 'pt_BR',
      symbol: currency == 'BRL' ? 'R\$' : currency,
    ).format(value);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingState(message: 'Carregando conta...');
    }

    if (_error != null || _account == null) {
      return ErrorState(
        message: _error ?? 'Erro ao carregar conta',
        onRetry: _loadAccount,
      );
    }

    return Column(
      children: [
        PageHeader(
          title: _account!.name,
          subtitle: 'Detalhes da conta',
          breadcrumbs: const ['Financeiro', 'Contas', 'Detalhes'],
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editAccount,
              tooltip: 'Editar',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteAccount,
              tooltip: 'Excluir',
            ),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card de informações principais
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: (_account!.balance >= 0
                                        ? Colors.green
                                        : Colors.red)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.account_balance_wallet,
                                color: _account!.balance >= 0
                                    ? Colors.green
                                    : Colors.red,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Saldo Atual',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.7),
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatCurrency(_account!.balance, _account!.currency),
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: _account!.balance >= 0
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Moeda',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.7),
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _account!.currency,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ],
                            ),
                            if (_account!.openingBalance != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Saldo Inicial',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.7),
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatCurrency(
                                      _account!.openingBalance!,
                                      _account!.currency,
                                    ),
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Seção de transações
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Últimas Transações',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: _navigateToTransactions,
                            child: const Text('Ver todas'),
                          ),
                          FilledButton.icon(
                            onPressed: _navigateToAddTransaction,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Adicionar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Lista de transações
                if (_isLoadingTransactions)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_transactions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: EmptyState(
                      icon: Icons.swap_horiz,
                      title: 'Nenhuma transação',
                      message: 'Esta conta ainda não possui transações.',
                      actionLabel: 'Adicionar Transação',
                      onAction: _navigateToAddTransaction,
                    ),
                  )
                else
                  ..._transactions.map((transaction) {
                    return ListItemCard(
                      title: transaction.description,
                      subtitle: '${transaction.categoryName ?? "Sem categoria"} • ${DateFormat('dd/MM/yyyy').format(transaction.occurredAt)}',
                      trailing: Text(
                        _formatCurrency(transaction.amount, _account!.currency),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: transaction.type == 'income' ? Colors.green : Colors.red,
                            ),
                      ),
                      leadingIcon: transaction.type == 'income'
                          ? Icons.arrow_downward
                          : Icons.arrow_upward,
                      leadingColor: transaction.type == 'income'
                          ? Colors.green
                          : Colors.red,
                      onTap: () {
                        context.push('/app/transactions?id=${transaction.id}');
                      },
                    );
                  }),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

