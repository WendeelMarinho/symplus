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
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        _subscription!.planColor.withOpacity(0.1),
                                        _subscription!.planColor.withOpacity(0.05),
                                      ],
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: _subscription!.planColor.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(
                                                color: _subscription!.planColor.withOpacity(0.3),
                                                width: 2,
                                              ),
                                            ),
                                            child: Icon(
                                              Icons.card_membership,
                                              color: _subscription!.planColor,
                                              size: 36,
                                            ),
                                          ),
                                          const SizedBox(width: 20),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _subscription!.planName,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .headlineMedium
                                                      ?.copyWith(
                                                        fontWeight: FontWeight.bold,
                                                        color: _subscription!.planColor,
                                                      ),
                                                ),
                                                const SizedBox(height: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: _subscription!.isActive
                                                        ? Colors.green
                                                        : _subscription!.isOnTrial
                                                            ? Colors.orange
                                                            : Colors.grey,
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: Text(
                                                    _subscription!.isActive
                                                        ? 'Plano Ativo'
                                                        : _subscription!.isOnTrial
                                                            ? 'Período de Teste'
                                                            : 'Plano Inativo',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
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
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.analytics,
                                            color: Theme.of(context).colorScheme.primary,
                                            size: 28,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Limites do Plano',
                                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      ..._subscription!.planLimits.entries.map((entry) {
                                        final feature = entry.key;
                                        final limit = entry.value;
                                        final icon = _getFeatureIcon(feature);
                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 12),
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .surfaceContainerHighest
                                                .withOpacity(0.5),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .outline
                                                  .withOpacity(0.2),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primaryContainer,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Icon(
                                                  icon,
                                                  color: Theme.of(context).colorScheme.primary,
                                                  size: 24,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      _formatFeatureName(feature),
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleMedium
                                                          ?.copyWith(
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      _getFeatureDescription(feature),
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
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: limit == -1
                                                      ? Colors.green.withOpacity(0.1)
                                                      : Theme.of(context)
                                                          .colorScheme
                                                          .primaryContainer,
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  limit == -1
                                                      ? 'Ilimitado'
                                                      : limit.toString(),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        fontWeight: FontWeight.bold,
                                                        color: limit == -1
                                                            ? Colors.green.shade700
                                                            : Theme.of(context)
                                                                .colorScheme
                                                                .onPrimaryContainer,
                                                      ),
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

                              // Card de Ações
                              if (canManage) ...[
                                Card(
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.settings,
                                              color: Theme.of(context).colorScheme.primary,
                                              size: 28,
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'Gerenciar Assinatura',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        if (_subscription!.plan != 'enterprise')
                                          FilledButton.icon(
                                            onPressed: () => _upgradePlan(
                                              _subscription!.plan == 'free'
                                                  ? 'basic'
                                                  : _subscription!.plan == 'basic'
                                                      ? 'premium'
                                                      : 'enterprise',
                                            ),
                                            icon: const Icon(Icons.upgrade, size: 24),
                                            label: Text(
                                              _subscription!.plan == 'free'
                                                  ? 'Fazer Upgrade para Básico'
                                                  : _subscription!.plan == 'basic'
                                                      ? 'Fazer Upgrade para Premium'
                                                      : 'Fazer Upgrade para Empresarial',
                                              style: const TextStyle(fontSize: 16),
                                            ),
                                            style: FilledButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 24,
                                                vertical: 18,
                                              ),
                                              minimumSize: const Size(double.infinity, 56),
                                            ),
                                          ),
                                        if (_subscription!.plan != 'free' &&
                                            _subscription!.isActive) ...[
                                          const SizedBox(height: 12),
                                          OutlinedButton.icon(
                                            onPressed: _cancelSubscription,
                                            icon: const Icon(Icons.cancel, size: 24),
                                            label: const Text(
                                              'Cancelar Assinatura',
                                              style: TextStyle(fontSize: 16),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 24,
                                                vertical: 18,
                                              ),
                                              minimumSize: const Size(double.infinity, 56),
                                              foregroundColor: Colors.red,
                                              side: const BorderSide(color: Colors.red),
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .surfaceContainerHighest
                                                .withOpacity(0.5),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.info_outline,
                                                color: Theme.of(context).colorScheme.primary,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  'Para mais opções de gerenciamento, entre em contato com o suporte.',
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
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ] else ...[
                                Card(
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.blue.withOpacity(0.3),
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(20),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.info_outline,
                                            color: Colors.blue,
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Permissão Necessária',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.blue.shade700,
                                                    ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Apenas proprietários e administradores podem alterar o plano.',
                                                style: TextStyle(
                                                  color: Colors.blue.shade700,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
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

  IconData _getFeatureIcon(String feature) {
    switch (feature) {
      case 'accounts':
        return Icons.account_balance_wallet;
      case 'transactions':
        return Icons.swap_horiz;
      case 'documents':
        return Icons.description;
      case 'users':
        return Icons.people;
      case 'organizations':
        return Icons.business;
      default:
        return Icons.check_circle;
    }
  }

  String _getFeatureDescription(String feature) {
    switch (feature) {
      case 'accounts':
        return 'Número máximo de contas financeiras';
      case 'transactions':
        return 'Número máximo de transações por mês';
      case 'documents':
        return 'Número máximo de documentos armazenados';
      case 'users':
        return 'Número máximo de usuários na organização';
      case 'organizations':
        return 'Número máximo de organizações';
      default:
        return 'Limite de uso';
    }
  }
}

