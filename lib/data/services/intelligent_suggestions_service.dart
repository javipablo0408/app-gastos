import 'package:dartz/dartz.dart';
import 'package:app_contabilidad/core/utils/result.dart';
import 'package:app_contabilidad/core/utils/logger.dart';
import 'package:app_contabilidad/core/errors/failures.dart';
import 'package:app_contabilidad/data/datasources/local/database_service.dart';
import 'package:app_contabilidad/domain/entities/expense.dart';
import 'package:app_contabilidad/domain/entities/income.dart';
import 'package:app_contabilidad/domain/entities/category.dart';

/// Servicio para sugerencias inteligentes
class IntelligentSuggestionsService {
  final DatabaseService _databaseService;

  IntelligentSuggestionsService(this._databaseService);

  /// Detecta gastos duplicados
  Future<Result<List<DuplicateExpense>>> detectDuplicateExpenses({
    required DateTime startDate,
    required DateTime endDate,
    double tolerance = 0.01, // Tolerancia para considerar duplicados
    Duration timeWindow = const Duration(hours: 24),
  }) async {
    try {
      final expensesResult = await _databaseService.getAllExpenses(
        startDate: startDate,
        endDate: endDate,
      );

      return expensesResult.fold(
        (failure) => Left(failure),
        (expenses) {
          final duplicates = <DuplicateExpense>[];
          final checked = <String>{};

          for (int i = 0; i < expenses.length; i++) {
            if (checked.contains(expenses[i].id)) continue;

            final similar = <Expense>[];
            for (int j = i + 1; j < expenses.length; j++) {
              if (checked.contains(expenses[j].id)) continue;

              final timeDiff = expenses[i].date.difference(expenses[j].date).abs();
              final amountDiff = (expenses[i].amount - expenses[j].amount).abs();

              if (timeDiff <= timeWindow &&
                  amountDiff <= tolerance &&
                  expenses[i].description.toLowerCase() ==
                      expenses[j].description.toLowerCase()) {
                if (similar.isEmpty) {
                  similar.add(expenses[i]);
                }
                similar.add(expenses[j]);
                checked.add(expenses[j].id);
              }
            }

            if (similar.length > 1) {
              duplicates.add(DuplicateExpense(
                expenses: similar,
                similarity: 1.0 - (similar[0].amount - similar[1].amount).abs() / similar[0].amount,
              ));
              checked.add(expenses[i].id);
            }
          }

          return Right(duplicates);
        },
      );
    } catch (e) {
      appLogger.e('Error detecting duplicate expenses', error: e);
      return Left(DatabaseFailure('Error al detectar gastos duplicados: ${e.toString()}'));
    }
  }

  /// Detecta gastos inusuales
  Future<Result<List<UnusualExpense>>> detectUnusualExpenses({
    required DateTime startDate,
    required DateTime endDate,
    double threshold = 2.0, // Desviaciones estándar
  }) async {
    try {
      final expensesResult = await _databaseService.getAllExpenses(
        startDate: startDate,
        endDate: endDate,
      );

      return expensesResult.fold(
        (failure) => Left(failure),
        (expenses) {
          if (expenses.length < 3) {
            return const Right([]);
          }

          // Calcular media y desviación estándar
          final amounts = expenses.map((e) => e.amount).toList();
          final mean = amounts.fold<double>(0.0, (sum, a) => sum + a) / amounts.length;
          final variance = amounts.fold<double>(
                0.0,
                (sum, a) => sum + (a - mean) * (a - mean),
              ) /
              amounts.length;
          final stdDev = variance > 0 ? variance : 1.0;

          final unusual = expenses
              .where((e) => (e.amount - mean).abs() > threshold * stdDev)
              .map((e) => UnusualExpense(
                    expense: e,
                    deviation: (e.amount - mean) / stdDev,
                    averageAmount: mean,
                  ))
              .toList();

          return Right(unusual);
        },
      );
    } catch (e) {
      appLogger.e('Error detecting unusual expenses', error: e);
      return Left(DatabaseFailure('Error al detectar gastos inusuales: ${e.toString()}'));
    }
  }

  /// Sugiere categoría basada en descripción
  Future<Result<Category?>> suggestCategory(String description) async {
    try {
      final expensesResult = await _databaseService.getAllExpenses();
      final categoriesResult = await _databaseService.getAllCategories();

      return expensesResult.fold(
        (failure) => Left(failure),
        (expenses) => categoriesResult.fold(
          (failure) => Left(failure),
          (categories) {
            // Buscar gastos con descripciones similares
            final descriptionLower = description.toLowerCase();
            final similarExpenses = expenses.where((e) {
              return e.description.toLowerCase().contains(descriptionLower) ||
                  descriptionLower.contains(e.description.toLowerCase());
            }).toList();

            if (similarExpenses.isEmpty) {
              return const Right(null);
            }

            // Contar categorías más usadas
            final categoryCount = <String, int>{};
            for (final expense in similarExpenses) {
              final categoryId = expense.categoryId;
              categoryCount[categoryId] = (categoryCount[categoryId] ?? 0) + 1;
            }

            // Obtener la categoría más frecuente
            if (categoryCount.isEmpty) {
              return const Right(null);
            }

            final mostUsedCategoryId = categoryCount.entries
                .reduce((a, b) => a.value > b.value ? a : b)
                .key;

            final suggestedCategory = categories.firstWhere(
              (c) => c.id == mostUsedCategoryId,
              orElse: () => categories.first,
            );

            return Right(suggestedCategory);
          },
        ),
      );
    } catch (e) {
      appLogger.e('Error suggesting category', error: e);
      return Left(DatabaseFailure('Error al sugerir categoría: ${e.toString()}'));
    }
  }
}

/// Gasto duplicado
class DuplicateExpense {
  final List<Expense> expenses;
  final double similarity; // 0.0 a 1.0

  DuplicateExpense({
    required this.expenses,
    required this.similarity,
  });
}

/// Gasto inusual
class UnusualExpense {
  final Expense expense;
  final double deviation; // Desviaciones estándar
  final double averageAmount;

  UnusualExpense({
    required this.expense,
    required this.deviation,
    required this.averageAmount,
  });
}

