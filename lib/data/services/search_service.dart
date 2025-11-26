import 'package:dartz/dartz.dart';
import 'package:app_contabilidad/core/utils/result.dart';
import 'package:app_contabilidad/core/utils/logger.dart';
import 'package:app_contabilidad/core/errors/failures.dart';
import 'package:app_contabilidad/data/datasources/local/database_service.dart';
import 'package:app_contabilidad/domain/entities/expense.dart';
import 'package:app_contabilidad/domain/entities/income.dart';

/// Criterios de búsqueda
class SearchCriteria {
  final String? query;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? categoryId;
  final List<String>? tagIds;
  final double? minAmount;
  final double? maxAmount;
  final bool? includeExpenses;
  final bool? includeIncomes;

  const SearchCriteria({
    this.query,
    this.startDate,
    this.endDate,
    this.categoryId,
    this.tagIds,
    this.minAmount,
    this.maxAmount,
    this.includeExpenses = true,
    this.includeIncomes = true,
  });

  bool get isEmpty {
    return query == null &&
        startDate == null &&
        endDate == null &&
        categoryId == null &&
        (tagIds == null || tagIds!.isEmpty) &&
        minAmount == null &&
        maxAmount == null;
  }
}

/// Resultado de búsqueda
class SearchResult {
  final List<Expense> expenses;
  final List<Income> incomes;
  final int totalCount;

  const SearchResult({
    this.expenses = const [],
    this.incomes = const [],
    this.totalCount = 0,
  });

  SearchResult copyWith({
    List<Expense>? expenses,
    List<Income>? incomes,
    int? totalCount,
  }) {
    return SearchResult(
      expenses: expenses ?? this.expenses,
      incomes: incomes ?? this.incomes,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

/// Servicio de búsqueda avanzada
class SearchService {
  final DatabaseService _databaseService;

  SearchService(this._databaseService);

  /// Realiza una búsqueda con los criterios especificados
  Future<Result<SearchResult>> search(SearchCriteria criteria) async {
    try {
      if (criteria.isEmpty) {
        return const Right(SearchResult());
      }

      List<Expense> expenses = [];
      List<Income> incomes = [];

      // Buscar gastos
      if (criteria.includeExpenses == true) {
        final expensesResult = await _databaseService.getAllExpenses(
          startDate: criteria.startDate,
          endDate: criteria.endDate,
          categoryId: criteria.categoryId,
        );

        if (expensesResult.isSuccess) {
          expenses = expensesResult.valueOrNull ?? [];
          
          // Filtrar por texto
          if (criteria.query != null && criteria.query!.isNotEmpty) {
            final query = criteria.query!.toLowerCase();
            expenses = expenses.where((e) {
              return e.description.toLowerCase().contains(query) ||
                  (e.category?.name.toLowerCase().contains(query) ?? false);
            }).toList();
          }

          // Filtrar por monto
          if (criteria.minAmount != null) {
            expenses = expenses.where((e) => e.amount >= criteria.minAmount!).toList();
          }
          if (criteria.maxAmount != null) {
            expenses = expenses.where((e) => e.amount <= criteria.maxAmount!).toList();
          }
        }
      }

      // Buscar ingresos
      if (criteria.includeIncomes == true) {
        final incomesResult = await _databaseService.getAllIncomes(
          startDate: criteria.startDate,
          endDate: criteria.endDate,
          categoryId: criteria.categoryId,
        );

        if (incomesResult.isSuccess) {
          incomes = incomesResult.valueOrNull ?? [];
          
          // Filtrar por texto
          if (criteria.query != null && criteria.query!.isNotEmpty) {
            final query = criteria.query!.toLowerCase();
            incomes = incomes.where((i) {
              return i.description.toLowerCase().contains(query) ||
                  (i.category?.name.toLowerCase().contains(query) ?? false);
            }).toList();
          }

          // Filtrar por monto
          if (criteria.minAmount != null) {
            incomes = incomes.where((i) => i.amount >= criteria.minAmount!).toList();
          }
          if (criteria.maxAmount != null) {
            incomes = incomes.where((i) => i.amount <= criteria.maxAmount!).toList();
          }
        }
      }

      final totalCount = expenses.length + incomes.length;

      return Right(SearchResult(
        expenses: expenses,
        incomes: incomes,
        totalCount: totalCount,
      ));
    } catch (e) {
      appLogger.e('Error in search', error: e);
      return Left(UnknownFailure('Error en búsqueda: ${e.toString()}'));
    }
  }

  /// Búsqueda rápida por texto
  Future<Result<SearchResult>> quickSearch(String query) async {
    return search(SearchCriteria(query: query));
  }
}

