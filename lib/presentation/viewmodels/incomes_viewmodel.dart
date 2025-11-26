import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_contabilidad/core/providers/providers.dart';
import 'package:app_contabilidad/data/datasources/local/database_service.dart';
import 'package:app_contabilidad/data/datasources/local/change_log_service.dart';
import 'package:app_contabilidad/core/utils/result.dart';
import 'package:app_contabilidad/core/utils/logger.dart';
import 'package:app_contabilidad/domain/entities/income.dart';
import 'package:uuid/uuid.dart';

/// Estado de la lista de ingresos
class IncomesState {
  final List<Income> incomes;
  final bool isLoading;
  final String? error;

  IncomesState({
    this.incomes = const [],
    this.isLoading = false,
    this.error,
  });

  IncomesState copyWith({
    List<Income>? incomes,
    bool? isLoading,
    String? error,
  }) {
    return IncomesState(
      incomes: incomes ?? this.incomes,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// ViewModel para gestionar ingresos
class IncomesViewModel extends StateNotifier<IncomesState> {
  final DatabaseService _databaseService;
  final ChangeLogService _changeLogService;
  final Uuid _uuid = const Uuid();

  IncomesViewModel(this._databaseService, this._changeLogService)
      : super(IncomesState()) {
    // Cargar datos iniciales
    loadIncomes();
  }

  /// Carga todos los ingresos
  Future<void> loadIncomes({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    bool forceRefresh = false,
  }) async {
    // Si ya hay datos y no es un refresh forzado, no cargar
    if (!forceRefresh && state.incomes.isNotEmpty && !state.isLoading) {
      return;
    }
    
    // Si ya está cargando, no iniciar otra carga
    if (state.isLoading) {
      return;
    }
    
    state = state.copyWith(isLoading: true, error: null);

    final result = await _databaseService.getAllIncomes(
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
      (incomes) {
        state = state.copyWith(
          incomes: incomes,
          isLoading: false,
        );
      },
    );
  }

  /// Crea un nuevo ingreso
  Future<Result<Income>> createIncome({
    required double amount,
    required String description,
    required String categoryId,
    required DateTime date,
  }) async {
    final income = Income(
      id: _uuid.v4(),
      amount: amount,
      description: description,
      categoryId: categoryId,
      date: date,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final result = await _databaseService.createIncome(income);

    result.fold(
      (failure) {},
      (createdIncome) async {
        // Registrar en change log (no esperar si falla)
        _changeLogService.logCreate(
          entityType: 'income',
          entityId: createdIncome.id,
        ).then((_) {}).catchError((e) {
          appLogger.e('Error logging create', error: e);
        });
        
        // Actualizar estado localmente sin recargar toda la lista
        final currentIncomes = List<Income>.from(state.incomes);
        currentIncomes.insert(0, createdIncome);
        state = state.copyWith(
          incomes: currentIncomes,
          isLoading: false,
        );
      },
    );

    return result;
  }

  /// Actualiza un ingreso
  Future<Result<Income>> updateIncome(Income income) async {
    final updated = income.copyWith(updatedAt: DateTime.now());
    final result = await _databaseService.updateIncome(updated);

    result.fold(
      (failure) {},
      (updatedIncome) async {
        // Registrar en change log (no esperar si falla)
        _changeLogService.logUpdate(
          entityType: 'income',
          entityId: updatedIncome.id,
        ).then((_) {}).catchError((e) {
          appLogger.e('Error logging update', error: e);
        });
        
        // Actualizar estado localmente
        final currentIncomes = List<Income>.from(state.incomes);
        final index = currentIncomes.indexWhere((i) => i.id == updatedIncome.id);
        if (index != -1) {
          currentIncomes[index] = updatedIncome;
          state = state.copyWith(
            incomes: currentIncomes,
            isLoading: false,
          );
        } else {
          // Si no está en la lista, recargar
          await loadIncomes(forceRefresh: true);
        }
      },
    );

    return result;
  }

  /// Elimina un ingreso
  Future<Result<void>> deleteIncome(String id) async {
    final result = await _databaseService.deleteIncome(id);

    result.fold(
      (failure) {},
      (_) async {
        // Registrar en change log (no esperar si falla)
        _changeLogService.logDelete(
          entityType: 'income',
          entityId: id,
        ).then((_) {}).catchError((e) {
          appLogger.e('Error logging delete', error: e);
        });
        
        // Actualizar estado localmente
        final currentIncomes = List<Income>.from(state.incomes);
        currentIncomes.removeWhere((i) => i.id == id);
        state = state.copyWith(
          incomes: currentIncomes,
          isLoading: false,
        );
      },
    );

    return result;
  }
}

/// Provider del ViewModel de ingresos
final incomesViewModelProvider =
    StateNotifierProvider.autoDispose<IncomesViewModel, IncomesState>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  final changeLogService = ref.watch(changeLogServiceProvider);
  final viewModel = IncomesViewModel(databaseService, changeLogService);
  // Mantener el provider vivo para evitar recargas innecesarias
  ref.keepAlive();
  return viewModel;
});


