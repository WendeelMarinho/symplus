import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/accessibility/responsive_utils.dart';

/// Widget wrapper que torna qualquer widget do dashboard arrastável
/// Funciona em web, mobile e desktop
class DraggableDashboardItem extends StatefulWidget {
  final String widgetId;
  final Widget child;
  final Function(String, int)? onDragStart;
  final Function(String, int)? onDragEnd;
  final Function(String, int, int)? onReorder;

  const DraggableDashboardItem({
    super.key,
    required this.widgetId,
    required this.child,
    this.onDragStart,
    this.onDragEnd,
    this.onReorder,
  });

  @override
  State<DraggableDashboardItem> createState() => _DraggableDashboardItemState();
}

class _DraggableDashboardItemState extends State<DraggableDashboardItem> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<String>(
      data: widget.widgetId,
      // Para web: também funciona com mouse drag no handle
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 300,
          constraints: const BoxConstraints(maxHeight: 200),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Opacity(
            opacity: 0.9,
            child: widget.child,
          ),
        ),
      ),
      onDragStarted: () {
        setState(() => _isDragging = true);
        HapticFeedback.mediumImpact();
      },
      onDragEnd: (_) {
        setState(() => _isDragging = false);
      },
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: widget.child,
      ),
      child: Stack(
        children: [
          widget.child,
          // Drag handle no canto superior direito
          Positioned(
            top: 8,
            right: 8,
            child: _DragHandle(
              isDragging: _isDragging,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget do drag handle (ícone de arrastar)
class _DragHandle extends StatelessWidget {
  final bool isDragging;

  const _DragHandle({required this.isDragging});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: Tooltip(
        message: 'Arraste para reordenar',
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.drag_handle,
            size: 18,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ),
    );
  }
}
