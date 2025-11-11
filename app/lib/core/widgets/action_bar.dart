import 'package:flutter/material.dart';

/// Faixa de ações padrão para páginas (botões de ação principais)
class ActionBar extends StatelessWidget {
  final List<ActionItem> actions;

  const ActionBar({
    super.key,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            ...actions.map((action) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: _buildActionButton(context, action),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, ActionItem action) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    switch (action.type) {
      case ActionType.primary:
        return Semantics(
          label: action.label,
          button: true,
          enabled: action.onPressed != null,
          child: FilledButton.icon(
            onPressed: action.onPressed,
            icon: Icon(action.icon, semanticLabel: action.label),
            label: Text(action.label),
            style: FilledButton.styleFrom(
              minimumSize: Size(isMobile ? 120 : 140, 40),
            ),
          ),
        );
      case ActionType.secondary:
        return OutlinedButton.icon(
          onPressed: action.onPressed,
          icon: Icon(action.icon, semanticLabel: action.label),
          label: Text(action.label),
          style: OutlinedButton.styleFrom(
            minimumSize: Size(isMobile ? 100 : 120, 40),
          ),
        );
      case ActionType.icon:
        return Tooltip(
          message: action.label,
          waitDuration: const Duration(milliseconds: 500),
          child: Semantics(
            label: action.label,
            button: true,
            enabled: action.onPressed != null,
            child: IconButton(
              onPressed: action.onPressed,
              icon: Icon(action.icon, semanticLabel: action.label),
              tooltip: action.label,
              iconSize: 24,
            ),
          ),
        );
    }
  }
}

enum ActionType {
  primary,
  secondary,
  icon,
}

class ActionItem {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final ActionType type;

  const ActionItem({
    required this.label,
    required this.icon,
    this.onPressed,
    this.type = ActionType.primary,
  });
}

