import 'package:dartz/dartz.dart';
import 'package:app_contabilidad/core/utils/logger.dart';
import 'package:app_contabilidad/core/utils/result.dart';
import 'package:app_contabilidad/core/errors/failures.dart';
import 'package:app_contabilidad/data/services/recurring_expenses_service.dart';
import 'package:app_contabilidad/data/services/recurring_incomes_service.dart';
import 'package:app_contabilidad/domain/entities/expense.dart';
import 'package:app_contabilidad/domain/entities/income.dart';

/// Servicio para ejecutar automáticamente gastos e ingresos recurrentes
class RecurringExecutorService {
  final RecurringExpensesService _recurringExpensesService;
  final RecurringIncomesService _recurringIncomesService;

  RecurringExecutorService(
    this._recurringExpensesService,
    this._recurringIncomesService,
  );

  /// Ejecuta todos los gastos e ingresos recurrentes que deben ejecutarse hoy
  Future<Result<RecurringExecutionResult>> executeDueRecurringTransactions() async {
    try {
      appLogger.i('Iniciando ejecución de transacciones recurrentes');

      // Ejecutar gastos recurrentes
      final expensesResult = await _recurringExpensesService.executeDueRecurringExpenses();
      final expenses = expensesResult.fold(
        (failure) {
          appLogger.e('Error ejecutando gastos recurrentes', error: failure);
          return <Expense>[];
        },
        (expenses) => expenses,
      );

      // Ejecutar ingresos recurrentes
      final incomesResult = await _recurringIncomesService.executeDueRecurringIncomes();
      final incomes = incomesResult.fold(
        (failure) {
          appLogger.e('Error ejecutando ingresos recurrentes', error: failure);
          return <Income>[];
        },
        (incomes) => incomes,
      );

      final result = RecurringExecutionResult(
        expensesCreated: expenses.length,
        incomesCreated: incomes.length,
        expenses: expenses,
        incomes: incomes,
      );

      appLogger.i(
        'Ejecución completada: ${expenses.length} gastos, ${incomes.length} ingresos',
      );

      return Right(result);
    } catch (e) {
      appLogger.e('Error en ejecución de transacciones recurrentes', error: e);
      return Left(DatabaseFailure('Error al ejecutar transacciones recurrentes: ${e.toString()}'));
    }
  }
}

/// Resultado de la ejecución de transacciones recurrentes
class RecurringExecutionResult {
  final int expensesCreated;
  final int incomesCreated;
  final List<Expense> expenses;
  final List<Income> incomes;

  RecurringExecutionResult({
    required this.expensesCreated,
    required this.incomesCreated,
    required this.expenses,
    required this.incomes,
  });

  int get totalCreated => expensesCreated + incomesCreated;
}

