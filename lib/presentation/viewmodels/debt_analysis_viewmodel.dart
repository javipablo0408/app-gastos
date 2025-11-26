import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_contabilidad/core/providers/providers.dart';
import 'package:app_contabilidad/data/services/debt_analysis_service.dart';
import 'package:app_contabilidad/core/utils/result.dart';
import 'package:app_contabilidad/data/services/debt_analysis_service.dart' as debt;

/// Estado de análisis de deudas
class DebtAnalysisState {
  final Map<String, double>? allDebts;
  final debt.DebtSummary? debtSummary;
  final String? selectedParticipantId;
  final bool isLoading;
  final String? error;

  DebtAnalysisState({
    this.allDebts,
    this.debtSummary,
    this.selectedParticipantId,
    this.isLoading = false,
    this.error,
  });

  DebtAnalysisState copyWith({
    Map<String, double>? allDebts,
    debt.DebtSummary? debtSummary,
    String? selectedParticipantId,
    bool? isLoading,
    String? error,
  }) {
    return DebtAnalysisState(
      allDebts: allDebts ?? this.allDebts,
      debtSummary: debtSummary ?? this.debtSummary,
      selectedParticipantId: selectedParticipantId ?? this.selectedParticipantId,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// ViewModel para análisis de deudas
class DebtAnalysisViewModel extends StateNotifier<DebtAnalysisState> {
  final DebtAnalysisService _service;

  DebtAnalysisViewModel(this._service) : super(DebtAnalysisState()) {
    loadAllDebts();
  }

  /// Carga todas las deudas
  Future<void> loadAllDebts() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _service.getAllDebts();

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
      },
      (debts) {
        state = state.copyWith(
          allDebts: debts,
          isLoading: false,
        );
      },
    );
  }

  /// Obtiene resumen de deudas de un participante
  Future<void> loadDebtSummary(String participantId) async {
    state = state.copyWith(isLoading: true, error: null, selectedParticipantId: participantId);

    final result = await _service.getDebtSummary(participantId);

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
      },
      (summary) {
        state = state.copyWith(
          debtSummary: summary,
          isLoading: false,
        );
      },
    );
  }
}

/// Provider del ViewModel de análisis de deudas
final debtAnalysisViewModelProvider =
    StateNotifierProvider.autoDispose<DebtAnalysisViewModel, DebtAnalysisState>((ref) {
  ref.keepAlive();
  final service = ref.watch(debtAnalysisServiceProvider);
  return DebtAnalysisViewModel(service);
});

