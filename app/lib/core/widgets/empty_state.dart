import 'package:flutter/material.dart';

/// Empty state padrão para páginas sem dados
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final padding = isMobile 
        ? const EdgeInsets.all(24.0)
        : const EdgeInsets.all(32.0);

    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: isMobile ? 64 : 80,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              semanticLabel: 'Ícone de estado vazio',
            ),
            SizedBox(height: isMobile ? 16 : 24),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
              semanticsLabel: 'Título: $title',
            ),
            if (message != null) ...[
              SizedBox(height: isMobile ? 8 : 12),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: isMobile ? 16 : 24),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add, semanticLabel: 'Adicionar'),
                label: Text(actionLabel!),
                style: FilledButton.styleFrom(
                  minimumSize: Size(isMobile ? 140 : 160, 48),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

