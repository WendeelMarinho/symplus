class Transaction {
  final int id;
  final String description;
  final double amount;
  final String type; // 'income' or 'expense'
  final DateTime occurredAt;
  final int? accountId;
  final String? accountName;
  final int? categoryId;
  final String? categoryName;
  final DateTime createdAt;
  final DateTime updatedAt;

  Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.occurredAt,
    this.accountId,
    this.accountName,
    this.categoryId,
    this.categoryName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as int,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String,
      occurredAt: DateTime.parse(json['occurred_at'] as String),
      accountId: json['account']?['id'] as int?,
      accountName: json['account']?['name'] as String?,
      categoryId: json['category']?['id'] as int?,
      categoryName: json['category']?['name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

