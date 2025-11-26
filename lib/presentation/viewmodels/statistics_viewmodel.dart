import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_contabilidad/core/providers/providers.dart';
import 'package:app_contabilidad/data/services/statistics_service.dart';
import 'package:app_contabilidad/core/utils/result.dart';

/// Estado de estadísticas
class StatisticsState {
  final FinancialStatistics? statistics;
  final bool isLoading;
  final String? error;
  final DateTime startDate;
  final DateTime endDate;

  StatisticsState({
    this.statistics,
    this.isLoading = false,
    this.error,
    DateTime? startDate,
    DateTime? endDate,
  })  : startDate = startDate ?? DateTime(DateTime.now().year, DateTime.now().month, 1),
        endDate = endDate ?? DateTime.now();

  StatisticsState copyWith({
    FinancialStatistics? statistics,
    bool? isLoading,
    String? error,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return StatisticsState(
      statistics: statistics ?? this.statistics,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

/// ViewModel de estadísticas
class StatisticsViewModel extends StateNotifier<StatisticsState> {
  final StatisticsService _statisticsService;

  StatisticsViewModel(this._statisticsService) : super(StatisticsState()) {
    loadStatistics();
  }

  Future<void> loadStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final effectiveStartDate = startDate ?? state.startDate;
    final effectiveEndDate = endDate ?? state.endDate;

    state = state.copyWith(
      isLoading: true,
      error: null,
      startDate: effectiveStartDate,
      endDate: effectiveEndDate,
    );

    final result = await _statisticsService.calculateStatistics(
      startDate: effectiveStartDate,
      endDate: effectiveEndDate,
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.toString(),
        );
      },
      (statistics) {
        state = state.copyWith(
          statistics: statistics,
          isLoading: false,
        );
      },
    );
  }
}

/// Provider del ViewModel de estadísticas
final statisticsViewModelProvider =
    StateNotifierProvider.autoDispose<StatisticsViewModel, StatisticsState>((ref) {
  ref.keepAlive();
  final statisticsService = ref.watch(statisticsServiceProvider);
  return StatisticsViewModel(statisticsService);
});

