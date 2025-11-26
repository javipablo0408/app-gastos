import 'package:dartz/dartz.dart';
import 'package:app_contabilidad/core/utils/result.dart';
import 'package:app_contabilidad/core/utils/logger.dart';
import 'package:app_contabilidad/core/errors/failures.dart';
import 'package:app_contabilidad/data/services/shared_expenses_service.dart';
import 'package:app_contabilidad/domain/entities/shared_expense.dart';

/// Servicio para análisis de deudas
class DebtAnalysisService {
  final SharedExpensesService _sharedExpensesService;

  DebtAnalysisService(this._sharedExpensesService);

  /// Obtiene todas las deudas consolidadas entre participantes
  Future<Result<Map<String, double>>> getAllDebts() async {
    try {
      final sharedExpensesResult = await _sharedExpensesService.getAllSharedExpenses();
      
      return sharedExpensesResult.fold(
        (failure) => Left(failure),
        (sharedExpenses) {
          final debtMap = <String, double>{};
          
          for (final sharedExpense in sharedExpenses) {
            final debts = sharedExpense.calculateDebts();
            for (final debt in debts) {
              final key = '${debt.fromId}_${debt.toId}';
              debtMap[key] = (debtMap[key] ?? 0.0) + debt.amount;
            }
          }
          
          return Right(debtMap);
        },
      );
    } catch (e) {
      appLogger.e('Error calculating all debts', error: e);
      return Left(DatabaseFailure('Error al calcular deudas: ${e.toString()}'));
    }
  }

  /// Obtiene el resumen de deudas de un participante
  Future<Result<DebtSummary>> getDebtSummary(String participantId) async {
    try {
      final sharedExpensesResult = await _sharedExpensesService.getAllSharedExpenses();
      
      return sharedExpensesResult.fold(
        (failure) => Left(failure),
        (sharedExpenses) {
          double totalOwed = 0.0;
          double totalOwing = 0.0;
          final debts = <Debt>[];
          
          for (final sharedExpense in sharedExpenses) {
            final expenseDebts = sharedExpense.calculateDebts();
            for (final debt in expenseDebts) {
              if (debt.fromId == participantId) {
                totalOwed += debt.amount;
                debts.add(debt);
              } else if (debt.toId == participantId) {
                totalOwing += debt.amount;
              }
            }
          }
          
          return Right(DebtSummary(
            participantId: participantId,
            totalOwed: totalOwed,
            totalOwing: totalOwing,
            netBalance: totalOwing - totalOwed,
            debts: debts,
          ));
        },
      );
    } catch (e) {
      appLogger.e('Error getting debt summary', error: e);
      return Left(DatabaseFailure('Error al obtener resumen de deudas: ${e.toString()}'));
    }
  }
}

/// Resumen de deudas de un participante
class DebtSummary {
  final String participantId;
  final double totalOwed; // Cuánto debe
  final double totalOwing; // Cuánto le deben
  final double netBalance; // Balance neto (positivo = le deben, negativo = debe)
  final List<Debt> debts;

  DebtSummary({
    required this.participantId,
    required this.totalOwed,
    required this.totalOwing,
    required this.netBalance,
    required this.debts,
  });
}

