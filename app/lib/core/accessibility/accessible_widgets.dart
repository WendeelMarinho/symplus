import 'package:flutter/material.dart';

/// Widget que garante tooltip e semântica adequada
class AccessibleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final String? semanticLabel;

  const AccessibleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: Semantics(
        label: semanticLabel ?? tooltip,
        button: true,
        enabled: onPressed != null,
        child: IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
          tooltip: tooltip,
        ),
      ),
    );
  }
}

/// Botão com tooltip e semântica
class AccessibleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String? tooltip;
  final String? semanticLabel;
  final ButtonStyle? style;

  const AccessibleButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.tooltip,
    this.semanticLabel,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = ElevatedButton(
      onPressed: onPressed,
      style: style,
      child: child,
    );

    if (tooltip != null || semanticLabel != null) {
      button = Semantics(
        label: semanticLabel ?? tooltip,
        button: true,
        enabled: onPressed != null,
        child: tooltip != null
            ? Tooltip(
                message: tooltip!,
                waitDuration: const Duration(milliseconds: 500),
                child: button,
              )
            : button,
      );
    }

    return button;
  }
}

/// FilledButton com tooltip e semântica
class AccessibleFilledButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String? tooltip;
  final String? semanticLabel;
  final ButtonStyle? style;

  const AccessibleFilledButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.tooltip,
    this.semanticLabel,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = FilledButton(
      onPressed: onPressed,
      style: style,
      child: child,
    );

    if (tooltip != null || semanticLabel != null) {
      button = Semantics(
        label: semanticLabel ?? tooltip,
        button: true,
        enabled: onPressed != null,
        child: tooltip != null
            ? Tooltip(
                message: tooltip!,
                waitDuration: const Duration(milliseconds: 500),
                child: button,
              )
            : button,
      );
    }

    return button;
  }
}

/// Card clicável com semântica
class AccessibleCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;

  const AccessibleCard({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      child: Card(
        child: InkWell(
          onTap: onTap,
          child: child,
        ),
      ),
    );
  }
}

