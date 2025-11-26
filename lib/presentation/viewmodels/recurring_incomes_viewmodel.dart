import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_contabilidad/core/providers/providers.dart';
import 'package:app_contabilidad/data/services/recurring_incomes_service.dart';
import 'package:app_contabilidad/core/utils/result.dart';
import 'package:app_contabilidad/core/utils/logger.dart';
import 'package:app_contabilidad/core/errors/failures.dart';
import 'package:app_contabilidad/domain/entities/recurring_income.dart';
import 'package:app_contabilidad/domain/entities/income.dart';
import 'package:app_contabilidad/domain/entities/recurring_expense.dart';
import 'package:app_contabilidad/presentation/viewmodels/dashboard_viewmodel.dart';
import 'package:app_contabilidad/presentation/viewmodels/incomes_viewmodel.dart';
import 'package:uuid/uuid.dart';
import 'package:dartz/dartz.dart';

/// Estado de ingresos recurrentes
class RecurringIncomesState {
  final List<RecurringIncome> recurringIncomes;
  final bool isLoading;
  final String? error;

  RecurringIncomesState({
    this.recurringIncomes = const [],
    this.isLoading = false,
    this.error,
  });

  RecurringIncomesState copyWith({
    List<RecurringIncome>? recurringIncomes,
    bool? isLoading,
    String? error,
  }) {
    return RecurringIncomesState(
      recurringIncomes: recurringIncomes ?? this.recurringIncomes,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// ViewModel para gestionar ingresos recurrentes
class RecurringIncomesViewModel extends StateNotifier<RecurringIncomesState> {
  final RecurringIncomesService _service;
  final Ref _ref;
  final Uuid _uuid = const Uuid();

  RecurringIncomesViewModel(this._service, this._ref) : super(RecurringIncomesState()) {
    loadRecurringIncomes();
  }

  /// Carga todos los ingresos recurrentes
  Future<void> loadRecurringIncomes({bool forceRefresh = false}) async {
    if (!forceRefresh && state.recurringIncomes.isNotEmpty && !state.isLoading) {
      return;
    }
    
    if (state.isLoading && !forceRefresh) {
      return;
    }
    
    if (forceRefresh && state.isLoading) {
      await Future.delayed(const Duration(milliseconds: 300));
    }
    
    state = state.copyWith(isLoading: true, error: null);

    final result = await _service.getAllRecurringIncomes();

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
      },
      (recurringIncomes) {
        state = state.copyWith(
          recurringIncomes: recurringIncomes,
          isLoading: false,
        );
      },
    );
  }

  /// Crea un nuevo ingreso recurrente
  Future<Result<RecurringIncome>> createRecurringIncome({
    required String description,
    required double amount,
    required String categoryId,
    required RecurrenceType recurrenceType,
    required int recurrenceValue,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    final recurringIncome = RecurringIncome(
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

    final result = await _service.createRecurringIncome(recurringIncome);

    result.fold(
      (failure) {},
      (created) {
        final currentRecurring = List<RecurringIncome>.from(state.recurringIncomes);
        currentRecurring.insert(0, created);
        state = state.copyWith(
          recurringIncomes: currentRecurring,
          isLoading: false,
        );
      },
    );

    return result;
  }

  /// Actualiza un ingreso recurrente
  Future<Result<RecurringIncome>> updateRecurringIncome(RecurringIncome recurringIncome) async {
    final updated = recurringIncome.copyWith(updatedAt: DateTime.now());
    final result = await _service.updateRecurringIncome(updated);

    result.fold(
      (failure) {},
      (updatedIncome) {
        final currentRecurring = List<RecurringIncome>.from(state.recurringIncomes);
        final index = currentRecurring.indexWhere((r) => r.id == updatedIncome.id);
        if (index != -1) {
          currentRecurring[index] = updatedIncome;
          state = state.copyWith(
            recurringIncomes: currentRecurring,
            isLoading: false,
          );
        } else {
          loadRecurringIncomes(forceRefresh: true);
        }
      },
    );

    return result;
  }

  /// Elimina un ingreso recurrente
  Future<Result<void>> deleteRecurringIncome(String id) async {
    final result = await _service.deleteRecurringIncome(id);

    result.fold(
      (failure) {},
      (_) {
        final currentRecurring = List<RecurringIncome>.from(state.recurringIncomes);
        currentRecurring.removeWhere((r) => r.id == id);
        state = state.copyWith(
          recurringIncomes: currentRecurring,
          isLoading: false,
        );
      },
    );

    return result;
  }

  /// Ejecuta los ingresos recurrentes pendientes
  Future<Result<List<Income>>> executeDueRecurringIncomes() async {
    appLogger.d('=== INICIANDO EJECUCIÓN DE INGRESOS RECURRENTES ===');
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final result = await _service.executeDueRecurringIncomes();
      
      result.fold(
        (failure) {
          state = state.copyWith(
            isLoading: false,
            error: failure.message,
          );
        },
        (createdIncomes) {
          final currentRecurring = List<RecurringIncome>.from(state.recurringIncomes);
          final now = DateTime.now();
          
          for (final income in createdIncomes) {
            final recurringIndex = currentRecurring.indexWhere((r) => 
              r.categoryId == income.categoryId && 
              r.amount == income.amount &&
              r.description == income.description
            );
            
            if (recurringIndex != -1) {
              currentRecurring[recurringIndex] = currentRecurring[recurringIndex].copyWith(
                lastExecuted: now,
                updatedAt: now,
              );
            }
          }
          
          state = state.copyWith(
            recurringIncomes: currentRecurring,
            isLoading: false,
          );
          
          final incomesViewModel = _ref.read(incomesViewModelProvider.notifier);
          incomesViewModel.loadIncomes(forceRefresh: true).then((_) {}).catchError((e) {
            appLogger.e('Error loading incomes', error: e);
          });
          
          final dashboardViewModel = _ref.read(dashboardViewModelProvider.notifier);
          for (final income in createdIncomes) {
            dashboardViewModel.addIncomeToDashboard(income).then((_) {}).catchError((e) {
              appLogger.e('Error adding income to dashboard', error: e);
            });
          }
          
          dashboardViewModel.updateOnDataChange().then((_) {}).catchError((e) {
            appLogger.e('Error updating dashboard', error: e);
          });
        },
      );
      
      return result;
    } catch (e, stackTrace) {
      appLogger.e('Error executing recurring incomes', error: e, stackTrace: stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: 'Error inesperado: ${e.toString()}',
      );
      return Left(UnknownFailure('Error al ejecutar ingresos recurrentes: ${e.toString()}'));
    }
  }
}

/// Provider del ViewModel de ingresos recurrentes
final recurringIncomesViewModelProvider =
    StateNotifierProvider.autoDispose<RecurringIncomesViewModel, RecurringIncomesState>((ref) {
  ref.keepAlive();
  final service = ref.watch(recurringIncomesServiceProvider);
  return RecurringIncomesViewModel(service, ref);
});

