import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/toast_service.dart';
import '../../../../core/widgets/loading_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../data/services/subscription_service.dart';
import '../../data/models/subscription.dart';

class SubscriptionPage extends ConsumerStatefulWidget {
  const SubscriptionPage({super.key});

  @override
  ConsumerState<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends ConsumerState<SubscriptionPage> {
  Subscription? _subscription;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await SubscriptionService.get();
      if (response.statusCode == 200) {
        final data = response.data;
        final subscriptionData = data['data'] ?? data;
        setState(() {
          _subscription = Subscription.fromJson(subscriptionData);
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

  Future<void> _upgradePlan(String plan) async {
    final authState = ref.read(authProvider);
    if (authState.role != 'owner' && authState.role != 'admin') {
      ToastService.showInfo(context, 'Apenas proprietários e administradores podem alterar o plano');
      return;
    }

    // Por enquanto, mostra mensagem de "em breve"
    ToastService.showInfo(context, 'Funcionalidade de upgrade em breve');
    
    // TODO: Implementar quando Stripe estiver configurado
    // try {
    //   await SubscriptionService.update(plan: plan);
    //   ToastService.showSuccess(context, 'Plano atualizado com sucesso!');
    //   _loadSubscription();
    // } catch (e) {
    //   ToastService.showError(context, 'Erro ao atualizar plano');
    // }
  }

  Future<void> _cancelSubscription() async {
    final authState = ref.read(authProvider);
    if (authState.role != 'owner' && authState.role != 'admin') {
      ToastService.showInfo(context, 'Apenas proprietários e administradores podem cancelar a assinatura');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Assinatura'),
        content: const Text(
          'Deseja realmente cancelar sua assinatura? Você continuará tendo acesso até o final do período pago.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Não'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sim, cancelar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SubscriptionService.cancel();
        ToastService.showSuccess(context, 'Assinatura cancelada. Você continuará tendo acesso até o final do período.');
        _loadSubscription();
      } catch (e) {
        ToastService.showError(context, 'Erro ao cancelar assinatura');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final canManage = authState.role == 'owner' || authState.role == 'admin';

    return Column(
      children: [
        PageHeader(
          title: 'Assinatura',
          subtitle: 'Gerencie seu plano e limites de uso',
          breadcrumbs: const ['Configurações', 'Assinatura'],
        ),
        Expanded(
          child: _isLoading
              ? const LoadingState(message: 'Carregando informações da assinatura...')
              : _error != null
                  ? ErrorState(
                      message: _error!,
                      onRetry: _loadSubscription,
                    )
                  : _subscription == null
                      ? const Center(child: Text('Nenhuma assinatura encontrada'))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Card do Plano Atual
                              Card(
                                elevation: 4,
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
                                              color: _subscription!.planColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              Icons.card_membership,
                                              color: _subscription!.planColor,
                                              size: 32,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _subscription!.planName,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .headlineSmall
                                                      ?.copyWith(
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _subscription!.isActive
                                                      ? 'Plano Ativo'
                                                      : _subscription!.isOnTrial
                                                          ? 'Período de Teste'
                                                          : 'Plano Inativo',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        color: _subscription!.isActive
                                                            ? Colors.green
                                                            : Colors.orange,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (_subscription!.isOnTrial && _subscription!.trialEndsAt != null) ...[
                                        const SizedBox(height: 16),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.orange),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.access_time, color: Colors.orange),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Período de teste até ${DateFormat('dd/MM/yyyy').format(_subscription!.trialEndsAt!)}',
                                                  style: const TextStyle(color: Colors.orange),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      if (_subscription!.endsAt != null) ...[
                                        const SizedBox(height: 16),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.red),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.warning, color: Colors.red),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Cancelado - Acesso até ${DateFormat('dd/MM/yyyy').format(_subscription!.endsAt!)}',
                                                  style: const TextStyle(color: Colors.red),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Limites do Plano
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Limites do Plano',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 16),
                                      ..._subscription!.planLimits.entries.map((entry) {
                                        final feature = entry.key;
                                        final limit = entry.value;
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 12),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                _formatFeatureName(feature),
                                                style: Theme.of(context).textTheme.bodyMedium,
                                              ),
                                              Text(
                                                limit == -1 ? 'Ilimitado' : limit.toString(),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      fontWeight: FontWeight.bold,
                                                      color: Theme.of(context).colorScheme.primary,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Botões de Ação
                              if (canManage) ...[
                                if (_subscription!.plan != 'enterprise')
                                  FilledButton.icon(
                                    onPressed: () => _upgradePlan(
                                      _subscription!.plan == 'free'
                                          ? 'basic'
                                          : _subscription!.plan == 'basic'
                                              ? 'premium'
                                              : 'enterprise',
                                    ),
                                    icon: const Icon(Icons.upgrade),
                                    label: const Text('Fazer Upgrade'),
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.all(16),
                                    ),
                                  ),
                                if (_subscription!.plan != 'free' && _subscription!.isActive)
                                  const SizedBox(height: 8),
                                if (_subscription!.plan != 'free' && _subscription!.isActive)
                                  OutlinedButton.icon(
                                    onPressed: _cancelSubscription,
                                    icon: const Icon(Icons.cancel),
                                    label: const Text('Cancelar Assinatura'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.all(16),
                                      foregroundColor: Colors.red,
                                    ),
                                  ),
                              ] else ...[
                                Card(
                                  color: Colors.blue.withOpacity(0.1),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.info_outline, color: Colors.blue),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Apenas proprietários e administradores podem alterar o plano.',
                                            style: TextStyle(color: Colors.blue[700]),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
        ),
      ],
    );
  }

  String _formatFeatureName(String feature) {
    switch (feature) {
      case 'accounts':
        return 'Contas';
      case 'transactions':
        return 'Transações';
      case 'documents':
        return 'Documentos';
      case 'users':
        return 'Usuários';
      case 'organizations':
        return 'Organizações';
      default:
        return feature.replaceAll('_', ' ').split(' ').map((word) {
          return word[0].toUpperCase() + word.substring(1);
        }).join(' ');
    }
  }
}
