import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_contabilidad/core/providers/providers.dart';
import 'package:app_contabilidad/data/services/period_comparison_service.dart';

/// Estado de comparación de períodos
class PeriodComparisonState {
  final PeriodComparison? comparison;
  final bool isLoading;
  final String? error;
  final DateTime? period1Start;
  final DateTime? period1End;
  final DateTime? period2Start;
  final DateTime? period2End;

  PeriodComparisonState({
    this.comparison,
    this.isLoading = false,
    this.error,
    this.period1Start,
    this.period1End,
    this.period2Start,
    this.period2End,
  });

  PeriodComparisonState copyWith({
    PeriodComparison? comparison,
    bool? isLoading,
    String? error,
    DateTime? period1Start,
    DateTime? period1End,
    DateTime? period2Start,
    DateTime? period2End,
  }) {
    return PeriodComparisonState(
      comparison: comparison ?? this.comparison,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      period1Start: period1Start ?? this.period1Start,
      period1End: period1End ?? this.period1End,
      period2Start: period2Start ?? this.period2Start,
      period2End: period2End ?? this.period2End,
    );
  }
}

/// ViewModel para comparación de períodos
class PeriodComparisonViewModel extends StateNotifier<PeriodComparisonState> {
  final PeriodComparisonService _service;

  PeriodComparisonViewModel(this._service) : super(PeriodComparisonState());

  /// Compara dos períodos
  Future<void> comparePeriods({
    required DateTime period1Start,
    required DateTime period1End,
    required DateTime period2Start,
    required DateTime period2End,
  }) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      period1Start: period1Start,
      period1End: period1End,
      period2Start: period2Start,
      period2End: period2End,
    );

    final result = await _service.comparePeriods(
      period1Start: period1Start,
      period1End: period1End,
      period2Start: period2Start,
      period2End: period2End,
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
      },
      (comparison) {
        state = state.copyWith(
          comparison: comparison,
          isLoading: false,
        );
      },
    );
  }
}

/// Provider del ViewModel de comparación
final periodComparisonViewModelProvider =
    StateNotifierProvider.autoDispose<PeriodComparisonViewModel, PeriodComparisonState>((ref) {
  ref.keepAlive();
  final service = ref.watch(periodComparisonServiceProvider);
  return PeriodComparisonViewModel(service);
});

