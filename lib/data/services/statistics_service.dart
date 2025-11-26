import 'package:dartz/dartz.dart';
import 'package:app_contabilidad/core/utils/result.dart';
import 'package:app_contabilidad/core/utils/logger.dart';
import 'package:app_contabilidad/core/errors/failures.dart';
import 'package:app_contabilidad/data/datasources/local/database_service.dart';
import 'package:app_contabilidad/domain/entities/expense.dart';
import 'package:app_contabilidad/domain/entities/income.dart';

/// Estadísticas financieras
class FinancialStatistics {
  final double totalExpenses;
  final double totalIncomes;
  final double balance;
  final double averageDailyExpense;
  final double averageWeeklyExpense;
  final double averageMonthlyExpense;
  final String topCategory;
  final double topCategoryAmount;
  final Map<String, double> expensesByCategory;
  final Map<String, double> expensesByMonth;
  final List<MonthlyComparison> monthlyComparisons;

  const FinancialStatistics({
    this.totalExpenses = 0.0,
    this.totalIncomes = 0.0,
    this.balance = 0.0,
    this.averageDailyExpense = 0.0,
    this.averageWeeklyExpense = 0.0,
    this.averageMonthlyExpense = 0.0,
    this.topCategory = '',
    this.topCategoryAmount = 0.0,
    this.expensesByCategory = const {},
    this.expensesByMonth = const {},
    this.monthlyComparisons = const [],
  });
}

/// Comparación mensual
class MonthlyComparison {
  final String month;
  final double expenses;
  final double incomes;
  final double balance;
  final double changeFromPrevious; // Cambio porcentual

  const MonthlyComparison({
    required this.month,
    this.expenses = 0.0,
    this.incomes = 0.0,
    this.balance = 0.0,
    this.changeFromPrevious = 0.0,
  });
}

/// Servicio de estadísticas avanzadas
class StatisticsService {
  final DatabaseService _databaseService;

  StatisticsService(this._databaseService);

  /// Calcula estadísticas para un período
  Future<Result<FinancialStatistics>> calculateStatistics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Obtener gastos e ingresos del período
      final expensesResult = await _databaseService.getAllExpenses(
        startDate: startDate,
        endDate: endDate,
      );

      final incomesResult = await _databaseService.getAllIncomes(
        startDate: startDate,
        endDate: endDate,
      );

      if (expensesResult.isFailure || incomesResult.isFailure) {
        return Left(DatabaseFailure('Error al cargar datos para estadísticas'));
      }

      final expenses = expensesResult.valueOrNull ?? [];
      final incomes = incomesResult.valueOrNull ?? [];

      // Calcular totales
      final totalExpenses = expenses.fold<double>(0, (sum, e) => sum + e.amount);
      final totalIncomes = incomes.fold<double>(0, (sum, i) => sum + i.amount);
      final balance = totalIncomes - totalExpenses;

      // Calcular promedios
      final days = endDate.difference(startDate).inDays + 1;
      final weeks = (days / 7).ceil();
      final months = ((endDate.year - startDate.year) * 12) +
          (endDate.month - startDate.month) + 1;

      final averageDailyExpense = days > 0 ? totalExpenses / days : 0.0;
      final averageWeeklyExpense = weeks > 0 ? totalExpenses / weeks : 0.0;
      final averageMonthlyExpense = months > 0 ? totalExpenses / months : 0.0;

      // Categoría con mayor gasto
      final expensesByCategory = <String, double>{};
      for (final expense in expenses) {
        final categoryName = expense.category?.name ?? 'Sin categoría';
        expensesByCategory[categoryName] =
            (expensesByCategory[categoryName] ?? 0) + expense.amount;
      }

      String topCategory = '';
      double topCategoryAmount = 0.0;
      expensesByCategory.forEach((category, amount) {
        if (amount > topCategoryAmount) {
          topCategory = category;
          topCategoryAmount = amount;
        }
      });

      // Gastos por mes
      final expensesByMonth = <String, double>{};
      for (final expense in expenses) {
        final monthKey = '${expense.date.year}-${expense.date.month.toString().padLeft(2, '0')}';
        expensesByMonth[monthKey] = (expensesByMonth[monthKey] ?? 0) + expense.amount;
      }

      // Comparaciones mensuales
      final monthlyComparisons = _calculateMonthlyComparisons(
        expenses,
        incomes,
        startDate,
        endDate,
      );

      return Right(FinancialStatistics(
        totalExpenses: totalExpenses,
        totalIncomes: totalIncomes,
        balance: balance,
        averageDailyExpense: averageDailyExpense,
        averageWeeklyExpense: averageWeeklyExpense,
        averageMonthlyExpense: averageMonthlyExpense,
        topCategory: topCategory,
        topCategoryAmount: topCategoryAmount,
        expensesByCategory: expensesByCategory,
        expensesByMonth: expensesByMonth,
        monthlyComparisons: monthlyComparisons,
      ));
    } catch (e) {
      appLogger.e('Error calculating statistics', error: e);
      return Left(UnknownFailure('Error al calcular estadísticas: ${e.toString()}'));
    }
  }

  List<MonthlyComparison> _calculateMonthlyComparisons(
    List<Expense> expenses,
    List<Income> incomes,
    DateTime startDate,
    DateTime endDate,
  ) {
    final comparisons = <MonthlyComparison>[];
    final monthlyData = <String, Map<String, double>>{};

    // Agrupar por mes
    for (final expense in expenses) {
      final monthKey = '${expense.date.year}-${expense.date.month.toString().padLeft(2, '0')}';
      monthlyData.putIfAbsent(monthKey, () => {'expenses': 0, 'incomes': 0});
      monthlyData[monthKey]!['expenses'] =
          (monthlyData[monthKey]!['expenses'] ?? 0) + expense.amount;
    }

    for (final income in incomes) {
      final monthKey = '${income.date.year}-${income.date.month.toString().padLeft(2, '0')}';
      monthlyData.putIfAbsent(monthKey, () => {'expenses': 0, 'incomes': 0});
      monthlyData[monthKey]!['incomes'] =
          (monthlyData[monthKey]!['incomes'] ?? 0) + income.amount;
    }

    // Crear comparaciones
    final sortedMonths = monthlyData.keys.toList()..sort();
    double? previousExpenses;

    for (final monthKey in sortedMonths) {
      final data = monthlyData[monthKey]!;
      final monthExpenses = data['expenses'] ?? 0.0;
      final monthIncomes = data['incomes'] ?? 0.0;
      final monthBalance = monthIncomes - monthExpenses;

      double changeFromPrevious = 0.0;
      if (previousExpenses != null && previousExpenses > 0) {
        changeFromPrevious = ((monthExpenses - previousExpenses) / previousExpenses) * 100;
      }

      comparisons.add(MonthlyComparison(
        month: monthKey,
        expenses: monthExpenses,
        incomes: monthIncomes,
        balance: monthBalance,
        changeFromPrevious: changeFromPrevious,
      ));

      previousExpenses = monthExpenses;
    }

    return comparisons;
  }
}

