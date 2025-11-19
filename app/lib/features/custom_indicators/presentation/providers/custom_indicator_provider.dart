import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/custom_indicator.dart';
import '../../data/services/custom_indicator_service.dart';
import '../../../transactions/data/services/transaction_service.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../../../core/providers/period_filter_provider.dart';

/// Estado da lista de indicadores personalizados
class CustomIndicatorsState {
  final List<CustomIndicator> indicators;
  final bool isLoading;
  final String? error;

  const CustomIndicatorsState({
    required this.indicators,
    this.isLoading = false,
    this.error,
  });

  CustomIndicatorsState copyWith({
    List<CustomIndicator>? indicators,
    bool? isLoading,
    String? error,
  }) {
    return CustomIndicatorsState(
      indicators: indicators ?? this.indicators,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Provider de indicadores personalizados
class CustomIndicatorsNotifier extends StateNotifier<CustomIndicatorsState> {
  final Ref _ref;

  CustomIndicatorsNotifier(this._ref) : super(const CustomIndicatorsState(indicators: [])) {
    load();
    // Listen to period changes to reload indicators
    _ref.listen<PeriodFilterState>(periodFilterProvider, (previous, next) {
      if (previous != next) {
        load();
      }
    });
  }

  /// Carrega todos os indicadores
  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Obter período atual
      final periodState = _ref.read(periodFilterProvider);
      final dates = periodState.dates;
      
      // Buscar indicadores da API com período para cálculo de valores
      final indicators = await CustomIndicatorService.list(
        from: dates.from.toIso8601String().split('T')[0],
        to: dates.to.toIso8601String().split('T')[0],
      );
      
      // A API já retorna os valores calculados (total_value e percentage)
      // Se algum indicador não tiver valores calculados, calcular no frontend como fallback
      final indicatorsWithValues = indicators.map((indicator) {
        if (indicator.totalValue != null && indicator.percentage != null) {
          // API já calculou, usar valores da API
          return indicator;
        } else {
          // Fallback: calcular no frontend (será feito em _calculateIndicatorValues)
          return indicator;
        }
      }).toList();
      
      // Se algum indicador não tiver valores, calcular
      final needsCalculation = indicatorsWithValues.any(
        (ind) => ind.totalValue == null || ind.percentage == null,
      );
      
      final finalIndicators = needsCalculation
          ? await _calculateIndicatorValues(indicatorsWithValues)
          : indicatorsWithValues;
      
      state = state.copyWith(
        indicators: finalIndicators,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Calcula valores e percentuais dos indicadores baseado nas transações
  Future<List<CustomIndicator>> _calculateIndicatorValues(
    List<CustomIndicator> indicators,
  ) async {
    // Obter período atual
    final periodState = _ref.read(periodFilterProvider);
    final dates = periodState.dates;

    try {
      // Buscar todas as transações do período
      final response = await TransactionService.list(
        from: dates.from.toIso8601String().split('T')[0],
        to: dates.to.toIso8601String().split('T')[0],
      );

      if (response.statusCode != 200) {
        return indicators;
      }

      final data = response.data;
      final transactionsData = data['data'] as List<dynamic>;
      final transactions = transactionsData
          .map((json) => Transaction.fromJson(json))
          .toList();

      // Calcular total de despesas
      final totalExpenses = transactions
          .where((t) => t.type == 'expense')
          .fold<double>(0.0, (sum, t) => sum + t.amount);

      // Calcular valores para cada indicador
      return indicators.map((indicator) {
        // Filtrar transações das categorias do indicador
        final indicatorTransactions = transactions.where((t) {
          return indicator.categoryIds.contains(t.categoryId) &&
              t.type == 'expense';
        }).toList();

        // Calcular valor total
        final totalValue = indicatorTransactions.fold<double>(
          0.0,
          (sum, t) => sum + t.amount,
        );

        // Calcular percentual sobre total de despesas
        final percentage = totalExpenses > 0
            ? (totalValue / totalExpenses * 100)
            : 0.0;

        return indicator.copyWith(
          totalValue: totalValue,
          percentage: percentage,
        );
      }).toList();
    } catch (e) {
      // Se houver erro, retornar indicadores sem valores calculados
      return indicators;
    }
  }

  /// Cria um novo indicador
  Future<void> create({
    required String name,
    required List<int> categoryIds,
  }) async {
    try {
      await CustomIndicatorService.create(
        name: name,
        categoryIds: categoryIds,
      );
      await load(); // Recarregar para incluir valores calculados
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Atualiza um indicador
  Future<void> update(
    int id, {
    String? name,
    List<int>? categoryIds,
  }) async {
    try {
      await CustomIndicatorService.update(
        id,
        name: name,
        categoryIds: categoryIds,
      );
      await load(); // Recarregar para atualizar valores calculados
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Deleta um indicador
  Future<void> delete(int id) async {
    try {
      await CustomIndicatorService.delete(id);
      await load();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}

/// Provider global de indicadores personalizados
final customIndicatorsProvider =
    StateNotifierProvider<CustomIndicatorsNotifier, CustomIndicatorsState>(
  (ref) => CustomIndicatorsNotifier(ref),
);

