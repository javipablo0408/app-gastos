import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_contabilidad/core/providers/providers.dart';
import 'package:app_contabilidad/data/datasources/local/database_service.dart';
import 'package:app_contabilidad/data/datasources/local/change_log_service.dart';
import 'package:app_contabilidad/core/utils/result.dart';
import 'package:app_contabilidad/domain/entities/budget.dart';
import 'package:uuid/uuid.dart';

/// Estado de la lista de presupuestos
class BudgetsState {
  final List<Budget> budgets;
  final bool isLoading;
  final String? error;

  BudgetsState({
    this.budgets = const [],
    this.isLoading = false,
    this.error,
  });

  BudgetsState copyWith({
    List<Budget>? budgets,
    bool? isLoading,
    String? error,
  }) {
    return BudgetsState(
      budgets: budgets ?? this.budgets,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// ViewModel para gestionar presupuestos
class BudgetsViewModel extends StateNotifier<BudgetsState> {
  final DatabaseService _databaseService;
  final ChangeLogService _changeLogService;
  final Uuid _uuid = const Uuid();

  BudgetsViewModel(this._databaseService, this._changeLogService)
      : super(BudgetsState()) {
    // Cargar datos iniciales
    loadBudgets();
  }

  /// Carga todos los presupuestos
  Future<void> loadBudgets({bool forceRefresh = false}) async {
    // Si ya hay datos y no es un refresh forzado, no cargar
    if (!forceRefresh && state.budgets.isNotEmpty && !state.isLoading) {
      return;
    }
    
    // Si ya está cargando, no iniciar otra carga
    if (state.isLoading) {
      return;
    }
    
    state = state.copyWith(isLoading: true, error: null);

    final result = await _databaseService.getAllBudgets();

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
      },
      (budgets) {
        state = state.copyWith(
          budgets: budgets,
          isLoading: false,
        );
      },
    );
  }

  /// Crea un nuevo presupuesto
  Future<Result<Budget>> createBudget({
    required String categoryId,
    required double amount,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final budget = Budget(
      id: _uuid.v4(),
      categoryId: categoryId,
      amount: amount,
      startDate: startDate,
      endDate: endDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final result = await _databaseService.createBudget(budget);

    result.fold(
      (failure) {},
      (createdBudget) async {
        // Registrar en change log
        await _changeLogService.logCreate(
          entityType: 'budget',
          entityId: createdBudget.id,
        );
        // Recargar lista
        await loadBudgets(forceRefresh: true);
      },
    );

    return result;
  }

  /// Actualiza un presupuesto
  Future<Result<Budget>> updateBudget(Budget budget) async {
    final updated = budget.copyWith(updatedAt: DateTime.now());
    final result = await _databaseService.updateBudget(updated);

    result.fold(
      (failure) {},
      (updatedBudget) async {
        // Registrar en change log
        await _changeLogService.logUpdate(
          entityType: 'budget',
          entityId: updatedBudget.id,
        );
        // Recargar lista
        await loadBudgets(forceRefresh: true);
      },
    );

    return result;
  }

  /// Elimina un presupuesto
  Future<Result<void>> deleteBudget(String id) async {
    final result = await _databaseService.deleteBudget(id);

    result.fold(
      (failure) {},
      (_) async {
        // Registrar en change log
        await _changeLogService.logDelete(
          entityType: 'budget',
          entityId: id,
        );
        // Recargar lista
        await loadBudgets(forceRefresh: true);
      },
    );

    return result;
  }
}

/// Provider del ViewModel de presupuestos
final budgetsViewModelProvider =
    StateNotifierProvider.autoDispose<BudgetsViewModel, BudgetsState>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  final changeLogService = ref.watch(changeLogServiceProvider);
  final viewModel = BudgetsViewModel(databaseService, changeLogService);
  // Mantener el provider vivo para evitar recargas innecesarias
  ref.keepAlive();
  return viewModel;
});


