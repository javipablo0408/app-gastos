import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_contabilidad/core/providers/providers.dart';
import 'package:app_contabilidad/core/utils/result.dart';
import 'package:app_contabilidad/data/services/shared_expenses_service.dart';
import 'package:app_contabilidad/domain/entities/shared_expense.dart';
import 'package:app_contabilidad/domain/entities/expense.dart';

/// Estado de gastos compartidos
class SharedExpensesState {
  final List<SharedExpense> sharedExpenses;
  final bool isLoading;
  final String? error;

  SharedExpensesState({
    this.sharedExpenses = const [],
    this.isLoading = false,
    this.error,
  });

  SharedExpensesState copyWith({
    List<SharedExpense>? sharedExpenses,
    bool? isLoading,
    String? error,
  }) {
    return SharedExpensesState(
      sharedExpenses: sharedExpenses ?? this.sharedExpenses,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// ViewModel para gastos compartidos
class SharedExpensesViewModel extends StateNotifier<SharedExpensesState> {
  final SharedExpensesService _service;

  SharedExpensesViewModel(this._service) : super(SharedExpensesState());

  /// Carga todos los gastos compartidos
  Future<void> loadSharedExpenses({bool forceRefresh = false}) async {
    if (state.isLoading && !forceRefresh) return;

    state = state.copyWith(isLoading: true, error: null);

    final result = await _service.getAllSharedExpenses();

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
      },
      (sharedExpenses) {
        state = state.copyWith(
          sharedExpenses: sharedExpenses,
          isLoading: false,
        );
      },
    );
  }

  /// Crea un gasto compartido
  Future<Result<SharedExpense>> createSharedExpense({
    required Expense expense,
    required List<Participant> participants,
    required SplitType splitType,
  }) async {
    final result = await _service.createSharedExpense(
      expense: expense,
      participants: participants,
      splitType: splitType,
    );

    result.fold(
      (failure) {},
      (created) {
        // Recargar lista
        loadSharedExpenses(forceRefresh: true);
      },
    );

    return result;
  }

  /// Actualiza un gasto compartido
  Future<Result<SharedExpense>> updateSharedExpense(SharedExpense sharedExpense) async {
    final result = await _service.updateSharedExpense(sharedExpense);

    result.fold(
      (failure) {},
      (updated) {
        // Recargar lista
        loadSharedExpenses(forceRefresh: true);
      },
    );

    return result;
  }

  /// Elimina un gasto compartido
  Future<Result<void>> deleteSharedExpense(String id) async {
    final result = await _service.deleteSharedExpense(id);

    result.fold(
      (failure) {},
      (_) {
        // Recargar lista
        loadSharedExpenses(forceRefresh: true);
      },
    );

    return result;
  }
}

/// Provider del ViewModel de gastos compartidos
final sharedExpensesViewModelProvider =
    StateNotifierProvider.autoDispose<SharedExpensesViewModel, SharedExpensesState>((ref) {
  final service = ref.watch(sharedExpensesServiceProvider);
  return SharedExpensesViewModel(service);
});

