import 'package:flutter/material.dart';

/// Dialog genérico para formulários simples
class FormDialog extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget form;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback? onConfirm;
  final bool isLoading;

  const FormDialog({
    super.key,
    required this.title,
    this.subtitle,
    required this.form,
    this.confirmLabel = 'Salvar',
    this.cancelLabel = 'Cancelar',
    this.onConfirm,
    this.isLoading = false,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? subtitle,
    required Widget form,
    String confirmLabel = 'Salvar',
    String cancelLabel = 'Cancelar',
    VoidCallback? onConfirm,
    bool isLoading = false,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) => FormDialog(
        title: title,
        subtitle: subtitle,
        form: form,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        onConfirm: onConfirm,
        isLoading: isLoading,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitle != null) ...[
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
              ),
              const SizedBox(height: 16),
            ],
            form,
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(cancelLabel),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : onConfirm,
          child: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(confirmLabel),
        ),
      ],
    );
  }
}

