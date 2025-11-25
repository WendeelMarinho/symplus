/// Modelo genérico de widget do dashboard
class DashboardWidget {
  /// ID único e estável do widget (ex: "kpi_income", "custom_indicators")
  final String id;

  /// Tipo do widget para agrupamento
  final String type;

  /// Tamanho padrão em colunas para grid (1-12)
  final int defaultSpan;

  /// Ordem padrão no layout
  final int defaultOrder;

  /// Se o widget está visível por padrão
  final bool visible;

  /// Metadados adicionais (flexível para extensões futuras)
  final Map<String, dynamic>? metadata;

  DashboardWidget({
    required this.id,
    required this.type,
    this.defaultSpan = 6,
    this.defaultOrder = 0,
    this.visible = true,
    this.metadata,
  });

  factory DashboardWidget.fromJson(Map<String, dynamic> json) {
    return DashboardWidget(
      id: json['id'] as String,
      type: json['type'] as String,
      defaultSpan: json['default_span'] as int? ?? 6,
      defaultOrder: json['default_order'] as int? ?? 0,
      visible: json['visible'] as bool? ?? true,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'default_span': defaultSpan,
      'default_order': defaultOrder,
      'visible': visible,
      if (metadata != null) 'metadata': metadata,
    };
  }
}

/// Enum para as visões de dashboard disponíveis
enum DashboardView {
  cash('cash', 'Visão Caixa'),
  result('result', 'Visão Resultado'),
  collection('collection', 'Visão Cobrança');

  final String value;
  final String label;

  const DashboardView(this.value, this.label);

  static DashboardView fromString(String value) {
    return DashboardView.values.firstWhere(
      (v) => v.value == value,
      orElse: () => DashboardView.cash,
    );
  }
}

