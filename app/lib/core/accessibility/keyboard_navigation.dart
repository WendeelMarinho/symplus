import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Helper para navegação por teclado
class KeyboardNavigation {
  /// Navegação por teclado padrão
  static Widget buildKeyboardNavigable({
    required Widget child,
    VoidCallback? onEnter,
    VoidCallback? onEscape,
    VoidCallback? onTab,
    bool autofocus = false,
  }) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.select) {
            onEnter?.call();
          } else if (event.logicalKey == LogicalKeyboardKey.escape) {
            onEscape?.call();
          } else if (event.logicalKey == LogicalKeyboardKey.tab) {
            onTab?.call();
          }
        }
      },
      child: Focus(
        autofocus: autofocus,
        child: child,
      ),
    );
  }

  /// Shortcuts comuns da aplicação
  static Map<LogicalKeySet, Intent> get commonShortcuts => {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN):
            const _NewItemIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS):
            const _SaveIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF):
            const _SearchIntent(),
        LogicalKeySet(LogicalKeyboardKey.escape): const _EscapeIntent(),
      };

  /// Actions para os shortcuts
  static Map<Type, Action<Intent>> get commonActions => {
        _NewItemIntent: CallbackAction<_NewItemIntent>(
          onInvoke: (intent) => intent.onInvoke?.call(),
        ),
        _SaveIntent: CallbackAction<_SaveIntent>(
          onInvoke: (intent) => intent.onInvoke?.call(),
        ),
        _SearchIntent: CallbackAction<_SearchIntent>(
          onInvoke: (intent) => intent.onInvoke?.call(),
        ),
        _EscapeIntent: CallbackAction<_EscapeIntent>(
          onInvoke: (intent) => intent.onInvoke?.call(),
        ),
      };
}

class _NewItemIntent extends Intent {
  final VoidCallback? onInvoke;
  const _NewItemIntent({this.onInvoke});
}

class _SaveIntent extends Intent {
  final VoidCallback? onInvoke;
  const _SaveIntent({this.onInvoke});
}

class _SearchIntent extends Intent {
  final VoidCallback? onInvoke;
  const _SearchIntent({this.onInvoke});
}

class _EscapeIntent extends Intent {
  final VoidCallback? onInvoke;
  const _EscapeIntent({this.onInvoke});
}

