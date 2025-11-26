import 'package:dartz/dartz.dart';
import 'package:app_contabilidad/core/utils/result.dart';
import 'package:app_contabilidad/core/utils/logger.dart';
import 'package:app_contabilidad/core/errors/failures.dart';
import 'package:app_contabilidad/data/datasources/local/database_service.dart';
import 'package:app_contabilidad/domain/entities/expense.dart';
import 'package:app_contabilidad/domain/entities/income.dart';

/// Servicio para comparar períodos
class PeriodComparisonService {
  final DatabaseService _databaseService;

  PeriodComparisonService(this._databaseService);

  /// Compara dos períodos
  Future<Result<PeriodComparison>> comparePeriods({
    required DateTime period1Start,
    required DateTime period1End,
    required DateTime period2Start,
    required DateTime period2End,
  }) async {
    try {
      // Obtener datos del período 1
      final period1ExpensesResult = await _databaseService.getAllExpenses(
        startDate: period1Start,
        endDate: period1End,
      );
      final period1IncomesResult = await _databaseService.getAllIncomes(
        startDate: period1Start,
        endDate: period1End,
      );

      // Obtener datos del período 2
      final period2ExpensesResult = await _databaseService.getAllExpenses(
        startDate: period2Start,
        endDate: period2End,
      );
      final period2IncomesResult = await _databaseService.getAllIncomes(
        startDate: period2Start,
        endDate: period2End,
      );

      return period1ExpensesResult.fold(
        (failure) => Left(failure),
        (period1Expenses) => period1IncomesResult.fold(
          (failure) => Left(failure),
          (period1Incomes) => period2ExpensesResult.fold(
            (failure) => Left(failure),
            (period2Expenses) => period2IncomesResult.fold(
              (failure) => Left(failure),
              (period2Incomes) {
                final period1TotalExpenses = period1Expenses.fold<double>(
                  0.0,
                  (sum, e) => sum + e.amount,
                );
                final period1TotalIncomes = period1Incomes.fold<double>(
                  0.0,
                  (sum, i) => sum + i.amount,
                );
                final period2TotalExpenses = period2Expenses.fold<double>(
                  0.0,
                  (sum, e) => sum + e.amount,
                );
                final period2TotalIncomes = period2Incomes.fold<double>(
                  0.0,
                  (sum, i) => sum + i.amount,
                );

                final expenseChange = period2TotalExpenses - period1TotalExpenses;
                final incomeChange = period2TotalIncomes - period1TotalIncomes;
                final balanceChange = (period2TotalIncomes - period2TotalExpenses) -
                    (period1TotalIncomes - period1TotalExpenses);

                return Right(PeriodComparison(
                  period1: PeriodData(
                    totalExpenses: period1TotalExpenses,
                    totalIncomes: period1TotalIncomes,
                    balance: period1TotalIncomes - period1TotalExpenses,
                    expenses: period1Expenses,
                    incomes: period1Incomes,
                  ),
                  period2: PeriodData(
                    totalExpenses: period2TotalExpenses,
                    totalIncomes: period2TotalIncomes,
                    balance: period2TotalIncomes - period2TotalExpenses,
                    expenses: period2Expenses,
                    incomes: period2Incomes,
                  ),
                  expenseChange: expenseChange,
                  incomeChange: incomeChange,
                  balanceChange: balanceChange,
                  expenseChangePercent: period1TotalExpenses > 0
                      ? (expenseChange / period1TotalExpenses) * 100
                      : 0.0,
                  incomeChangePercent: period1TotalIncomes > 0
                      ? (incomeChange / period1TotalIncomes) * 100
                      : 0.0,
                ));
              },
            ),
          ),
        ),
      );
    } catch (e) {
      appLogger.e('Error comparing periods', error: e);
      return Left(DatabaseFailure('Error al comparar períodos: ${e.toString()}'));
    }
  }
}

/// Comparación de períodos
class PeriodComparison {
  final PeriodData period1;
  final PeriodData period2;
  final double expenseChange;
  final double incomeChange;
  final double balanceChange;
  final double expenseChangePercent;
  final double incomeChangePercent;

  PeriodComparison({
    required this.period1,
    required this.period2,
    required this.expenseChange,
    required this.incomeChange,
    required this.balanceChange,
    required this.expenseChangePercent,
    required this.incomeChangePercent,
  });
}

/// Datos de un período
class PeriodData {
  final double totalExpenses;
  final double totalIncomes;
  final double balance;
  final List<Expense> expenses;
  final List<Income> incomes;

  PeriodData({
    required this.totalExpenses,
    required this.totalIncomes,
    required this.balance,
    required this.expenses,
    required this.incomes,
  });
}

