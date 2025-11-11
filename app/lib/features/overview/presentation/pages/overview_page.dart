import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/navigation/menu_catalog.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../../core/widgets/page_header.dart';

class OverviewPage extends ConsumerWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final menuItems = authState.allowedMenuItems;

    // Organizar features em categorias
    final financeFeatures = menuItems.where((item) => 
      ['accounts', 'transactions', 'categories', 'due-items', 'dashboard'].contains(item.id)
    ).toList();
    
    final managementFeatures = menuItems.where((item) => 
      ['documents', 'requests', 'notifications'].contains(item.id)
    ).toList();
    
    final analyticsFeatures = menuItems.where((item) => 
      ['reports-pl'].contains(item.id) || item.id == 'reports'
    ).toList();
    
    final settingsFeatures = menuItems.where((item) => 
      ['profile', 'settings', 'subscription'].contains(item.id)
    ).toList();

    return Column(
      children: [
        PageHeader(
          title: 'Visão Geral',
          subtitle: 'Acesse rapidamente todas as funcionalidades disponíveis',
          breadcrumbs: const ['Início'],
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (financeFeatures.isNotEmpty) ...[
                  _buildSectionTitle(context, 'Financeiro', Icons.account_balance),
                  const SizedBox(height: 12),
                  _buildFeatureGrid(context, financeFeatures),
                  const SizedBox(height: 24),
                ],
                if (managementFeatures.isNotEmpty) ...[
                  _buildSectionTitle(context, 'Gestão', Icons.business),
                  const SizedBox(height: 12),
                  _buildFeatureGrid(context, managementFeatures),
                  const SizedBox(height: 24),
                ],
                if (analyticsFeatures.isNotEmpty) ...[
                  _buildSectionTitle(context, 'Análises', Icons.analytics),
                  const SizedBox(height: 12),
                  _buildFeatureGrid(context, analyticsFeatures),
                  const SizedBox(height: 24),
                ],
                if (settingsFeatures.isNotEmpty) ...[
                  _buildSectionTitle(context, 'Configurações', Icons.settings),
                  const SizedBox(height: 12),
                  _buildFeatureGrid(context, settingsFeatures),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildFeatureGrid(BuildContext context, List<MenuItem> items) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final crossAxisCount = isMobile ? 2 : 3;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _FeatureCard(
          menuItem: item,
          onTap: () => context.go(item.route),
        );
      },
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final MenuItem menuItem;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.menuItem,
    required this.onTap,
  });

  String _getDescription(String id) {
    switch (id) {
      case 'dashboard':
        return 'Visão geral das finanças';
      case 'accounts':
        return 'Gerencie suas contas';
      case 'transactions':
        return 'Registre transações';
      case 'categories':
        return 'Organize categorias';
      case 'due-items':
        return 'Controle vencimentos';
      case 'documents':
        return 'Armazene documentos';
      case 'requests':
        return 'Acompanhe tickets';
      case 'notifications':
        return 'Central de notificações';
      case 'reports-pl':
      case 'reports':
        return 'Análise financeira';
      case 'subscription':
        return 'Plano e limites';
      case 'profile':
        return 'Seus dados';
      case 'settings':
        return 'Preferências';
      default:
        return 'Acessar funcionalidade';
    }
  }

  Color _getColor(String id) {
    switch (id) {
      case 'dashboard':
        return Colors.blue;
      case 'accounts':
        return Colors.green;
      case 'transactions':
        return Colors.orange;
      case 'categories':
        return Colors.purple;
      case 'due-items':
        return Colors.red;
      case 'documents':
        return Colors.indigo;
      case 'requests':
        return Colors.teal;
      case 'notifications':
        return Colors.amber;
      case 'reports-pl':
      case 'reports':
        return Colors.pink;
      case 'subscription':
        return Colors.cyan;
      case 'profile':
        return Colors.deepOrange;
      case 'settings':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor(menuItem.id);
    final description = _getDescription(menuItem.id);

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    menuItem.icon,
                    size: 40,
                    color: color,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  menuItem.label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

