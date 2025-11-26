import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_contabilidad/core/providers/providers.dart';
import 'package:app_contabilidad/data/services/financial_projection_service.dart';

/// Estado de proyecciones financieras
class FinancialProjectionState {
  final FinancialProjection? projection;
  final ScenarioResult? scenarioResult;
  final bool isLoading;
  final String? error;
  final DateTime? startDate;
  final DateTime? endDate;

  FinancialProjectionState({
    this.projection,
    this.scenarioResult,
    this.isLoading = false,
    this.error,
    this.startDate,
    this.endDate,
  });

  FinancialProjectionState copyWith({
    FinancialProjection? projection,
    ScenarioResult? scenarioResult,
    bool? isLoading,
    String? error,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return FinancialProjectionState(
      projection: projection ?? this.projection,
      scenarioResult: scenarioResult ?? this.scenarioResult,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

/// ViewModel para proyecciones financieras
class FinancialProjectionViewModel extends StateNotifier<FinancialProjectionState> {
  final FinancialProjectionService _service;

  FinancialProjectionViewModel(this._service) : super(FinancialProjectionState());

  /// Calcula proyección futura
  Future<void> calculateProjection({
    required DateTime startDate,
    required DateTime endDate,
    int monthsToProject = 6,
  }) async {
    try {
      if (startDate.isAfter(endDate)) {
        state = state.copyWith(
          isLoading: false,
          error: 'La fecha de inicio debe ser anterior a la fecha de fin',
        );
        return;
      }

      state = state.copyWith(isLoading: true, error: null, startDate: startDate, endDate: endDate);

      final result = await _service.projectFutureBalance(
        startDate: startDate,
        endDate: endDate,
        monthsToProject: monthsToProject,
      );

      result.fold(
        (failure) {
          state = state.copyWith(
            isLoading: false,
            error: failure.message,
            projection: null, // Limpiar proyección anterior en caso de error
          );
        },
        (projection) {
          state = state.copyWith(
            projection: projection,
            isLoading: false,
            error: null,
          );
        },
      );
    } catch (e, stackTrace) {
      // Log del error completo para debugging
      print('Error en calculateProjection: $e');
      print('Stack trace: $stackTrace');
      
      state = state.copyWith(
        isLoading: false,
        error: 'Error inesperado al calcular proyección: ${e.toString()}',
        projection: null,
      );
    }
  }

  /// Simula un escenario
  Future<void> simulateScenario({
    required DateTime startDate,
    required DateTime endDate,
    double? additionalExpense,
    double? additionalIncome,
    double? expenseReduction,
  }) async {
    try {
      if (startDate.isAfter(endDate)) {
        state = state.copyWith(
          isLoading: false,
          error: 'La fecha de inicio debe ser anterior a la fecha de fin',
        );
        return;
      }

      state = state.copyWith(isLoading: true, error: null);

      final result = await _service.simulateScenario(
        startDate: startDate,
        endDate: endDate,
        additionalExpense: additionalExpense,
        additionalIncome: additionalIncome,
        expenseReduction: expenseReduction,
      );

      result.fold(
        (failure) {
          state = state.copyWith(
            isLoading: false,
            error: failure.message,
          );
        },
        (scenarioResult) {
          state = state.copyWith(
            scenarioResult: scenarioResult,
            isLoading: false,
            error: null,
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error inesperado al simular escenario: ${e.toString()}',
      );
    }
  }
}

/// Provider del ViewModel de proyecciones
final financialProjectionViewModelProvider =
    StateNotifierProvider.autoDispose<FinancialProjectionViewModel, FinancialProjectionState>((ref) {
  ref.keepAlive();
  final service = ref.watch(financialProjectionServiceProvider);
  return FinancialProjectionViewModel(service);
});

