import 'package:flutter/material.dart';
import '../design/app_colors.dart';
import '../design/app_borders.dart';
import '../design/app_spacing.dart';
import '../design/app_shadows.dart';

/// Widget que garante tooltip e semântica adequada
/// Estilo moderno: círculo com hover
class AccessibleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final String? semanticLabel;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const AccessibleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.semanticLabel,
    this.backgroundColor,
    this.foregroundColor,
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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(AppBorders.buttonRadius),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: backgroundColor ?? Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: foregroundColor ?? AppColors.onSurface,
                size: 20,
              ),
            ),
          ),
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
  final Widget? child;
  final VoidCallback? onPressed;
  final String? tooltip;
  final String? semanticLabel;
  final ButtonStyle? style;
  final IconData? icon;
  final String? label;

  const AccessibleFilledButton({
    super.key,
    this.child,
    this.onPressed,
    this.tooltip,
    this.semanticLabel,
    this.style,
    this.icon,
    this.label,
  }) : assert(child != null || (icon != null && label != null), 'Must provide either child or icon+label');

  const AccessibleFilledButton.icon({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.tooltip,
    this.semanticLabel,
    this.style,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    Widget button;
    
    if (icon != null && label != null) {
      button = FilledButton.icon(
        onPressed: onPressed,
        style: style,
        icon: Icon(icon),
        label: Text(label!),
      );
    } else {
      button = FilledButton(
        onPressed: onPressed,
        style: style,
        child: child!,
      );
    }

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
/// Estilo moderno: radius + shadow + padding do design system
class AccessibleCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final bool elevated;

  const AccessibleCard({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.padding,
    this.margin,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      child: Card(
        elevation: 0,
        shadowColor: Colors.transparent,
        margin: margin,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorders.cardRadius),
          side: BorderSide(
            color: AppColors.border,
            width: AppBorders.borderWidth,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppBorders.cardRadius),
          child: Container(
            padding: padding ?? const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppBorders.cardRadius),
              boxShadow: elevated ? [AppShadows.cardElevated] : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

