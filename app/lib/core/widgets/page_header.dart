import 'package:flutter/material.dart';
import '../design/app_colors.dart';
import '../design/app_typography.dart';
import '../design/app_spacing.dart';

/// Header padrão moderno para todas as páginas
/// Layout: Breadcrumb + Título + Subtítulo | Ações à direita
class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<String>? breadcrumbs;
  final List<Widget>? actions;

  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.breadcrumbs,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final padding = EdgeInsets.symmetric(
      horizontal: AppSpacing.pagePadding(context).horizontal,
      vertical: isMobile ? AppSpacing.md : AppSpacing.lg,
    );

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumbs (se houver)
          if (breadcrumbs != null && breadcrumbs!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...breadcrumbs!.asMap().entries.map((entry) {
                      final isLast = entry.key == breadcrumbs!.length - 1;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            entry.value,
                            style: AppTypography.caption.copyWith(
                              color: isLast
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontWeight: isLast ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          if (!isLast) ...[
                            const SizedBox(width: AppSpacing.xs),
                            Icon(
                              Icons.chevron_right,
                              size: 14,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                          ],
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          // Título, subtítulo e ações
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.display.copyWith(
                        fontSize: isMobile ? 24 : 28,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle!,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (actions != null && actions!.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.lg),
                if (isMobile)
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: actions!,
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: actions!
                        .map((action) => Padding(
                              padding: const EdgeInsets.only(left: AppSpacing.sm),
                              child: action,
                            ))
                        .toList(),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

