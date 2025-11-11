class PlReport {
  final Map<String, dynamic> period;
  final Map<String, dynamic> summary;
  final String groupBy;
  final List<Map<String, dynamic>> series;

  PlReport({
    required this.period,
    required this.summary,
    required this.groupBy,
    required this.series,
  });

  factory PlReport.fromJson(Map<String, dynamic> json) {
    return PlReport(
      period: json['period'] as Map<String, dynamic>,
      summary: json['summary'] as Map<String, dynamic>,
      groupBy: json['group_by'] as String,
      series: (json['series'] as List<dynamic>)
          .map((item) => item as Map<String, dynamic>)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'period': period,
      'summary': summary,
      'group_by': groupBy,
      'series': series,
    };
  }

  double get totalIncome => (summary['total_income'] as num).toDouble();
  double get totalExpense => (summary['total_expense'] as num).toDouble();
  double get netProfit => (summary['net_profit'] as num).toDouble();
  double get expenseOverIncomePercent =>
      (summary['expense_over_income_percent'] as num).toDouble();

  DateTime get fromDate => DateTime.parse(period['from'] as String);
  DateTime get toDate => DateTime.parse(period['to'] as String);
}

