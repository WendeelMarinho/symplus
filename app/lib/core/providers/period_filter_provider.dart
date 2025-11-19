import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tipos de período disponíveis
enum PeriodType {
  thisWeek,
  thisMonth,
  lastMonth,
  quarter,
  semester,
  year,
  custom,
}

/// Estado do filtro de período
class PeriodFilterState {
  final PeriodType type;
  final DateTime? from;
  final DateTime? to;
  final String label;

  const PeriodFilterState({
    required this.type,
    this.from,
    this.to,
    required this.label,
  });

  PeriodFilterState copyWith({
    PeriodType? type,
    DateTime? from,
    DateTime? to,
    String? label,
  }) {
    return PeriodFilterState(
      type: type ?? this.type,
      from: from ?? this.from,
      to: to ?? this.to,
      label: label ?? this.label,
    );
  }

  /// Retorna as datas calculadas para o período
  ({DateTime from, DateTime to}) get dates {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (type) {
      case PeriodType.thisWeek:
        // Segunda-feira da semana atual
        final weekday = today.weekday;
        final monday = today.subtract(Duration(days: weekday - 1));
        return (from: monday, to: today);

      case PeriodType.thisMonth:
        // Primeiro dia do mês atual até hoje
        final firstDay = DateTime(today.year, today.month, 1);
        return (from: firstDay, to: today);

      case PeriodType.lastMonth:
        // Primeiro ao último dia do mês anterior
        final lastMonth = DateTime(today.year, today.month - 1);
        final firstDay = DateTime(lastMonth.year, lastMonth.month, 1);
        final lastDay = DateTime(today.year, today.month, 0);
        return (from: firstDay, to: lastDay);

      case PeriodType.quarter:
        // Trimestre atual (Q1: Jan-Mar, Q2: Apr-Jun, Q3: Jul-Sep, Q4: Oct-Dec)
        final quarter = ((today.month - 1) / 3).floor();
        final firstMonth = quarter * 3 + 1;
        final firstDay = DateTime(today.year, firstMonth, 1);
        return (from: firstDay, to: today);

      case PeriodType.semester:
        // Semestre atual (S1: Jan-Jun, S2: Jul-Dec)
        final semester = today.month <= 6 ? 1 : 2;
        final firstMonth = semester == 1 ? 1 : 7;
        final firstDay = DateTime(today.year, firstMonth, 1);
        return (from: firstDay, to: today);

      case PeriodType.year:
        // Ano atual (1º de janeiro até hoje)
        final firstDay = DateTime(today.year, 1, 1);
        return (from: firstDay, to: today);

      case PeriodType.custom:
        // Usar datas customizadas
        if (from != null && to != null) {
          return (from: from!, to: to!);
        }
        // Fallback: último mês
        final lastMonth = DateTime(today.year, today.month - 1);
        final firstDay = DateTime(lastMonth.year, lastMonth.month, 1);
        final lastDay = DateTime(today.year, today.month, 0);
        return (from: firstDay, to: lastDay);
    }
  }

  /// Retorna label formatado para exibição
  String get displayLabel {
    if (type == PeriodType.custom && from != null && to != null) {
      // Formatar datas customizadas
      final fromStr = '${from!.day.toString().padLeft(2, '0')}/${from!.month.toString().padLeft(2, '0')}/${from!.year}';
      final toStr = '${to!.day.toString().padLeft(2, '0')}/${to!.month.toString().padLeft(2, '0')}/${to!.year}';
      return '$fromStr - $toStr';
    }
    return label;
  }
}

/// Provider do filtro de período
class PeriodFilterNotifier extends StateNotifier<PeriodFilterState> {
  PeriodFilterNotifier()
      : super(
          PeriodFilterState(
            type: PeriodType.thisMonth,
            label: 'Este mês',
          ),
        );

  /// Define o período
  void setPeriod(PeriodType type, {DateTime? from, DateTime? to}) {
    String label;
    switch (type) {
      case PeriodType.thisWeek:
        label = 'Esta semana';
        break;
      case PeriodType.thisMonth:
        label = 'Este mês';
        break;
      case PeriodType.lastMonth:
        label = 'Último mês';
        break;
      case PeriodType.quarter:
        label = 'Trimestre';
        break;
      case PeriodType.semester:
        label = 'Semestre';
        break;
      case PeriodType.year:
        label = 'Ano';
        break;
      case PeriodType.custom:
        label = 'Personalizado';
        break;
    }

    state = PeriodFilterState(
      type: type,
      from: from,
      to: to,
      label: label,
    );
  }

  /// Define período customizado
  void setCustomPeriod(DateTime from, DateTime to) {
    state = PeriodFilterState(
      type: PeriodType.custom,
      from: from,
      to: to,
      label: 'Personalizado',
    );
  }

  /// Reseta para o período padrão (este mês)
  void reset() {
    state = PeriodFilterState(
      type: PeriodType.thisMonth,
      label: 'Este mês',
    );
  }
}

/// Provider global do filtro de período
final periodFilterProvider =
    StateNotifierProvider<PeriodFilterNotifier, PeriodFilterState>((ref) {
  return PeriodFilterNotifier();
});

