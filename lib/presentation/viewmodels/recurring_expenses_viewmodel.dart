import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_contabilidad/core/providers/providers.dart';
import 'package:app_contabilidad/data/services/recurring_expenses_service.dart';
import 'package:app_contabilidad/core/utils/result.dart';
import 'package:app_contabilidad/core/utils/logger.dart';
import 'package:app_contabilidad/core/errors/failures.dart';
import 'package:app_contabilidad/domain/entities/recurring_expense.dart';
import 'package:app_contabilidad/domain/entities/expense.dart';
import 'package:app_contabilidad/presentation/viewmodels/dashboard_viewmodel.dart';
import 'package:app_contabilidad/presentation/viewmodels/expenses_viewmodel.dart';
import 'package:uuid/uuid.dart';
import 'package:dartz/dartz.dart';

/// Estado de gastos recurrentes
class RecurringExpensesState {
  final List<RecurringExpense> recurringExpenses;
  final bool isLoading;
  final String? error;

  RecurringExpensesState({
    this.recurringExpenses = const [],
    this.isLoading = false,
    this.error,
  });

  RecurringExpensesState copyWith({
    List<RecurringExpense>? recurringExpenses,
    bool? isLoading,
    String? error,
  }) {
    return RecurringExpensesState(
      recurringExpenses: recurringExpenses ?? this.recurringExpenses,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// ViewModel para gestionar gastos recurrentes
class RecurringExpensesViewModel extends StateNotifier<RecurringExpensesState> {
  final RecurringExpensesService _service;
  final Ref _ref;
  final Uuid _uuid = const Uuid();

  RecurringExpensesViewModel(this._service, this._ref) : super(RecurringExpensesState()) {
    loadRecurringExpenses();
  }

  /// Carga todos los gastos recurrentes
  Future<void> loadRecurringExpenses({bool forceRefresh = false}) async {
    if (!forceRefresh && state.recurringExpenses.isNotEmpty && !state.isLoading) {
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

    final result = await _service.getAllRecurringExpenses();

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
      },
      (recurringExpenses) {
        state = state.copyWith(
          recurringExpenses: recurringExpenses,
          isLoading: false,
        );
      },
    );
  }

  /// Crea un nuevo gasto recurrente
  Future<Result<RecurringExpense>> createRecurringExpense({
    required String description,
    required double amount,
    required String categoryId,
    required RecurrenceType recurrenceType,
    required int recurrenceValue,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    final recurringExpense = RecurringExpense(
      id: _uuid.v4(),
      description: description,
      amount: amount,
      categoryId: categoryId,
      recurrenceType: recurrenceType,
      recurrenceValue: recurrenceValue,
      startDate: startDate,
      endDate: endDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final result = await _service.createRecurringExpense(recurringExpense);

    result.fold(
      (failure) {},
      (created) {
        // Actualizar estado localmente sin recargar toda la lista
        final currentRecurring = List<RecurringExpense>.from(state.recurringExpenses);
        currentRecurring.insert(0, created);
        state = state.copyWith(
          recurringExpenses: currentRecurring,
          isLoading: false,
        );
      },
    );

    return result;
  }

  /// Actualiza un gasto recurrente
  Future<Result<RecurringExpense>> updateRecurringExpense(RecurringExpense recurringExpense) async {
    final updated = recurringExpense.copyWith(updatedAt: DateTime.now());
    final result = await _service.updateRecurringExpense(updated);

    result.fold(
      (failure) {},
      (updatedExpense) {
        // Actualizar estado localmente
        final currentRecurring = List<RecurringExpense>.from(state.recurringExpenses);
        final index = currentRecurring.indexWhere((r) => r.id == updatedExpense.id);
        if (index != -1) {
          currentRecurring[index] = updatedExpense;
          state = state.copyWith(
            recurringExpenses: currentRecurring,
            isLoading: false,
          );
        } else {
          // Si no está en la lista, recargar
          loadRecurringExpenses(forceRefresh: true);
        }
      },
    );

    return result;
  }

  /// Elimina un gasto recurrente
  Future<Result<void>> deleteRecurringExpense(String id) async {
    final result = await _service.deleteRecurringExpense(id);

    result.fold(
      (failure) {},
      (_) {
        // Actualizar estado localmente
        final currentRecurring = List<RecurringExpense>.from(state.recurringExpenses);
        currentRecurring.removeWhere((r) => r.id == id);
        state = state.copyWith(
          recurringExpenses: currentRecurring,
          isLoading: false,
        );
      },
    );

    return result;
  }

  /// Ejecuta los gastos recurrentes pendientes
  Future<Result<List<Expense>>> executeDueRecurringExpenses() async {
    appLogger.d('=== INICIANDO EJECUCIÓN DE GASTOS RECURRENTES ===');
    appLogger.d('Total de gastos recurrentes en estado: ${state.recurringExpenses.length}');
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      appLogger.d('Llamando a _service.executeDueRecurringExpenses()');
      final result = await _service.executeDueRecurringExpenses();
      appLogger.d('Resultado recibido: isFailure=${result.isFailure}');
      
      result.fold(
        (failure) {
          appLogger.e('Error en executeDueRecurringExpenses: ${failure.message}');
          state = state.copyWith(
            isLoading: false,
            error: failure.message,
          );
        },
        (createdExpenses) {
          appLogger.d('Gastos creados: ${createdExpenses.length}');
          
          // Actualizar estado localmente de los gastos recurrentes ejecutados
          final currentRecurring = List<RecurringExpense>.from(state.recurringExpenses);
          final now = DateTime.now();
          
          for (final expense in createdExpenses) {
            appLogger.d('Buscando gasto recurrente para: ${expense.description}, categoría: ${expense.categoryId}, monto: ${expense.amount}');
            
            // Encontrar el gasto recurrente que generó este gasto
            final recurringIndex = currentRecurring.indexWhere((r) => 
              r.categoryId == expense.categoryId && 
              r.amount == expense.amount &&
              r.description == expense.description
            );
            
            if (recurringIndex != -1) {
              appLogger.d('Gasto recurrente encontrado en índice $recurringIndex');
              // Actualizar lastExecuted del gasto recurrente
              currentRecurring[recurringIndex] = currentRecurring[recurringIndex].copyWith(
                lastExecuted: now,
                updatedAt: now,
              );
            } else {
              appLogger.w('No se encontró el gasto recurrente correspondiente');
            }
          }
          
          // Actualizar estado y quitar loading inmediatamente
          appLogger.d('Actualizando estado y quitando loading');
          state = state.copyWith(
            recurringExpenses: currentRecurring,
            isLoading: false,
          );
          
          // Notificar al ViewModel de gastos (sin bloquear)
          appLogger.d('Notificando a ExpensesViewModel');
          final expensesViewModel = _ref.read(expensesViewModelProvider.notifier);
          expensesViewModel.loadExpenses(forceRefresh: true).then((_) {
            appLogger.d('ExpensesViewModel actualizado');
          }).catchError((e) {
            appLogger.e('Error loading expenses', error: e);
          });
          
          // Actualizar dashboard (sin bloquear)
          appLogger.d('Actualizando dashboard con ${createdExpenses.length} gastos');
          final dashboardViewModel = _ref.read(dashboardViewModelProvider.notifier);
          for (final expense in createdExpenses) {
            dashboardViewModel.addExpenseToDashboard(expense).then((_) {
              appLogger.d('Gasto agregado al dashboard: ${expense.description}');
            }).catchError((e) {
              appLogger.e('Error adding expense to dashboard', error: e);
            });
          }
          
          // Notificar al dashboard para que se actualice completamente (sin bloquear)
          dashboardViewModel.updateOnDataChange().then((_) {
            appLogger.d('Dashboard actualizado completamente');
          }).catchError((e) {
            appLogger.e('Error updating dashboard', error: e);
          });
          
          appLogger.d('=== FIN EJECUCIÓN DE GASTOS RECURRENTES ===');
        },
      );
      
      return result;
    } catch (e, stackTrace) {
      appLogger.e('Error executing recurring expenses', error: e, stackTrace: stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: 'Error inesperado: ${e.toString()}',
      );
      return Left(UnknownFailure('Error al ejecutar gastos recurrentes: ${e.toString()}'));
    }
  }
}

/// Provider del ViewModel de gastos recurrentes
final recurringExpensesViewModelProvider =
    StateNotifierProvider.autoDispose<RecurringExpensesViewModel, RecurringExpensesState>((ref) {
  ref.keepAlive();
  final service = ref.watch(recurringExpensesServiceProvider);
  return RecurringExpensesViewModel(service, ref);
});

