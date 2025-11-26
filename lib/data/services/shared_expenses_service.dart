import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:app_contabilidad/core/utils/result.dart';
import 'package:app_contabilidad/core/utils/logger.dart';
import 'package:app_contabilidad/core/errors/failures.dart';
import 'package:app_contabilidad/data/datasources/local/database_service.dart';
import 'package:app_contabilidad/data/datasources/local/change_log_service.dart';
import 'package:app_contabilidad/domain/entities/shared_expense.dart';
import 'package:app_contabilidad/domain/entities/expense.dart';
import 'package:uuid/uuid.dart';

/// Servicio para gestionar gastos compartidos
class SharedExpensesService {
  final DatabaseService _databaseService;
  final ChangeLogService _changeLogService;
  final Uuid _uuid = const Uuid();

  SharedExpensesService(this._databaseService, this._changeLogService);

  /// Obtiene todos los gastos compartidos
  Future<Result<List<SharedExpense>>> getAllSharedExpenses({
    bool includeDeleted = false,
  }) async {
    try {
      return await _databaseService.getAllSharedExpenses(includeDeleted: includeDeleted);
    } catch (e) {
      appLogger.e('Error getting shared expenses', error: e);
      return Left(DatabaseFailure('Error al obtener gastos compartidos: ${e.toString()}'));
    }
  }

  /// Crea un gasto compartido
  Future<Result<SharedExpense>> createSharedExpense({
    required Expense expense,
    required List<Participant> participants,
    required SplitType splitType,
  }) async {
    try {
      // Crear el gasto primero
      final expenseResult = await _databaseService.createExpense(expense);
      
      return expenseResult.fold(
        (failure) => Left(failure),
        (createdExpense) async {
          final sharedExpense = SharedExpense(
            id: _uuid.v4(),
            expenseId: createdExpense.id,
            expense: createdExpense,
            participants: participants,
            splitType: splitType,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          // Guardar en base de datos
          final createResult = await _databaseService.createSharedExpense(sharedExpense);
          
          return createResult.fold(
            (failure) => Left(failure),
            (created) async {
              await _changeLogService.logCreate(
                entityType: 'shared_expense',
                entityId: created.id,
              );
              return Right(created);
            },
          );
        },
      );
    } catch (e) {
      appLogger.e('Error creating shared expense', error: e);
      return Left(DatabaseFailure('Error al crear gasto compartido: ${e.toString()}'));
    }
  }

  /// Actualiza un gasto compartido
  Future<Result<SharedExpense>> updateSharedExpense(SharedExpense sharedExpense) async {
    try {
      final result = await _databaseService.updateSharedExpense(sharedExpense);
      
      return result.fold(
        (failure) => Left(failure),
        (updated) async {
          await _changeLogService.logUpdate(
            entityType: 'shared_expense',
            entityId: updated.id,
          );
          return Right(updated);
        },
      );
    } catch (e) {
      appLogger.e('Error updating shared expense', error: e);
      return Left(DatabaseFailure('Error al actualizar gasto compartido: ${e.toString()}'));
    }
  }

  /// Elimina un gasto compartido
  Future<Result<void>> deleteSharedExpense(String id) async {
    try {
      final result = await _databaseService.deleteSharedExpense(id);
      
      return result.fold(
        (failure) => Left(failure),
        (_) async {
          await _changeLogService.logDelete(
            entityType: 'shared_expense',
            entityId: id,
          );
          return const Right(null);
        },
      );
    } catch (e) {
      appLogger.e('Error deleting shared expense', error: e);
      return Left(DatabaseFailure('Error al eliminar gasto compartido: ${e.toString()}'));
    }
  }

  /// Calcula las deudas entre participantes
  Future<Result<List<Debt>>> calculateDebts(String sharedExpenseId) async {
    final result = await getAllSharedExpenses();
    return result.fold(
      (failure) => Left(failure),
      (sharedExpenses) {
        final sharedExpense = sharedExpenses.firstWhere(
          (se) => se.id == sharedExpenseId,
          orElse: () => throw Exception('Shared expense not found'),
        );
        final debts = sharedExpense.calculateDebts();
        return Right(debts);
      },
    );
  }
}

