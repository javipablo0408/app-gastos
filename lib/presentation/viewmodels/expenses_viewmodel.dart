import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_contabilidad/core/providers/providers.dart';
import 'package:app_contabilidad/data/datasources/local/database_service.dart';
import 'package:app_contabilidad/data/datasources/local/change_log_service.dart';
import 'package:app_contabilidad/core/utils/result.dart';
import 'package:app_contabilidad/core/utils/logger.dart';
import 'package:app_contabilidad/domain/entities/expense.dart';
import 'package:uuid/uuid.dart';

/// Estado de la lista de gastos
class ExpensesState {
  final List<Expense> expenses;
  final bool isLoading;
  final String? error;

  ExpensesState({
    this.expenses = const [],
    this.isLoading = false,
    this.error,
  });

  ExpensesState copyWith({
    List<Expense>? expenses,
    bool? isLoading,
    String? error,
  }) {
    return ExpensesState(
      expenses: expenses ?? this.expenses,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// ViewModel para gestionar gastos
class ExpensesViewModel extends StateNotifier<ExpensesState> {
  final DatabaseService _databaseService;
  final ChangeLogService _changeLogService;
  final Uuid _uuid = const Uuid();

  ExpensesViewModel(this._databaseService, this._changeLogService)
      : super(ExpensesState()) {
    // Cargar datos iniciales
    loadExpenses();
  }

  /// Carga todos los gastos
  Future<void> loadExpenses({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    bool forceRefresh = false,
  }) async {
    // Si ya hay datos y no es un refresh forzado, no cargar
    if (!forceRefresh && state.expenses.isNotEmpty && !state.isLoading) {
      return;
    }
    
    // Si ya está cargando y no es un refresh forzado, no iniciar otra carga
    if (state.isLoading && !forceRefresh) {
      return;
    }
    
    // Si es un refresh forzado y está cargando, esperar un poco
    if (forceRefresh && state.isLoading) {
      await Future.delayed(const Duration(milliseconds: 300));
    }
    
    state = state.copyWith(isLoading: true, error: null);

    final result = await _databaseService.getAllExpenses(
      startDate: startDate,
      endDate: endDate,
      categoryId: categoryId,
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
      },
      (expenses) {
        state = state.copyWith(
          expenses: expenses,
          isLoading: false,
        );
      },
    );
  }

  /// Crea un nuevo gasto
  Future<Result<Expense>> createExpense({
    required double amount,
    required String description,
    required String categoryId,
    required DateTime date,
    String? receiptImagePath,
    String? billFilePath,
  }) async {
    final expense = Expense(
      id: _uuid.v4(),
      amount: amount,
      description: description,
      categoryId: categoryId,
      date: date,
      receiptImagePath: receiptImagePath,
      billFilePath: billFilePath,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final result = await _databaseService.createExpense(expense);

    result.fold(
      (failure) {},
      (createdExpense) async {
        // Registrar en change log (no esperar si falla)
        _changeLogService.logCreate(
          entityType: 'expense',
          entityId: createdExpense.id,
        ).then((_) {}).catchError((e) {
          appLogger.e('Error logging create', error: e);
        });
        
        // Actualizar estado localmente sin recargar toda la lista
        final currentExpenses = List<Expense>.from(state.expenses);
        currentExpenses.insert(0, createdExpense);
        state = state.copyWith(
          expenses: currentExpenses,
          isLoading: false,
        );
      },
    );

    return result;
  }

  /// Actualiza un gasto
  Future<Result<Expense>> updateExpense(Expense expense) async {
    final updated = expense.copyWith(updatedAt: DateTime.now());
    final result = await _databaseService.updateExpense(updated);

    result.fold(
      (failure) {},
      (updatedExpense) async {
        // Registrar en change log (no esperar si falla)
        _changeLogService.logUpdate(
          entityType: 'expense',
          entityId: updatedExpense.id,
        ).then((_) {}).catchError((e) {
          appLogger.e('Error logging update', error: e);
        });
        
        // Actualizar estado localmente
        final currentExpenses = List<Expense>.from(state.expenses);
        final index = currentExpenses.indexWhere((e) => e.id == updatedExpense.id);
        if (index != -1) {
          currentExpenses[index] = updatedExpense;
          state = state.copyWith(
            expenses: currentExpenses,
            isLoading: false,
          );
        } else {
          // Si no está en la lista, recargar
          await loadExpenses(forceRefresh: true);
        }
      },
    );

    return result;
  }

  /// Elimina un gasto
  Future<Result<void>> deleteExpense(String id) async {
    final result = await _databaseService.deleteExpense(id);

    result.fold(
      (failure) {},
      (_) async {
        // Registrar en change log (no esperar si falla)
        _changeLogService.logDelete(
          entityType: 'expense',
          entityId: id,
        ).then((_) {}).catchError((e) {
          appLogger.e('Error logging delete', error: e);
        });
        
        // Actualizar estado localmente
        final currentExpenses = List<Expense>.from(state.expenses);
        currentExpenses.removeWhere((e) => e.id == id);
        state = state.copyWith(
          expenses: currentExpenses,
          isLoading: false,
        );
      },
    );

    return result;
  }
}

/// Provider del ViewModel de gastos
final expensesViewModelProvider =
    StateNotifierProvider.autoDispose<ExpensesViewModel, ExpensesState>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  final changeLogService = ref.watch(changeLogServiceProvider);
  final viewModel = ExpensesViewModel(databaseService, changeLogService);
  // Mantener el provider vivo para evitar recargas innecesarias
  ref.keepAlive();
  return viewModel;
});

