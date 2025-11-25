import 'dashboard_widget.dart';

/// Modelo de layout do dashboard (template ou personalizado)
class DashboardLayout {
  /// ID do layout (null para templates padrão)
  final String? id;

  /// Visão associada (cash, result, collection)
  final DashboardView view;

  /// Lista de widgets na ordem definida
  final List<DashboardWidget> widgets;

  /// Se é um template padrão ou layout personalizado
  final bool isTemplate;

  /// Timestamp de criação/atualização
  final DateTime? updatedAt;

  DashboardLayout({
    this.id,
    required this.view,
    required this.widgets,
    this.isTemplate = false,
    this.updatedAt,
  });

  factory DashboardLayout.fromJson(Map<String, dynamic> json) {
    return DashboardLayout(
      id: json['id'] as String?,
      view: DashboardView.fromString(json['view'] as String),
      widgets: (json['widgets'] as List)
          .map((e) => DashboardWidget.fromJson(e as Map<String, dynamic>))
          .toList(),
      isTemplate: json['is_template'] as bool? ?? false,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'view': view.value,
      'widgets': widgets.map((w) => w.toJson()).toList(),
      'is_template': isTemplate,
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}

/// Modelo de insight para cards do dashboard
class DashboardInsight {
  /// ID do widget relacionado (ex: "kpi_income")
  final String widgetId;

  /// Tipo de insight (warning, info, success, error)
  final String type;

  /// Mensagem do insight
  final String message;

  /// Ícone opcional
  final String? icon;

  DashboardInsight({
    required this.widgetId,
    required this.type,
    required this.message,
    this.icon,
  });

  factory DashboardInsight.fromJson(Map<String, dynamic> json) {
    return DashboardInsight(
      widgetId: json['widget_id'] as String,
      type: json['type'] as String,
      message: json['message'] as String,
      icon: json['icon'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'widget_id': widgetId,
      'type': type,
      'message': message,
      if (icon != null) 'icon': icon,
    };
  }
}

