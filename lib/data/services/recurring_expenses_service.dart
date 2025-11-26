import 'package:dartz/dartz.dart';
import 'package:app_contabilidad/core/utils/result.dart';
import 'package:app_contabilidad/core/utils/logger.dart';
import 'package:app_contabilidad/core/errors/failures.dart';
import 'package:app_contabilidad/data/datasources/local/database_service.dart';
import 'package:app_contabilidad/data/datasources/local/change_log_service.dart';
import 'package:app_contabilidad/domain/entities/recurring_expense.dart';
import 'package:app_contabilidad/domain/entities/expense.dart';
import 'package:uuid/uuid.dart';

/// Servicio para gestionar gastos recurrentes
class RecurringExpensesService {
  final DatabaseService _databaseService;
  final ChangeLogService _changeLogService;
  final Uuid _uuid = const Uuid();

  RecurringExpensesService(this._databaseService, this._changeLogService);

  /// Obtiene todos los gastos recurrentes activos
  Future<Result<List<RecurringExpense>>> getActiveRecurringExpenses() async {
    return await _databaseService.getAllRecurringExpenses(activeOnly: true);
  }
  
  /// Obtiene todos los gastos recurrentes
  Future<Result<List<RecurringExpense>>> getAllRecurringExpenses() async {
    return await _databaseService.getAllRecurringExpenses();
  }
  
  /// Crea un gasto recurrente
  Future<Result<RecurringExpense>> createRecurringExpense(RecurringExpense recurringExpense) async {
    final result = await _databaseService.createRecurringExpense(recurringExpense);
    result.fold(
      (_) {},
      (created) async {
        await _changeLogService.logCreate(
          entityType: 'recurring_expense',
          entityId: created.id,
        );
      },
    );
    return result;
  }
  
  /// Actualiza un gasto recurrente
  Future<Result<RecurringExpense>> updateRecurringExpense(RecurringExpense recurringExpense) async {
    final result = await _databaseService.updateRecurringExpense(recurringExpense);
    result.fold(
      (_) {},
      (updated) async {
        await _changeLogService.logUpdate(
          entityType: 'recurring_expense',
          entityId: updated.id,
        );
      },
    );
    return result;
  }
  
  /// Elimina un gasto recurrente
  Future<Result<void>> deleteRecurringExpense(String id) async {
    final result = await _databaseService.deleteRecurringExpense(id);
    result.fold(
      (_) {},
      (_) async {
        await _changeLogService.logDelete(
          entityType: 'recurring_expense',
          entityId: id,
        );
      },
    );
    return result;
  }

  /// Ejecuta los gastos recurrentes que deben ejecutarse hoy
  Future<Result<List<Expense>>> executeDueRecurringExpenses() async {
    try {
      appLogger.d('=== executeDueRecurringExpenses INICIADO ===');
      appLogger.d('Llamando a getActiveRecurringExpenses()');
      final recurringResult = await getActiveRecurringExpenses();
      appLogger.d('getActiveRecurringExpenses() completado, isFailure=${recurringResult.isFailure}');
      
      if (recurringResult.isFailure) {
        appLogger.e('Error obteniendo gastos recurrentes activos', error: recurringResult.errorOrNull);
        return Left(recurringResult.errorOrNull!);
      }

      final recurringExpenses = recurringResult.valueOrNull ?? [];
      appLogger.d('Total de gastos recurrentes activos: ${recurringExpenses.length}');
      final expensesToCreate = <Expense>[];

      for (final recurring in recurringExpenses) {
        final shouldExecute = recurring.shouldExecuteToday();
        appLogger.d('Gasto recurrente: ${recurring.description}');
        appLogger.d('  - isActive: ${recurring.isActive}');
        appLogger.d('  - startDate: ${recurring.startDate}');
        appLogger.d('  - lastExecuted: ${recurring.lastExecuted}');
        appLogger.d('  - recurrenceType: ${recurring.recurrenceType}');
        appLogger.d('  - recurrenceValue: ${recurring.recurrenceValue}');
        appLogger.d('  - shouldExecuteToday: $shouldExecute');
        
        if (shouldExecute) {
          appLogger.d('Ejecutando gasto recurrente: ${recurring.description}');
          
          final expense = Expense(
            id: _uuid.v4(),
            amount: recurring.amount,
            description: recurring.description,
            categoryId: recurring.categoryId,
            date: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          appLogger.d('Gasto creado en memoria: ${expense.description}, categoría: ${expense.categoryId}');

          // Verificar que la categoría existe antes de crear el gasto
          if (recurring.categoryId.isEmpty) {
            appLogger.e('Gasto recurrente sin categoría: ${recurring.description}');
            continue;
          }
          
          appLogger.d('Llamando a createExpense para: ${expense.description}');
          final createResult = await _databaseService.createExpense(expense);
          appLogger.d('createExpense completado, isFailure=${createResult.isFailure}');
          
          if (createResult.isFailure) {
            appLogger.e('Error creating expense from recurring: ${recurring.description}', error: createResult.errorOrNull);
            continue;
          }
          
          final createdExpense = createResult.valueOrNull!;
          appLogger.d('Gasto creado exitosamente: ${createdExpense.description}, categoría: ${createdExpense.category?.name ?? "Sin categoría"}');
          
          // Usar el gasto creado con categoría cargada si está disponible
          expensesToCreate.add(createdExpense);
          
          // Actualizar lastExecuted del gasto recurrente (sin esperar para evitar bloqueos)
          final updatedRecurring = recurring.copyWith(
            lastExecuted: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          
          // Actualizar el gasto recurrente en segundo plano (fire-and-forget)
          updateRecurringExpense(updatedRecurring).then((result) {
            result.fold(
              (failure) {
                appLogger.e('Error updating recurring expense', error: failure);
              },
              (_) {
                appLogger.d('Gasto recurrente actualizado: ${recurring.description}');
              },
            );
          }).catchError((e) {
            appLogger.e('Error updating recurring expense', error: e);
          });
          
          // Registrar en change log (fire-and-forget)
          _changeLogService.logCreate(
            entityType: 'expense',
            entityId: createdExpense.id,
          ).then((_) {}).catchError((e) {
            appLogger.e('Error logging create', error: e);
          });
        } else {
          appLogger.d('Gasto recurrente NO debe ejecutarse hoy: ${recurring.description}');
        }
      }
      
      appLogger.d('Total de gastos creados: ${expensesToCreate.length}');

      return Right(expensesToCreate);
    } catch (e) {
      appLogger.e('Error executing recurring expenses', error: e);
      return Left(UnknownFailure('Error al ejecutar gastos recurrentes: ${e.toString()}'));
    }
  }
}

