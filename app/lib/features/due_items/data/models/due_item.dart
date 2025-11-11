class DueItem {
  final int id;
  final String title;
  final double amount;
  final DateTime dueDate;
  final String type; // 'pay' or 'receive'
  final String status; // 'pending', 'paid', 'overdue'
  final String? description;
  final bool isOverdue;
  final DateTime createdAt;
  final DateTime updatedAt;

  DueItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.type,
    required this.status,
    this.description,
    required this.isOverdue,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DueItem.fromJson(Map<String, dynamic> json) {
    return DueItem(
      id: json['id'] as int,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      dueDate: DateTime.parse(json['due_date'] as String),
      type: json['type'] as String,
      status: json['status'] as String,
      description: json['description'] as String?,
      isOverdue: json['is_overdue'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'due_date': dueDate.toIso8601String().split('T')[0],
      'type': type,
      'status': status,
      if (description != null) 'description': description,
      'is_overdue': isOverdue,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isPay => type == 'pay';
  bool get isReceive => type == 'receive';
  bool get isPending => status == 'pending';
  bool get isPaid => status == 'paid';
  bool get isOverdueStatus => status == 'overdue';
}

