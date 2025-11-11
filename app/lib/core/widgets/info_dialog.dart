import 'package:flutter/material.dart';

/// Dialog informativo padrão
class InfoDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonLabel;
  final IconData? icon;

  const InfoDialog({
    super.key,
    required this.title,
    required this.message,
    this.buttonLabel = 'OK',
    this.icon,
  });

  /// Mostra o dialog informativo
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    String buttonLabel = 'OK',
    IconData? icon,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => InfoDialog(
        title: title,
        message: message,
        buttonLabel: buttonLabel,
        icon: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: icon != null
          ? Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 48,
            )
          : null,
      title: Text(title),
      content: Text(message),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(buttonLabel),
        ),
      ],
    );
  }
}

