class Account {
  final int id;
  final String name;
  final String currency;
  final double balance; // current_balance da API
  final double? openingBalance;
  final DateTime createdAt;
  final DateTime updatedAt;

  Account({
    required this.id,
    required this.name,
    required this.currency,
    required this.balance,
    this.openingBalance,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] as int,
      name: json['name'] as String,
      currency: json['currency'] as String,
      balance: ((json['current_balance'] ?? json['balance'] ?? 0) as num).toDouble(),
      openingBalance: json['opening_balance'] != null
          ? (json['opening_balance'] as num).toDouble()
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'currency': currency,
      'current_balance': balance,
      if (openingBalance != null) 'opening_balance': openingBalance,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

