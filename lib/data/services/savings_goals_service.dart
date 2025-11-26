import 'package:dartz/dartz.dart';
import 'package:app_contabilidad/core/utils/result.dart';
import 'package:app_contabilidad/core/utils/logger.dart';
import 'package:app_contabilidad/core/errors/failures.dart';
import 'package:app_contabilidad/data/datasources/local/database_service.dart';
import 'package:app_contabilidad/data/datasources/local/change_log_service.dart';
import 'package:app_contabilidad/domain/entities/savings_goal.dart';
import 'package:uuid/uuid.dart';

/// Servicio para gestionar objetivos de ahorro
class SavingsGoalsService {
  final DatabaseService _databaseService;
  final ChangeLogService _changeLogService;
  final Uuid _uuid = const Uuid();

  SavingsGoalsService(this._databaseService, this._changeLogService);

  /// Obtiene todos los objetivos de ahorro
  Future<Result<List<SavingsGoal>>> getAllSavingsGoals({bool activeOnly = false}) async {
    return await _databaseService.getAllSavingsGoals(activeOnly: activeOnly);
  }

  /// Crea un objetivo de ahorro
  Future<Result<SavingsGoal>> createSavingsGoal(SavingsGoal savingsGoal) async {
    final result = await _databaseService.createSavingsGoal(savingsGoal);
    result.fold(
      (_) {},
      (created) async {
        await _changeLogService.logCreate(
          entityType: 'savings_goal',
          entityId: created.id,
        );
      },
    );
    return result;
  }

  /// Actualiza un objetivo de ahorro
  Future<Result<SavingsGoal>> updateSavingsGoal(SavingsGoal savingsGoal) async {
    final result = await _databaseService.updateSavingsGoal(savingsGoal);
    result.fold(
      (_) {},
      (updated) async {
        await _changeLogService.logUpdate(
          entityType: 'savings_goal',
          entityId: updated.id,
        );
      },
    );
    return result;
  }

  /// Elimina un objetivo de ahorro
  Future<Result<void>> deleteSavingsGoal(String id) async {
    final result = await _databaseService.deleteSavingsGoal(id);
    result.fold(
      (_) {},
      (_) async {
        await _changeLogService.logDelete(
          entityType: 'savings_goal',
          entityId: id,
        );
      },
    );
    return result;
  }

  /// Agrega dinero a un objetivo de ahorro
  Future<Result<SavingsGoal>> addToSavingsGoal(String id, double amount) async {
    try {
      final goalsResult = await getAllSavingsGoals();
      if (goalsResult.isFailure) {
        return Left(goalsResult.errorOrNull!);
      }

      final goals = goalsResult.valueOrNull ?? [];
      final goal = goals.firstWhere((g) => g.id == id, orElse: () => throw Exception('Objetivo no encontrado'));

      final newAmount = goal.currentAmount + amount;
      final isCompleted = newAmount >= goal.targetAmount;

      final updated = goal.copyWith(
        currentAmount: newAmount,
        isCompleted: isCompleted || goal.isCompleted,
        updatedAt: DateTime.now(),
      );

      return await updateSavingsGoal(updated);
    } catch (e) {
      appLogger.e('Error adding to savings goal', error: e);
      return Left(UnknownFailure('Error al agregar dinero al objetivo: ${e.toString()}'));
    }
  }
}

