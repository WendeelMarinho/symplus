class Category {
  final int id;
  final String type; // 'income' or 'expense'
  final String name;
  final String color; // Hex color
  final int? transactionsCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
    required this.id,
    required this.type,
    required this.name,
    required this.color,
    this.transactionsCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      type: json['type'] as String,
      name: json['name'] as String,
      color: json['color'] as String? ?? '#3B82F6',
      transactionsCount: json['transactions_count'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'color': color,
      if (transactionsCount != null) 'transactions_count': transactionsCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';
}

