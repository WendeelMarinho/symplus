/// Model de Indicador Personalizado
/// 
/// Representa um indicador que agrupa múltiplas categorias
/// para calcular um valor total e percentual sobre despesas.
class CustomIndicator {
  final int id;
  final String name;
  final List<int> categoryIds; // IDs das categorias vinculadas
  final double? totalValue; // Valor total calculado (opcional, calculado em runtime)
  final double? percentage; // Percentual sobre total de despesas (opcional, calculado em runtime)
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CustomIndicator({
    required this.id,
    required this.name,
    required this.categoryIds,
    this.totalValue,
    this.percentage,
    this.createdAt,
    this.updatedAt,
  });

  factory CustomIndicator.fromJson(Map<String, dynamic> json) {
    return CustomIndicator(
      id: json['id'] as int,
      name: json['name'] as String,
      categoryIds: (json['category_ids'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      totalValue: json['total_value'] != null
          ? (json['total_value'] as num).toDouble()
          : null,
      percentage: json['percentage'] != null
          ? (json['percentage'] as num).toDouble()
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category_ids': categoryIds,
      if (totalValue != null) 'total_value': totalValue,
      if (percentage != null) 'percentage': percentage,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  /// Cria uma cópia do indicador com campos atualizados
  CustomIndicator copyWith({
    int? id,
    String? name,
    List<int>? categoryIds,
    double? totalValue,
    double? percentage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomIndicator(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryIds: categoryIds ?? this.categoryIds,
      totalValue: totalValue ?? this.totalValue,
      percentage: percentage ?? this.percentage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

