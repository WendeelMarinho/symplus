import 'package:flutter/material.dart';
import '../accessibility/responsive_utils.dart';

/// Espaçamento do Design System Symplus Finance
/// Scale: 4, 8, 12, 16, 20, 24, 32
class AppSpacing {
  AppSpacing._();

  // Base spacing scale
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0; // Base spacing
  static const double lg = 20.0;
  static const double xl = 24.0; // Spacing between large blocks
  static const double xxl = 32.0;

  // Standard Page Padding
  static EdgeInsets pagePadding(BuildContext context) {
    if (ResponsiveUtils.isMobile(context)) {
      return const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.lg);
    } else if (ResponsiveUtils.isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl);
    } else {
      return const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xxl);
    }
  }

  // Standard Card Padding
  static EdgeInsets cardPadding(BuildContext context) {
    if (ResponsiveUtils.isMobile(context)) {
      return const EdgeInsets.all(AppSpacing.sm);
    } else {
      return const EdgeInsets.all(AppSpacing.md);
    }
  }
}

