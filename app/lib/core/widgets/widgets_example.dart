import 'package:flutter/material.dart';
import 'confirm_dialog.dart';
import 'error_state.dart';
import 'info_dialog.dart';
import 'toast_service.dart';

/// Arquivo de exemplo/documentação para uso dos widgets de feedback
/// 
/// Este arquivo não é usado no código, apenas serve como referência de uso.

class WidgetsExamplePage extends StatelessWidget {
  const WidgetsExamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exemplos de Feedback')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Toasts
          _buildSection(
            context,
            'Toasts / Snackbars',
            [
              ListTile(
                title: const Text('Toast de Sucesso'),
                onTap: () => ToastService.showSuccess(context, 'Operação realizada com sucesso!'),
              ),
              ListTile(
                title: const Text('Toast de Erro'),
                onTap: () => ToastService.showError(context, 'Ocorreu um erro ao processar a requisição'),
              ),
              ListTile(
                title: const Text('Toast de Aviso'),
                onTap: () => ToastService.showWarning(context, 'Atenção: Verifique os dados informados'),
              ),
              ListTile(
                title: const Text('Toast de Informação'),
                onTap: () => ToastService.showInfo(context, 'Nova atualização disponível'),
              ),
            ],
          ),
          
          // Dialogs
          _buildSection(
            context,
            'Dialogs',
            [
              ListTile(
                title: const Text('Dialog de Confirmação'),
                subtitle: const Text('Exemplo: Excluir item'),
                onTap: () async {
                  final confirmed = await ConfirmDialog.show(
                    context,
                    title: 'Confirmar Exclusão',
                    message: 'Tem certeza que deseja excluir este item? Esta ação não pode ser desfeita.',
                    confirmLabel: 'Excluir',
                    cancelLabel: 'Cancelar',
                    confirmColor: Colors.red,
                    icon: Icons.delete,
                  );
                  if (confirmed && context.mounted) {
                    ToastService.showSuccess(context, 'Item excluído com sucesso!');
                  }
                },
              ),
              ListTile(
                title: const Text('Dialog Informativo'),
                onTap: () {
                  InfoDialog.show(
                    context,
                    title: 'Informação',
                    message: 'Esta é uma mensagem informativa para o usuário.',
                    icon: Icons.info,
                  );
                },
              ),
            ],
          ),
          
          // Error State
          _buildSection(
            context,
            'Estados de Erro',
            [
              ListTile(
                title: const Text('Error State com Retry'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => Scaffold(
                        appBar: AppBar(title: const Text('Exemplo de Erro')),
                        body: ErrorState(
                          title: 'Erro ao carregar dados',
                          message: 'Não foi possível conectar ao servidor. Verifique sua conexão com a internet.',
                          onRetry: () {
                            ToastService.showInfo(context, 'Tentando novamente...');
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
}

