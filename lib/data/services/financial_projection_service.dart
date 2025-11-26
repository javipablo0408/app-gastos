import 'package:dartz/dartz.dart';
import 'package:app_contabilidad/core/utils/result.dart';
import 'package:app_contabilidad/core/utils/logger.dart';
import 'package:app_contabilidad/core/errors/failures.dart';
import 'package:app_contabilidad/data/datasources/local/database_service.dart';

/// Servicio para proyecciones financieras
class FinancialProjectionService {
  final DatabaseService _databaseService;

  FinancialProjectionService(this._databaseService);

  /// Proyecta el balance futuro basado en tendencias históricas
  Future<Result<FinancialProjection>> projectFutureBalance({
    required DateTime startDate,
    required DateTime endDate,
    int monthsToProject = 6,
  }) async {
    try {
      // Obtener datos históricos
      final expensesResult = await _databaseService.getAllExpenses(
        startDate: startDate,
        endDate: endDate,
      );
      final incomesResult = await _databaseService.getAllIncomes(
        startDate: startDate,
        endDate: endDate,
      );

      return expensesResult.fold(
        (failure) => Left(failure),
        (expenses) => incomesResult.fold(
          (failure) => Left(failure),
          (incomes) {
            // Calcular promedios mensuales
            final months = _calculateMonthsBetween(startDate, endDate);
            if (months <= 0) {
              return Left(DatabaseFailure('El rango de fechas no es válido'));
            }
            
            final totalExpenses = expenses.fold<double>(
              0.0,
              (sum, e) => sum + e.amount,
            );
            final totalIncomes = incomes.fold<double>(
              0.0,
              (sum, i) => sum + i.amount,
            );
            
            // Si no hay datos, usar 0 en lugar de dividir por meses
            final avgMonthlyExpenses = months > 0 ? totalExpenses / months : 0.0;
            final avgMonthlyIncomes = months > 0 ? totalIncomes / months : 0.0;

            // Validar que haya al menos algunos datos
            if (expenses.isEmpty && incomes.isEmpty) {
              return Left(DatabaseFailure(
                'No hay datos de gastos ni ingresos en el período seleccionado. '
                'Agrega algunos gastos e ingresos primero.',
              ));
            }

            // Calcular balance actual
            final currentBalance = totalIncomes - totalExpenses;

            // Proyectar meses futuros
            final projections = <MonthlyProjection>[];
            double projectedBalance = currentBalance;

            for (int i = 1; i <= monthsToProject; i++) {
              projectedBalance += (avgMonthlyIncomes - avgMonthlyExpenses);
              projections.add(MonthlyProjection(
                month: DateTime.now().add(Duration(days: 30 * i)),
                projectedIncome: avgMonthlyIncomes,
                projectedExpense: avgMonthlyExpenses,
                projectedBalance: projectedBalance,
              ));
            }

            return Right(FinancialProjection(
              currentBalance: currentBalance,
              averageMonthlyIncome: avgMonthlyIncomes,
              averageMonthlyExpense: avgMonthlyExpenses,
              monthlySavings: avgMonthlyIncomes - avgMonthlyExpenses,
              projections: projections,
            ));
          },
        ),
      );
    } catch (e) {
      appLogger.e('Error projecting future balance', error: e);
      return Left(DatabaseFailure('Error al proyectar balance futuro: ${e.toString()}'));
    }
  }

  /// Simula un escenario "¿Qué pasa si...?"
  Future<Result<ScenarioResult>> simulateScenario({
    required DateTime startDate,
    required DateTime endDate,
    double? additionalExpense,
    double? additionalIncome,
    double? expenseReduction,
  }) async {
    try {
      final expensesResult = await _databaseService.getAllExpenses(
        startDate: startDate,
        endDate: endDate,
      );
      final incomesResult = await _databaseService.getAllIncomes(
        startDate: startDate,
        endDate: endDate,
      );

      return expensesResult.fold(
        (failure) => Left(failure),
        (expenses) => incomesResult.fold(
          (failure) => Left(failure),
          (incomes) {
            final months = _calculateMonthsBetween(startDate, endDate);
            if (months <= 0) {
              return Left(DatabaseFailure('El rango de fechas no es válido'));
            }
            final totalExpenses = expenses.fold<double>(
              0.0,
              (sum, e) => sum + e.amount,
            );
            final totalIncomes = incomes.fold<double>(
              0.0,
              (sum, i) => sum + i.amount,
            );
            final currentAvgExpense = totalExpenses / months;
            final currentAvgIncome = totalIncomes / months;

            final projectedExpense = currentAvgExpense +
                (additionalExpense ?? 0.0) -
                (expenseReduction ?? 0.0);
            final projectedIncome = currentAvgIncome + (additionalIncome ?? 0.0);

            final currentSavings = currentAvgIncome - currentAvgExpense;
            final projectedSavings = projectedIncome - projectedExpense;

            return Right(ScenarioResult(
              currentMonthlySavings: currentSavings,
              projectedMonthlySavings: projectedSavings,
              difference: projectedSavings - currentSavings,
              projectedExpense: projectedExpense,
              projectedIncome: projectedIncome,
            ));
          },
        ),
      );
    } catch (e) {
      appLogger.e('Error simulating scenario', error: e);
      return Left(DatabaseFailure('Error al simular escenario: ${e.toString()}'));
    }
  }

  int _calculateMonthsBetween(DateTime start, DateTime end) {
    // Asegurar que start sea anterior a end
    if (start.isAfter(end)) {
      return 1;
    }
    
    // Calcular diferencia en días
    final daysDifference = end.difference(start).inDays;
    
    // Si la diferencia es menor a 1 día, retornar 1 mes mínimo
    if (daysDifference < 1) {
      return 1;
    }
    
    // Calcular meses aproximados basado en días (promedio de 30.44 días por mes)
    final months = (daysDifference / 30.44).ceil();
    
    // Asegurar al menos 1 mes y máximo 24 meses
    if (months <= 0) {
      return 1;
    }
    if (months > 24) {
      return 24; // Limitar a 2 años para evitar cálculos muy largos
    }
    
    return months;
  }
}

/// Proyección financiera
class FinancialProjection {
  final double currentBalance;
  final double averageMonthlyIncome;
  final double averageMonthlyExpense;
  final double monthlySavings;
  final List<MonthlyProjection> projections;

  FinancialProjection({
    required this.currentBalance,
    required this.averageMonthlyIncome,
    required this.averageMonthlyExpense,
    required this.monthlySavings,
    required this.projections,
  });
}

/// Proyección mensual
class MonthlyProjection {
  final DateTime month;
  final double projectedIncome;
  final double projectedExpense;
  final double projectedBalance;

  MonthlyProjection({
    required this.month,
    required this.projectedIncome,
    required this.projectedExpense,
    required this.projectedBalance,
  });
}

/// Resultado de simulación de escenario
class ScenarioResult {
  final double currentMonthlySavings;
  final double projectedMonthlySavings;
  final double difference;
  final double projectedExpense;
  final double projectedIncome;

  ScenarioResult({
    required this.currentMonthlySavings,
    required this.projectedMonthlySavings,
    required this.difference,
    required this.projectedExpense,
    required this.projectedIncome,
  });
}

