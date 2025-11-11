import 'package:flutter/material.dart';

/// Utilitários para layouts responsivos
class ResponsiveLayout {
  // Breakpoints
  static const double mobileMaxWidth = 599;
  static const double tabletMaxWidth = 999;
  static const double desktopMinWidth = 1000;

  /// Verifica se é mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width <= mobileMaxWidth;
  }

  /// Verifica se é tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width > mobileMaxWidth && width <= tabletMaxWidth;
  }

  /// Verifica se é desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopMinWidth;
  }

  /// Retorna o número de colunas baseado no tamanho da tela
  static int getColumnCount(BuildContext context) {
    if (isMobile(context)) return 1;
    if (isTablet(context)) return 2;
    return 3;
  }

  /// Retorna padding responsivo
  static EdgeInsets getPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(16.0);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(24.0);
    } else {
      return const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0);
    }
  }

  /// Retorna largura máxima para conteúdo (não estoura lateralmente)
  static double? getMaxContentWidth(BuildContext context) {
    if (isDesktop(context)) {
      return 1200; // Largura máxima em desktop
    }
    return null; // Mobile/tablet usa largura total
  }

  /// Retorna espaçamento entre itens (gutter)
  static double getGutter(BuildContext context) {
    if (isMobile(context)) return 8.0;
    if (isTablet(context)) return 12.0;
    return 16.0;
  }
}

/// Widget que aplica largura máxima e centraliza conteúdo
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final maxWidth = ResponsiveLayout.getMaxContentWidth(context);
    final defaultPadding = ResponsiveLayout.getPadding(context);

    return Container(
      width: double.infinity,
      constraints: maxWidth != null
          ? BoxConstraints(maxWidth: maxWidth)
          : const BoxConstraints(),
      padding: padding ?? defaultPadding,
      child: child,
    );
  }
}

