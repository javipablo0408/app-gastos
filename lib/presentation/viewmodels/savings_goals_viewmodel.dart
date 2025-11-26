import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_contabilidad/core/providers/providers.dart';
import 'package:app_contabilidad/data/services/savings_goals_service.dart';
import 'package:app_contabilidad/core/utils/result.dart';
import 'package:app_contabilidad/core/utils/logger.dart';
import 'package:app_contabilidad/domain/entities/savings_goal.dart';
import 'package:app_contabilidad/presentation/viewmodels/dashboard_viewmodel.dart';
import 'package:uuid/uuid.dart';

/// Estado de objetivos de ahorro
class SavingsGoalsState {
  final List<SavingsGoal> savingsGoals;
  final bool isLoading;
  final String? error;

  SavingsGoalsState({
    this.savingsGoals = const [],
    this.isLoading = false,
    this.error,
  });

  SavingsGoalsState copyWith({
    List<SavingsGoal>? savingsGoals,
    bool? isLoading,
    String? error,
  }) {
    return SavingsGoalsState(
      savingsGoals: savingsGoals ?? this.savingsGoals,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// ViewModel para gestionar objetivos de ahorro
class SavingsGoalsViewModel extends StateNotifier<SavingsGoalsState> {
  final SavingsGoalsService _service;
  final Ref? _ref;
  final Uuid _uuid = const Uuid();

  SavingsGoalsViewModel(this._service, [this._ref]) : super(SavingsGoalsState()) {
    loadSavingsGoals();
  }

  /// Carga todos los objetivos de ahorro
  Future<void> loadSavingsGoals({bool forceRefresh = false}) async {
    if (!forceRefresh && state.savingsGoals.isNotEmpty && !state.isLoading) {
      return;
    }
    
    if (state.isLoading) {
      return;
    }
    
    state = state.copyWith(isLoading: true, error: null);

    final result = await _service.getAllSavingsGoals();

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
      },
      (savingsGoals) {
        state = state.copyWith(
          savingsGoals: savingsGoals,
          isLoading: false,
        );
      },
    );
  }

  /// Crea un nuevo objetivo de ahorro
  Future<Result<SavingsGoal>> createSavingsGoal({
    required String name,
    required String description,
    required double targetAmount,
    required DateTime targetDate,
  }) async {
    final savingsGoal = SavingsGoal(
      id: _uuid.v4(),
      name: name,
      description: description,
      targetAmount: targetAmount,
      currentAmount: 0.0,
      targetDate: targetDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final result = await _service.createSavingsGoal(savingsGoal);

    result.fold(
      (failure) {},
      (created) {
        // Actualizar estado localmente sin recargar toda la lista
        final currentGoals = List<SavingsGoal>.from(state.savingsGoals);
        currentGoals.insert(0, created);
        state = state.copyWith(
          savingsGoals: currentGoals,
          isLoading: false,
        );
      },
    );

    return result;
  }

  /// Actualiza un objetivo de ahorro
  Future<Result<SavingsGoal>> updateSavingsGoal(SavingsGoal savingsGoal) async {
    final updated = savingsGoal.copyWith(updatedAt: DateTime.now());
    final result = await _service.updateSavingsGoal(updated);

    result.fold(
      (failure) {},
      (updatedGoal) {
        // Actualizar estado localmente
        final currentGoals = List<SavingsGoal>.from(state.savingsGoals);
        final index = currentGoals.indexWhere((g) => g.id == updatedGoal.id);
        if (index != -1) {
          currentGoals[index] = updatedGoal;
          state = state.copyWith(
            savingsGoals: currentGoals,
            isLoading: false,
          );
        } else {
          // Si no está en la lista, recargar
          loadSavingsGoals(forceRefresh: true);
        }
        
        // Notificar al dashboard para que se actualice
        if (_ref != null) {
          final dashboardViewModel = _ref!.read(dashboardViewModelProvider.notifier);
          dashboardViewModel.updateSavingsGoalInDashboard(updatedGoal);
        }
      },
    );

    return result;
  }

  /// Elimina un objetivo de ahorro
  Future<Result<void>> deleteSavingsGoal(String id) async {
    final result = await _service.deleteSavingsGoal(id);

    result.fold(
      (failure) {},
      (_) {
        // Actualizar estado localmente
        final currentGoals = List<SavingsGoal>.from(state.savingsGoals);
        currentGoals.removeWhere((g) => g.id == id);
        state = state.copyWith(
          savingsGoals: currentGoals,
          isLoading: false,
        );
      },
    );

    return result;
  }

  /// Agrega dinero a un objetivo
  Future<Result<SavingsGoal>> addToSavingsGoal(String id, double amount) async {
    final result = await _service.addToSavingsGoal(id, amount);
    result.fold(
      (failure) {},
      (updatedGoal) {
        // Actualizar estado localmente
        final currentGoals = List<SavingsGoal>.from(state.savingsGoals);
        final index = currentGoals.indexWhere((g) => g.id == updatedGoal.id);
        if (index != -1) {
          currentGoals[index] = updatedGoal;
          state = state.copyWith(
            savingsGoals: currentGoals,
            isLoading: false,
          );
        } else {
          // Si no está en la lista, recargar
          loadSavingsGoals(forceRefresh: true);
        }
        
        // Notificar al dashboard para que se actualice
        if (_ref != null) {
          final dashboardViewModel = _ref!.read(dashboardViewModelProvider.notifier);
          dashboardViewModel.updateSavingsGoalInDashboard(updatedGoal);
        }
      },
    );
    return result;
  }
}

/// Provider del ViewModel de objetivos de ahorro
final savingsGoalsViewModelProvider =
    StateNotifierProvider.autoDispose<SavingsGoalsViewModel, SavingsGoalsState>((ref) {
  ref.keepAlive();
  final service = ref.watch(savingsGoalsServiceProvider);
  return SavingsGoalsViewModel(service, ref);
});

