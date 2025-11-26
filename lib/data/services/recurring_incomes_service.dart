import 'package:dartz/dartz.dart';
import 'package:app_contabilidad/core/utils/result.dart';
import 'package:app_contabilidad/core/utils/logger.dart';
import 'package:app_contabilidad/core/errors/failures.dart';
import 'package:app_contabilidad/data/datasources/local/database_service.dart';
import 'package:app_contabilidad/data/datasources/local/change_log_service.dart';
import 'package:app_contabilidad/domain/entities/recurring_income.dart';
import 'package:app_contabilidad/domain/entities/income.dart';
import 'package:uuid/uuid.dart';

/// Servicio para gestionar ingresos recurrentes
class RecurringIncomesService {
  final DatabaseService _databaseService;
  final ChangeLogService _changeLogService;
  final Uuid _uuid = const Uuid();

  RecurringIncomesService(this._databaseService, this._changeLogService);

  /// Obtiene todos los ingresos recurrentes activos
  Future<Result<List<RecurringIncome>>> getActiveRecurringIncomes() async {
    return await _databaseService.getAllRecurringIncomes(activeOnly: true);
  }
  
  /// Obtiene todos los ingresos recurrentes
  Future<Result<List<RecurringIncome>>> getAllRecurringIncomes() async {
    return await _databaseService.getAllRecurringIncomes();
  }
  
  /// Crea un ingreso recurrente
  Future<Result<RecurringIncome>> createRecurringIncome(RecurringIncome recurringIncome) async {
    final result = await _databaseService.createRecurringIncome(recurringIncome);
    result.fold(
      (_) {},
      (created) async {
        await _changeLogService.logCreate(
          entityType: 'recurring_income',
          entityId: created.id,
        );
      },
    );
    return result;
  }
  
  /// Actualiza un ingreso recurrente
  Future<Result<RecurringIncome>> updateRecurringIncome(RecurringIncome recurringIncome) async {
    final result = await _databaseService.updateRecurringIncome(recurringIncome);
    result.fold(
      (_) {},
      (updated) async {
        await _changeLogService.logUpdate(
          entityType: 'recurring_income',
          entityId: updated.id,
        );
      },
    );
    return result;
  }
  
  /// Elimina un ingreso recurrente
  Future<Result<void>> deleteRecurringIncome(String id) async {
    final result = await _databaseService.deleteRecurringIncome(id);
    result.fold(
      (_) {},
      (_) async {
        await _changeLogService.logDelete(
          entityType: 'recurring_income',
          entityId: id,
        );
      },
    );
    return result;
  }

  /// Ejecuta los ingresos recurrentes que deben ejecutarse hoy
  Future<Result<List<Income>>> executeDueRecurringIncomes() async {
    try {
      appLogger.d('=== executeDueRecurringIncomes INICIADO ===');
      appLogger.d('Llamando a getActiveRecurringIncomes()');
      final recurringResult = await getActiveRecurringIncomes();
      appLogger.d('getActiveRecurringIncomes() completado, isFailure=${recurringResult.isFailure}');
      
      if (recurringResult.isFailure) {
        appLogger.e('Error obteniendo ingresos recurrentes activos', error: recurringResult.errorOrNull);
        return Left(recurringResult.errorOrNull!);
      }

      final recurringIncomes = recurringResult.valueOrNull ?? [];
      appLogger.d('Total de ingresos recurrentes activos: ${recurringIncomes.length}');
      final incomesToCreate = <Income>[];

      for (final recurring in recurringIncomes) {
        final shouldExecute = recurring.shouldExecuteToday();
        appLogger.d('Ingreso recurrente: ${recurring.description}');
        appLogger.d('  - isActive: ${recurring.isActive}');
        appLogger.d('  - startDate: ${recurring.startDate}');
        appLogger.d('  - lastExecuted: ${recurring.lastExecuted}');
        appLogger.d('  - recurrenceType: ${recurring.recurrenceType}');
        appLogger.d('  - recurrenceValue: ${recurring.recurrenceValue}');
        appLogger.d('  - shouldExecuteToday: $shouldExecute');
        
        if (shouldExecute) {
          appLogger.d('Ejecutando ingreso recurrente: ${recurring.description}');
          
          final income = Income(
            id: _uuid.v4(),
            amount: recurring.amount,
            description: recurring.description,
            categoryId: recurring.categoryId,
            date: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          appLogger.d('Ingreso creado en memoria: ${income.description}, categoría: ${income.categoryId}');

          // Verificar que la categoría existe antes de crear el ingreso
          if (recurring.categoryId.isEmpty) {
            appLogger.e('Ingreso recurrente sin categoría: ${recurring.description}');
            continue;
          }
          
          appLogger.d('Llamando a createIncome para: ${income.description}');
          final createResult = await _databaseService.createIncome(income);
          appLogger.d('createIncome completado, isFailure=${createResult.isFailure}');
          
          if (createResult.isFailure) {
            appLogger.e('Error creating income from recurring: ${recurring.description}', error: createResult.errorOrNull);
            continue;
          }
          
          final createdIncome = createResult.valueOrNull!;
          appLogger.d('Ingreso creado exitosamente: ${createdIncome.description}, categoría: ${createdIncome.category?.name ?? "Sin categoría"}');
          
          // Usar el ingreso creado con categoría cargada si está disponible
          incomesToCreate.add(createdIncome);
          
          // Actualizar lastExecuted del ingreso recurrente (sin esperar para evitar bloqueos)
          final updatedRecurring = recurring.copyWith(
            lastExecuted: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          
          // Actualizar el ingreso recurrente en segundo plano (fire-and-forget)
          updateRecurringIncome(updatedRecurring).then((result) {
            result.fold(
              (failure) {
                appLogger.e('Error updating recurring income', error: failure);
              },
              (_) {
                appLogger.d('Ingreso recurrente actualizado: ${recurring.description}');
              },
            );
          }).catchError((e) {
            appLogger.e('Error updating recurring income', error: e);
          });
          
          // Registrar en change log (fire-and-forget)
          _changeLogService.logCreate(
            entityType: 'income',
            entityId: createdIncome.id,
          ).then((_) {}).catchError((e) {
            appLogger.e('Error logging create', error: e);
          });
        } else {
          appLogger.d('Ingreso recurrente NO debe ejecutarse hoy: ${recurring.description}');
        }
      }
      
      appLogger.d('Total de ingresos creados: ${incomesToCreate.length}');

      return Right(incomesToCreate);
    } catch (e) {
      appLogger.e('Error executing recurring incomes', error: e);
      return Left(UnknownFailure('Error al ejecutar ingresos recurrentes: ${e.toString()}'));
    }
  }
}

