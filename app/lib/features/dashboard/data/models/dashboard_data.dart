class DashboardData {
  final FinancialSummary financialSummary;
  final List<TransactionSummary> recentTransactions;
  final List<DueItemSummary> upcomingDueItems;
  final List<DueItemSummary> overdueItems;
  final List<AccountBalance> accountBalances;
  final List<MonthlyIncomeExpense> monthlyIncomeExpense;
  final TopCategories topCategories;
  final CashFlowProjection cashFlowProjection;

  DashboardData({
    required this.financialSummary,
    required this.recentTransactions,
    required this.upcomingDueItems,
    required this.overdueItems,
    required this.accountBalances,
    required this.monthlyIncomeExpense,
    required this.topCategories,
    required this.cashFlowProjection,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      financialSummary: FinancialSummary.fromJson(json['financial_summary']),
      recentTransactions: (json['recent_transactions'] as List)
          .map((e) => TransactionSummary.fromJson(e))
          .toList(),
      upcomingDueItems: (json['upcoming_due_items'] as List)
          .map((e) => DueItemSummary.fromJson(e))
          .toList(),
      overdueItems: (json['overdue_items'] as List)
          .map((e) => DueItemSummary.fromJson(e))
          .toList(),
      accountBalances: (json['account_balances'] as List)
          .map((e) => AccountBalance.fromJson(e))
          .toList(),
      monthlyIncomeExpense: (json['monthly_income_expense'] as List)
          .map((e) => MonthlyIncomeExpense.fromJson(e))
          .toList(),
      topCategories: TopCategories.fromJson(json['top_categories']),
      cashFlowProjection: CashFlowProjection.fromJson(json['cash_flow_projection']),
    );
  }
}

class FinancialSummary {
  final double income;
  final double expenses;
  final double net;
  final Period period;

  FinancialSummary({
    required this.income,
    required this.expenses,
    required this.net,
    required this.period,
  });

  factory FinancialSummary.fromJson(Map<String, dynamic> json) {
    return FinancialSummary(
      income: (json['income'] as num).toDouble(),
      expenses: (json['expenses'] as num).toDouble(),
      net: (json['net'] as num).toDouble(),
      period: Period.fromJson(json['period']),
    );
  }
}

class Period {
  final String from;
  final String to;

  Period({required this.from, required this.to});

  factory Period.fromJson(Map<String, dynamic> json) {
    return Period(
      from: json['from'] as String,
      to: json['to'] as String,
    );
  }
}

class TransactionSummary {
  final int id;
  final String description;
  final double amount;
  final String type;
  final String occurredAt;
  final AccountSummary? account;
  final CategorySummary? category;

  TransactionSummary({
    required this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.occurredAt,
    this.account,
    this.category,
  });

  factory TransactionSummary.fromJson(Map<String, dynamic> json) {
    return TransactionSummary(
      id: json['id'] as int,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String,
      occurredAt: json['occurred_at'] as String,
      account: json['account'] != null
          ? AccountSummary.fromJson(json['account'])
          : null,
      category: json['category'] != null
          ? CategorySummary.fromJson(json['category'])
          : null,
    );
  }
}

class AccountSummary {
  final int id;
  final String name;

  AccountSummary({required this.id, required this.name});

  factory AccountSummary.fromJson(Map<String, dynamic> json) {
    return AccountSummary(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

class CategorySummary {
  final int id;
  final String name;

  CategorySummary({required this.id, required this.name});

  factory CategorySummary.fromJson(Map<String, dynamic> json) {
    return CategorySummary(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

class DueItemSummary {
  final int id;
  final String title;
  final double amount;
  final String type;
  final String dueDate;
  final String status;
  final int? daysUntilDue;
  final int? daysOverdue;

  DueItemSummary({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.dueDate,
    required this.status,
    this.daysUntilDue,
    this.daysOverdue,
  });

  factory DueItemSummary.fromJson(Map<String, dynamic> json) {
    return DueItemSummary(
      id: json['id'] as int,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String,
      dueDate: json['due_date'] as String,
      status: json['status'] as String,
      daysUntilDue: json['days_until_due'] as int?,
      daysOverdue: json['days_overdue'] as int?,
    );
  }

  bool get isPay => type == 'pay';
  bool get isReceive => type == 'receive';
  bool get isPending => status == 'pending';
  bool get isPaid => status == 'paid';
  bool get isOverdueStatus => status == 'overdue';
}

class AccountBalance {
  final int id;
  final String name;
  final double balance;

  AccountBalance({
    required this.id,
    required this.name,
    required this.balance,
  });

  factory AccountBalance.fromJson(Map<String, dynamic> json) {
    return AccountBalance(
      id: json['id'] as int,
      name: json['name'] as String,
      balance: (json['balance'] as num).toDouble(),
    );
  }
}

class MonthlyIncomeExpense {
  final String month;
  final double income;
  final double expenses;
  final double net;

  MonthlyIncomeExpense({
    required this.month,
    required this.income,
    required this.expenses,
    required this.net,
  });

  factory MonthlyIncomeExpense.fromJson(Map<String, dynamic> json) {
    return MonthlyIncomeExpense(
      month: json['month'] as String,
      income: (json['income'] as num).toDouble(),
      expenses: (json['expenses'] as num).toDouble(),
      net: (json['net'] as num).toDouble(),
    );
  }
}

class TopCategories {
  final List<CategoryTotal> income;
  final List<CategoryTotal> expenses;

  TopCategories({
    required this.income,
    required this.expenses,
  });

  factory TopCategories.fromJson(Map<String, dynamic> json) {
    return TopCategories(
      income: (json['income'] as List)
          .map((e) => CategoryTotal.fromJson(e))
          .toList(),
      expenses: (json['expenses'] as List)
          .map((e) => CategoryTotal.fromJson(e))
          .toList(),
    );
  }
}

class CategoryTotal {
  final CategorySummary category;
  final double total;

  CategoryTotal({
    required this.category,
    required this.total,
  });

  factory CategoryTotal.fromJson(Map<String, dynamic> json) {
    return CategoryTotal(
      category: CategorySummary.fromJson(json['category']),
      total: (json['total'] as num).toDouble(),
    );
  }
}

class CashFlowProjection {
  final double currentBalance;
  final double projectedIncome;
  final double projectedExpenses;
  final double projectedBalance;
  final int projectionPeriodDays;

  CashFlowProjection({
    required this.currentBalance,
    required this.projectedIncome,
    required this.projectedExpenses,
    required this.projectedBalance,
    required this.projectionPeriodDays,
  });

  factory CashFlowProjection.fromJson(Map<String, dynamic> json) {
    return CashFlowProjection(
      currentBalance: (json['current_balance'] as num).toDouble(),
      projectedIncome: (json['projected_income'] as num).toDouble(),
      projectedExpenses: (json['projected_expenses'] as num).toDouble(),
      projectedBalance: (json['projected_balance'] as num).toDouble(),
      projectionPeriodDays: json['projection_period_days'] as int,
    );
  }
}

