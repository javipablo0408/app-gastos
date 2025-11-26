import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:app_contabilidad/core/errors/failures.dart';
import 'package:app_contabilidad/core/utils/logger.dart';
import 'package:app_contabilidad/core/utils/result.dart';
import 'package:app_contabilidad/data/models/database.dart' as db;
import 'package:app_contabilidad/data/models/category_model.dart';
import 'package:app_contabilidad/data/models/expense_model.dart';
import 'package:app_contabilidad/data/models/income_model.dart';
import 'package:app_contabilidad/data/models/budget_model.dart';
import 'package:app_contabilidad/data/models/change_log_model.dart';
import 'package:app_contabilidad/data/models/recurring_expense_model.dart';
import 'package:app_contabilidad/data/models/recurring_income_model.dart';
import 'package:app_contabilidad/data/models/savings_goal_model.dart';
import 'package:app_contabilidad/data/models/tag_model.dart';
import 'package:app_contabilidad/data/models/bill_model.dart';
import 'package:app_contabilidad/data/models/shared_expense_model.dart';
import 'package:app_contabilidad/domain/entities/category.dart';
import 'package:app_contabilidad/domain/entities/expense.dart';
import 'package:app_contabilidad/domain/entities/income.dart';
import 'package:app_contabilidad/domain/entities/budget.dart';
import 'package:app_contabilidad/domain/entities/change_log.dart';
import 'package:app_contabilidad/domain/entities/recurring_expense.dart';
import 'package:app_contabilidad/domain/entities/recurring_income.dart';
import 'package:app_contabilidad/domain/entities/savings_goal.dart';
import 'package:app_contabilidad/domain/entities/tag.dart';
import 'package:app_contabilidad/domain/entities/bill.dart';
import 'package:app_contabilidad/domain/entities/shared_expense.dart';
import 'package:synchronized/synchronized.dart';

/// Servicio de base de datos con semáforos para acceso concurrente seguro
class DatabaseService {
  final db.AppDatabase _database;
  final Lock _lock = Lock();

  DatabaseService(this._database);

  // ==================== CATEGORÍAS ====================

  /// Obtiene todas las categorías
  Future<Result<List<Category>>> getAllCategories({bool includeDeleted = false}) async {
    return await _lock.synchronized(() async {
      try {
        var query = _database.select(_database.categories);
        if (!includeDeleted) {
          query = query..where((c) => c.isDeleted.equals(false));
        }
        final results = await query.get();
        final categories = results.map((r) => r.toEntity()).toList();
        return Right(categories);
      } catch (e) {
        appLogger.e('Error getting categories', error: e);
        return Left(DatabaseFailure('Error al obtener categorías: ${e.toString()}'));
      }
    });
  }

  /// Obtiene una categoría por ID (versión interna sin lock, para usar dentro de operaciones ya sincronizadas)
  Future<Result<Category?>> _getCategoryByIdInternal(String id) async {
    try {
      final query = _database.select(_database.categories)
        ..where((c) => c.id.equals(id) & c.isDeleted.equals(false));
      final result = await query.getSingleOrNull();
      return Right(result?.toEntity());
    } catch (e) {
      appLogger.e('Error getting category by id', error: e);
      return Left(DatabaseFailure('Error al obtener categoría: ${e.toString()}'));
    }
  }

  /// Obtiene una categoría por ID
  Future<Result<Category?>> getCategoryById(String id) async {
    return await _lock.synchronized(() async {
      return await _getCategoryByIdInternal(id);
    });
  }

  /// Crea una categoría
  Future<Result<Category>> createCategory(Category category) async {
    return await _lock.synchronized(() async {
      try {
        await _database.into(_database.categories).insert(category.toCompanion());
        return Right(category);
      } catch (e) {
        appLogger.e('Error creating category', error: e);
        return Left(DatabaseFailure('Error al crear categoría: ${e.toString()}'));
      }
    });
  }

  /// Actualiza una categoría
  Future<Result<Category>> updateCategory(Category category) async {
    return await _lock.synchronized(() async {
      try {
        final updated = category.copyWith(updatedAt: DateTime.now());
        await (_database.update(_database.categories)..where((c) => c.id.equals(category.id)))
            .write(updated.toCompanion());
        return Right(updated);
      } catch (e) {
        appLogger.e('Error updating category', error: e);
        return Left(DatabaseFailure('Error al actualizar categoría: ${e.toString()}'));
      }
    });
  }

  /// Elimina una categoría (soft delete)
  Future<Result<void>> deleteCategory(String id) async {
    return await _lock.synchronized(() async {
      try {
        await (_database.update(_database.categories)..where((c) => c.id.equals(id)))
            .write(db.CategoriesCompanion(isDeleted: const Value(true), updatedAt: Value(DateTime.now())));
        return const Right(null);
      } catch (e) {
        appLogger.e('Error deleting category', error: e);
        return Left(DatabaseFailure('Error al eliminar categoría: ${e.toString()}'));
      }
    });
  }

  // ==================== GASTOS ====================

  /// Obtiene todos los gastos
  Future<Result<List<Expense>>> getAllExpenses({
    bool includeDeleted = false,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
  }) async {
    return await _lock.synchronized(() async {
      try {
        var query = _database.select(_database.expenses);
        
        if (!includeDeleted) {
          query = query..where((e) => e.isDeleted.equals(false));
        }
        
        if (startDate != null) {
          query = query..where((e) => e.date.isBiggerOrEqualValue(startDate));
        }
        
        if (endDate != null) {
          query = query..where((e) => e.date.isSmallerOrEqualValue(endDate));
        }
        
        if (categoryId != null) {
          query = query..where((e) => e.categoryId.equals(categoryId));
        }
        
        query = query..orderBy([(e) => OrderingTerm.desc(e.date)]);
        
        final results = await query.get();
        
        // Cargar categorías (usar versión interna sin lock ya que estamos dentro del lock)
        final categoryMap = <String, Category>{};
        for (final expense in results) {
          if (!categoryMap.containsKey(expense.categoryId)) {
            final catResult = await _getCategoryByIdInternal(expense.categoryId);
            catResult.fold(
              (l) => null,
              (r) => r?.let((cat) => categoryMap[expense.categoryId] = cat),
            );
          }
        }
        
        final expenses = results.map((r) => r.toEntity(category: categoryMap[r.categoryId])).toList();
        return Right(expenses);
      } catch (e) {
        appLogger.e('Error getting expenses', error: e);
        return Left(DatabaseFailure('Error al obtener gastos: ${e.toString()}'));
      }
    });
  }

  /// Crea un gasto
  Future<Result<Expense>> createExpense(Expense expense) async {
    return await _lock.synchronized(() async {
      try {
        appLogger.d('createExpense: iniciando para ${expense.description}');
        
        // Verificar que la categoría existe antes de crear el gasto
        if (expense.categoryId.isEmpty) {
          return Left(DatabaseFailure('El gasto debe tener una categoría asignada'));
        }
        
        appLogger.d('createExpense: cargando categoría ${expense.categoryId}');
        // Usar versión interna sin lock ya que estamos dentro del lock
        final catResult = await _getCategoryByIdInternal(expense.categoryId);
        Category? category;
        catResult.fold(
          (failure) {
            appLogger.e('Error loading category for expense: ${expense.categoryId}', error: failure);
          },
          (cat) {
            category = cat;
          },
        );
        
        if (category == null) {
          appLogger.w('Categoría no encontrada para el gasto: ${expense.categoryId}');
        } else {
          appLogger.d('createExpense: categoría cargada: ${category?.name ?? "null"}');
        }
        
        appLogger.d('createExpense: insertando en base de datos');
        await _database.into(_database.expenses).insert(expense.toCompanion());
        appLogger.d('createExpense: insertado exitosamente');
        
        // Retornar el gasto con la categoría cargada
        final expenseWithCategory = expense.copyWith(category: category);
        appLogger.d('createExpense: completado para ${expense.description}');
        return Right(expenseWithCategory);
      } catch (e, stackTrace) {
        appLogger.e('Error creating expense', error: e, stackTrace: stackTrace);
        return Left(DatabaseFailure('Error al crear gasto: ${e.toString()}'));
      }
    });
  }

  /// Actualiza un gasto
  Future<Result<Expense>> updateExpense(Expense expense) async {
    return await _lock.synchronized(() async {
      try {
        final updated = expense.copyWith(
          updatedAt: DateTime.now(),
          version: expense.version + 1,
        );
        await (_database.update(_database.expenses)..where((e) => e.id.equals(expense.id)))
            .write(updated.toCompanion());
        return Right(updated);
      } catch (e) {
        appLogger.e('Error updating expense', error: e);
        final errorMsg = e.toString();
        if (errorMsg.contains('bill_file_path') || errorMsg.contains('no such column')) {
          return Left(DatabaseFailure(
            'Error: La base de datos necesita actualizarse. '
            'Por favor, cierra y vuelve a abrir la aplicación para aplicar la migración automática.',
          ));
        }
        return Left(DatabaseFailure('Error al actualizar gasto: ${errorMsg}'));
      }
    });
  }

  /// Elimina un gasto (soft delete)
  Future<Result<void>> deleteExpense(String id) async {
    return await _lock.synchronized(() async {
      try {
        await (_database.update(_database.expenses)..where((e) => e.id.equals(id)))
            .write(db.ExpensesCompanion(
              isDeleted: const Value(true),
              updatedAt: Value(DateTime.now()),
            ));
        return const Right(null);
      } catch (e) {
        appLogger.e('Error deleting expense', error: e);
        return Left(DatabaseFailure('Error al eliminar gasto: ${e.toString()}'));
      }
    });
  }

  // ==================== INGRESOS ====================

  /// Obtiene todos los ingresos
  Future<Result<List<Income>>> getAllIncomes({
    bool includeDeleted = false,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
  }) async {
    return await _lock.synchronized(() async {
      try {
        var query = _database.select(_database.incomes);
        
        if (!includeDeleted) {
          query = query..where((i) => i.isDeleted.equals(false));
        }
        
        if (startDate != null) {
          query = query..where((i) => i.date.isBiggerOrEqualValue(startDate));
        }
        
        if (endDate != null) {
          query = query..where((i) => i.date.isSmallerOrEqualValue(endDate));
        }
        
        if (categoryId != null) {
          query = query..where((i) => i.categoryId.equals(categoryId));
        }
        
        query = query..orderBy([(i) => OrderingTerm.desc(i.date)]);
        
        final results = await query.get();
        
        // Cargar categorías (usar versión interna sin lock ya que estamos dentro del lock)
        final categoryMap = <String, Category>{};
        for (final income in results) {
          if (!categoryMap.containsKey(income.categoryId)) {
            final catResult = await _getCategoryByIdInternal(income.categoryId);
            catResult.fold(
              (l) => null,
              (r) => r?.let((cat) => categoryMap[income.categoryId] = cat),
            );
          }
        }
        
        final incomes = results.map((r) => r.toEntity(category: categoryMap[r.categoryId])).toList();
        return Right(incomes);
      } catch (e) {
        appLogger.e('Error getting incomes', error: e);
        return Left(DatabaseFailure('Error al obtener ingresos: ${e.toString()}'));
      }
    });
  }

  /// Crea un ingreso
  Future<Result<Income>> createIncome(Income income) async {
    return await _lock.synchronized(() async {
      try {
        await _database.into(_database.incomes).insert(income.toCompanion());
        return Right(income);
      } catch (e) {
        appLogger.e('Error creating income', error: e);
        return Left(DatabaseFailure('Error al crear ingreso: ${e.toString()}'));
      }
    });
  }

  /// Actualiza un ingreso
  Future<Result<Income>> updateIncome(Income income) async {
    return await _lock.synchronized(() async {
      try {
        final updated = income.copyWith(
          updatedAt: DateTime.now(),
          version: income.version + 1,
        );
        await (_database.update(_database.incomes)..where((i) => i.id.equals(income.id)))
            .write(updated.toCompanion());
        return Right(updated);
      } catch (e) {
        appLogger.e('Error updating income', error: e);
        return Left(DatabaseFailure('Error al actualizar ingreso: ${e.toString()}'));
      }
    });
  }

  /// Elimina un ingreso (soft delete)
  Future<Result<void>> deleteIncome(String id) async {
    return await _lock.synchronized(() async {
      try {
        await (_database.update(_database.incomes)..where((i) => i.id.equals(id)))
            .write(db.IncomesCompanion(
              isDeleted: const Value(true),
              updatedAt: Value(DateTime.now()),
            ));
        return const Right(null);
      } catch (e) {
        appLogger.e('Error deleting income', error: e);
        return Left(DatabaseFailure('Error al eliminar ingreso: ${e.toString()}'));
      }
    });
  }

  // ==================== PRESUPUESTOS ====================

  /// Obtiene todos los presupuestos
  Future<Result<List<Budget>>> getAllBudgets({bool includeDeleted = false}) async {
    return await _lock.synchronized(() async {
      try {
        var query = _database.select(_database.budgets);
        if (!includeDeleted) {
          query = query..where((b) => b.isDeleted.equals(false));
        }
        final results = await query.get();
        
        // Cargar categorías (usar versión interna sin lock ya que estamos dentro del lock)
        final categoryMap = <String, Category>{};
        for (final budget in results) {
          if (!categoryMap.containsKey(budget.categoryId)) {
            final catResult = await _getCategoryByIdInternal(budget.categoryId);
            catResult.fold(
              (l) => null,
              (r) => r?.let((cat) => categoryMap[budget.categoryId] = cat),
            );
          }
        }
        
        final budgets = results.map((r) => r.toEntity(category: categoryMap[r.categoryId])).toList();
        return Right(budgets);
      } catch (e) {
        appLogger.e('Error getting budgets', error: e);
        return Left(DatabaseFailure('Error al obtener presupuestos: ${e.toString()}'));
      }
    });
  }

  /// Crea un presupuesto
  Future<Result<Budget>> createBudget(Budget budget) async {
    return await _lock.synchronized(() async {
      try {
        await _database.into(_database.budgets).insert(budget.toCompanion());
        return Right(budget);
      } catch (e) {
        appLogger.e('Error creating budget', error: e);
        return Left(DatabaseFailure('Error al crear presupuesto: ${e.toString()}'));
      }
    });
  }

  /// Actualiza un presupuesto
  Future<Result<Budget>> updateBudget(Budget budget) async {
    return await _lock.synchronized(() async {
      try {
        final updated = budget.copyWith(updatedAt: DateTime.now());
        await (_database.update(_database.budgets)..where((b) => b.id.equals(budget.id)))
            .write(updated.toCompanion());
        return Right(updated);
      } catch (e) {
        appLogger.e('Error updating budget', error: e);
        return Left(DatabaseFailure('Error al actualizar presupuesto: ${e.toString()}'));
      }
    });
  }

  /// Elimina un presupuesto (soft delete)
  Future<Result<void>> deleteBudget(String id) async {
    return await _lock.synchronized(() async {
      try {
        await (_database.update(_database.budgets)..where((b) => b.id.equals(id)))
            .write(db.BudgetsCompanion(
              isDeleted: const Value(true),
              updatedAt: Value(DateTime.now()),
            ));
        return const Right(null);
      } catch (e) {
        appLogger.e('Error deleting budget', error: e);
        return Left(DatabaseFailure('Error al eliminar presupuesto: ${e.toString()}'));
      }
    });
  }

  // ==================== CHANGE LOGS ====================

  /// Obtiene logs de cambios pendientes de sincronizar
  Future<Result<List<ChangeLog>>> getPendingChangeLogs() async {
    return await _lock.synchronized(() async {
      try {
        final query = _database.select(_database.changeLogs)
          ..where((c) => c.synced.equals(false))
          ..orderBy([(c) => OrderingTerm.asc(c.timestamp)]);
        final results = await query.get();
        return Right(results.map((r) => r.toEntity()).toList());
      } catch (e) {
        appLogger.e('Error getting pending change logs', error: e);
        return Left(DatabaseFailure('Error al obtener logs de cambios: ${e.toString()}'));
      }
    });
  }

  /// Crea un log de cambio
  Future<Result<ChangeLog>> createChangeLog(ChangeLog changeLog) async {
    return await _lock.synchronized(() async {
      try {
        await _database.into(_database.changeLogs).insert(changeLog.toCompanion());
        return Right(changeLog);
      } catch (e) {
        appLogger.e('Error creating change log', error: e);
        return Left(DatabaseFailure('Error al crear log de cambio: ${e.toString()}'));
      }
    });
  }

  /// Marca logs como sincronizados
  Future<Result<void>> markChangeLogsAsSynced(List<String> logIds) async {
    return await _lock.synchronized(() async {
      try {
        for (final id in logIds) {
          await (_database.update(_database.changeLogs)..where((c) => c.id.equals(id)))
              .write(const db.ChangeLogsCompanion(synced: Value(true)));
        }
        return const Right(null);
      } catch (e) {
        appLogger.e('Error marking change logs as synced', error: e);
        return Left(DatabaseFailure('Error al marcar logs como sincronizados: ${e.toString()}'));
      }
    });
  }

  // ==================== GASTOS RECURRENTES ====================

  /// Obtiene todos los gastos recurrentes
  Future<Result<List<RecurringExpense>>> getAllRecurringExpenses({
    bool includeDeleted = false,
    bool activeOnly = false,
  }) async {
    appLogger.d('getAllRecurringExpenses: iniciando, activeOnly=$activeOnly');
    return await _lock.synchronized(() async {
      try {
        appLogger.d('getAllRecurringExpenses: dentro del lock, creando query');
        var query = _database.select(_database.recurringExpenses);
        if (!includeDeleted) {
          query = query..where((r) => r.isDeleted.equals(false));
        }
        if (activeOnly) {
          query = query..where((r) => r.isActive.equals(true));
        }
        query = query..orderBy([(r) => OrderingTerm.desc(r.createdAt)]);
        appLogger.d('getAllRecurringExpenses: ejecutando query');
        final results = await query.get();
        appLogger.d('getAllRecurringExpenses: query ejecutada, resultados: ${results.length}');
        
        // Cargar categorías (usar versión interna sin lock ya que estamos dentro del lock)
        final categoryMap = <String, Category>{};
        appLogger.d('getAllRecurringExpenses: cargando categorías para ${results.length} gastos recurrentes');
        for (final recurring in results) {
          if (!categoryMap.containsKey(recurring.categoryId)) {
            appLogger.d('getAllRecurringExpenses: cargando categoría ${recurring.categoryId}');
            final catResult = await _getCategoryByIdInternal(recurring.categoryId);
            catResult.fold(
              (l) => null,
              (r) => r?.let((cat) => categoryMap[recurring.categoryId] = cat),
            );
          }
        }
        appLogger.d('getAllRecurringExpenses: categorías cargadas, creando entidades');
        
        final recurringExpenses = results.map((r) => r.toEntity(category: categoryMap[r.categoryId])).toList();
        appLogger.d('getAllRecurringExpenses: completado, ${recurringExpenses.length} gastos recurrentes');
        return Right(recurringExpenses);
      } catch (e, stackTrace) {
        appLogger.e('Error getting recurring expenses', error: e, stackTrace: stackTrace);
        return Left(DatabaseFailure('Error al obtener gastos recurrentes: ${e.toString()}'));
      }
    });
  }

  /// Crea un gasto recurrente
  Future<Result<RecurringExpense>> createRecurringExpense(RecurringExpense recurringExpense) async {
    return await _lock.synchronized(() async {
      try {
        await _database.into(_database.recurringExpenses).insert(recurringExpense.toCompanion());
        return Right(recurringExpense);
      } catch (e) {
        appLogger.e('Error creating recurring expense', error: e);
        return Left(DatabaseFailure('Error al crear gasto recurrente: ${e.toString()}'));
      }
    });
  }

  /// Actualiza un gasto recurrente
  Future<Result<RecurringExpense>> updateRecurringExpense(RecurringExpense recurringExpense) async {
    return await _lock.synchronized(() async {
      try {
        final updated = recurringExpense.copyWith(updatedAt: DateTime.now());
        await (_database.update(_database.recurringExpenses)..where((r) => r.id.equals(recurringExpense.id)))
            .write(updated.toCompanion());
        return Right(updated);
      } catch (e) {
        appLogger.e('Error updating recurring expense', error: e);
        return Left(DatabaseFailure('Error al actualizar gasto recurrente: ${e.toString()}'));
      }
    });
  }

  /// Elimina un gasto recurrente (soft delete)
  Future<Result<void>> deleteRecurringExpense(String id) async {
    return await _lock.synchronized(() async {
      try {
        await (_database.update(_database.recurringExpenses)..where((r) => r.id.equals(id)))
            .write(db.RecurringExpensesCompanion(
              isDeleted: const Value(true),
              updatedAt: Value(DateTime.now()),
            ));
        return const Right(null);
      } catch (e) {
        appLogger.e('Error deleting recurring expense', error: e);
        return Left(DatabaseFailure('Error al eliminar gasto recurrente: ${e.toString()}'));
      }
    });
  }

  // ==================== INGRESOS RECURRENTES ====================

  /// Obtiene todos los ingresos recurrentes
  Future<Result<List<RecurringIncome>>> getAllRecurringIncomes({
    bool includeDeleted = false,
    bool activeOnly = false,
  }) async {
    appLogger.d('getAllRecurringIncomes: iniciando, activeOnly=$activeOnly');
    return await _lock.synchronized(() async {
      try {
        appLogger.d('getAllRecurringIncomes: dentro del lock, creando query');
        var query = _database.select(_database.recurringIncomes);
        if (!includeDeleted) {
          query = query..where((r) => r.isDeleted.equals(false));
        }
        if (activeOnly) {
          query = query..where((r) => r.isActive.equals(true));
        }
        query = query..orderBy([(r) => OrderingTerm.desc(r.createdAt)]);
        appLogger.d('getAllRecurringIncomes: ejecutando query');
        final results = await query.get();
        appLogger.d('getAllRecurringIncomes: query ejecutada, resultados: ${results.length}');
        
        // Cargar categorías (usar versión interna sin lock ya que estamos dentro del lock)
        final categoryMap = <String, Category>{};
        appLogger.d('getAllRecurringIncomes: cargando categorías para ${results.length} ingresos recurrentes');
        for (final recurring in results) {
          if (!categoryMap.containsKey(recurring.categoryId)) {
            appLogger.d('getAllRecurringIncomes: cargando categoría ${recurring.categoryId}');
            final catResult = await _getCategoryByIdInternal(recurring.categoryId);
            catResult.fold(
              (l) => null,
              (r) => r?.let((cat) => categoryMap[recurring.categoryId] = cat),
            );
          }
        }
        appLogger.d('getAllRecurringIncomes: categorías cargadas, creando entidades');
        
        final recurringIncomes = results.map((r) => r.toEntity(category: categoryMap[r.categoryId])).toList();
        appLogger.d('getAllRecurringIncomes: completado, ${recurringIncomes.length} ingresos recurrentes');
        return Right(recurringIncomes);
      } catch (e, stackTrace) {
        appLogger.e('Error getting recurring incomes', error: e, stackTrace: stackTrace);
        return Left(DatabaseFailure('Error al obtener ingresos recurrentes: ${e.toString()}'));
      }
    });
  }

  /// Crea un ingreso recurrente
  Future<Result<RecurringIncome>> createRecurringIncome(RecurringIncome recurringIncome) async {
    return await _lock.synchronized(() async {
      try {
        await _database.into(_database.recurringIncomes).insert(recurringIncome.toCompanion());
        return Right(recurringIncome);
      } catch (e) {
        appLogger.e('Error creating recurring income', error: e);
        return Left(DatabaseFailure('Error al crear ingreso recurrente: ${e.toString()}'));
      }
    });
  }

  /// Actualiza un ingreso recurrente
  Future<Result<RecurringIncome>> updateRecurringIncome(RecurringIncome recurringIncome) async {
    return await _lock.synchronized(() async {
      try {
        final updated = recurringIncome.copyWith(updatedAt: DateTime.now());
        await (_database.update(_database.recurringIncomes)..where((r) => r.id.equals(recurringIncome.id)))
            .write(updated.toCompanion());
        return Right(updated);
      } catch (e) {
        appLogger.e('Error updating recurring income', error: e);
        return Left(DatabaseFailure('Error al actualizar ingreso recurrente: ${e.toString()}'));
      }
    });
  }

  /// Elimina un ingreso recurrente (soft delete)
  Future<Result<void>> deleteRecurringIncome(String id) async {
    return await _lock.synchronized(() async {
      try {
        await (_database.update(_database.recurringIncomes)..where((r) => r.id.equals(id)))
            .write(db.RecurringIncomesCompanion(
              isDeleted: const Value(true),
              updatedAt: Value(DateTime.now()),
            ));
        return const Right(null);
      } catch (e) {
        appLogger.e('Error deleting recurring income', error: e);
        return Left(DatabaseFailure('Error al eliminar ingreso recurrente: ${e.toString()}'));
      }
    });
  }

  // ==================== OBJETIVOS DE AHORRO ====================

  /// Obtiene todos los objetivos de ahorro
  Future<Result<List<SavingsGoal>>> getAllSavingsGoals({
    bool includeDeleted = false,
    bool activeOnly = false,
  }) async {
    return await _lock.synchronized(() async {
      try {
        var query = _database.select(_database.savingsGoals);
        if (!includeDeleted) {
          query = query..where((s) => s.isDeleted.equals(false));
        }
        if (activeOnly) {
          query = query..where((s) => s.isCompleted.equals(false));
        }
        query = query..orderBy([(s) => OrderingTerm.desc(s.createdAt)]);
        final results = await query.get();
        final savingsGoals = results.map((r) => r.toEntity()).toList();
        return Right(savingsGoals);
      } catch (e) {
        appLogger.e('Error getting savings goals', error: e);
        return Left(DatabaseFailure('Error al obtener objetivos de ahorro: ${e.toString()}'));
      }
    });
  }

  /// Crea un objetivo de ahorro
  Future<Result<SavingsGoal>> createSavingsGoal(SavingsGoal savingsGoal) async {
    return await _lock.synchronized(() async {
      try {
        await _database.into(_database.savingsGoals).insert(savingsGoal.toCompanion());
        return Right(savingsGoal);
      } catch (e) {
        appLogger.e('Error creating savings goal', error: e);
        return Left(DatabaseFailure('Error al crear objetivo de ahorro: ${e.toString()}'));
      }
    });
  }

  /// Actualiza un objetivo de ahorro
  Future<Result<SavingsGoal>> updateSavingsGoal(SavingsGoal savingsGoal) async {
    return await _lock.synchronized(() async {
      try {
        final updated = savingsGoal.copyWith(updatedAt: DateTime.now());
        await (_database.update(_database.savingsGoals)..where((s) => s.id.equals(savingsGoal.id)))
            .write(updated.toCompanion());
        return Right(updated);
      } catch (e) {
        appLogger.e('Error updating savings goal', error: e);
        return Left(DatabaseFailure('Error al actualizar objetivo de ahorro: ${e.toString()}'));
      }
    });
  }

  /// Elimina un objetivo de ahorro (soft delete)
  Future<Result<void>> deleteSavingsGoal(String id) async {
    return await _lock.synchronized(() async {
      try {
        await (_database.update(_database.savingsGoals)..where((s) => s.id.equals(id)))
            .write(db.SavingsGoalsCompanion(
              isDeleted: const Value(true),
              updatedAt: Value(DateTime.now()),
            ));
        return const Right(null);
      } catch (e) {
        appLogger.e('Error deleting savings goal', error: e);
        return Left(DatabaseFailure('Error al eliminar objetivo de ahorro: ${e.toString()}'));
      }
    });
  }

  // ==================== TAGS ====================

  /// Obtiene todas las etiquetas
  Future<Result<List<Tag>>> getAllTags({bool includeDeleted = false}) async {
    return await _lock.synchronized(() async {
      try {
        var query = _database.select(_database.tags);
        if (!includeDeleted) {
          query = query..where((t) => t.isDeleted.equals(false));
        }
        query = query..orderBy([(t) => OrderingTerm.asc(t.name)]);
        final results = await query.get();
        final tags = results.map((r) => r.toEntity()).toList();
        return Right(tags);
      } catch (e) {
        appLogger.e('Error getting tags', error: e);
        return Left(DatabaseFailure('Error al obtener etiquetas: ${e.toString()}'));
      }
    });
  }

  /// Crea una etiqueta
  Future<Result<Tag>> createTag(Tag tag) async {
    return await _lock.synchronized(() async {
      try {
        await _database.into(_database.tags).insert(tag.toCompanion());
        return Right(tag);
      } catch (e) {
        appLogger.e('Error creating tag', error: e);
        return Left(DatabaseFailure('Error al crear etiqueta: ${e.toString()}'));
      }
    });
  }

  /// Actualiza una etiqueta
  Future<Result<Tag>> updateTag(Tag tag) async {
    return await _lock.synchronized(() async {
      try {
        final updated = tag.copyWith(updatedAt: DateTime.now());
        await (_database.update(_database.tags)..where((t) => t.id.equals(tag.id)))
            .write(updated.toCompanion());
        return Right(updated);
      } catch (e) {
        appLogger.e('Error updating tag', error: e);
        return Left(DatabaseFailure('Error al actualizar etiqueta: ${e.toString()}'));
      }
    });
  }

  /// Elimina una etiqueta (soft delete)
  Future<Result<void>> deleteTag(String id) async {
    return await _lock.synchronized(() async {
      try {
        await (_database.update(_database.tags)..where((t) => t.id.equals(id)))
            .write(db.TagsCompanion(
              isDeleted: const Value(true),
              updatedAt: Value(DateTime.now()),
            ));
        return const Right(null);
      } catch (e) {
        appLogger.e('Error deleting tag', error: e);
        return Left(DatabaseFailure('Error al eliminar etiqueta: ${e.toString()}'));
      }
    });
  }

  // ==================== FACTURAS ====================

  /// Obtiene todas las facturas
  Future<Result<List<Bill>>> getAllBills({
    bool includeDeleted = false,
    bool unpaidOnly = false,
  }) async {
    return await _lock.synchronized(() async {
      try {
        var query = _database.select(_database.bills);
        if (!includeDeleted) {
          query = query..where((b) => b.isDeleted.equals(false));
        }
        if (unpaidOnly) {
          query = query..where((b) => b.isPaid.equals(false));
        }
        query = query..orderBy([(b) => OrderingTerm.asc(b.dueDate)]);
        final results = await query.get();
        
        // Cargar categorías
        final bills = <Bill>[];
        for (final result in results) {
          db.Category? categoryData;
          if (result.categoryId != null) {
            final categoryQuery = _database.select(_database.categories)
              ..where((c) => c.id.equals(result.categoryId!));
            categoryData = await categoryQuery.getSingleOrNull();
          }
          bills.add(result.toEntity(category: categoryData));
        }
        
        return Right(bills);
      } catch (e) {
        appLogger.e('Error getting bills', error: e);
        return Left(DatabaseFailure('Error al obtener facturas: ${e.toString()}'));
      }
    });
  }

  /// Crea una factura
  Future<Result<Bill>> createBill(Bill bill) async {
    return await _lock.synchronized(() async {
      try {
        await _database.into(_database.bills).insert(bill.toCompanion());
        return Right(bill);
      } catch (e) {
        appLogger.e('Error creating bill', error: e);
        return Left(DatabaseFailure('Error al crear factura: ${e.toString()}'));
      }
    });
  }

  /// Actualiza una factura
  Future<Result<Bill>> updateBill(Bill bill) async {
    return await _lock.synchronized(() async {
      try {
        final updated = bill.copyWith(updatedAt: DateTime.now());
        await (_database.update(_database.bills)..where((b) => b.id.equals(bill.id)))
            .write(updated.toCompanion());
        return Right(updated);
      } catch (e) {
        appLogger.e('Error updating bill', error: e);
        return Left(DatabaseFailure('Error al actualizar factura: ${e.toString()}'));
      }
    });
  }

  /// Elimina una factura (soft delete)
  Future<Result<void>> deleteBill(String id) async {
    return await _lock.synchronized(() async {
      try {
        await (_database.update(_database.bills)..where((b) => b.id.equals(id)))
            .write(db.BillsCompanion(
              isDeleted: const Value(true),
              updatedAt: Value(DateTime.now()),
            ));
        return const Right(null);
      } catch (e) {
        appLogger.e('Error deleting bill', error: e);
        return Left(DatabaseFailure('Error al eliminar factura: ${e.toString()}'));
      }
    });
  }

  // ==================== GASTOS COMPARTIDOS ====================

  /// Obtiene todos los gastos compartidos
  Future<Result<List<SharedExpense>>> getAllSharedExpenses({
    bool includeDeleted = false,
  }) async {
    return await _lock.synchronized(() async {
      try {
        var query = _database.select(_database.sharedExpenses);
        if (!includeDeleted) {
          query = query..where((se) => se.isDeleted.equals(false));
        }
        query = query..orderBy([(se) => OrderingTerm.desc(se.createdAt)]);
        
        final results = await query.get();
        
        // Cargar gastos asociados
        final expenseMap = <String, Expense>{};
        for (final sharedExpense in results) {
          if (!expenseMap.containsKey(sharedExpense.expenseId)) {
            final expenseResult = await _getExpenseByIdInternal(sharedExpense.expenseId);
            expenseResult.fold(
              (l) => null,
              (r) => r?.let((exp) => expenseMap[sharedExpense.expenseId] = exp),
            );
          }
        }
        
        final sharedExpenses = results.map((r) => 
          r.toEntity(expense: expenseMap[r.expenseId])
        ).toList();
        
        return Right(sharedExpenses);
      } catch (e) {
        appLogger.e('Error getting shared expenses', error: e);
        return Left(DatabaseFailure('Error al obtener gastos compartidos: ${e.toString()}'));
      }
    });
  }

  /// Obtiene un gasto compartido por ID
  Future<Result<SharedExpense?>> getSharedExpenseById(String id) async {
    return await _lock.synchronized(() async {
      try {
        final result = await (_database.select(_database.sharedExpenses)
          ..where((se) => se.id.equals(id)))
          .getSingleOrNull();
        
        if (result == null) {
          return const Right(null);
        }
        
        // Cargar gasto asociado
        final expenseResult = await _getExpenseByIdInternal(result.expenseId);
        final expense = expenseResult.fold(
          (l) => null,
          (r) => r,
        );
        
        return Right(result.toEntity(expense: expense));
      } catch (e) {
        appLogger.e('Error getting shared expense by id', error: e);
        return Left(DatabaseFailure('Error al obtener gasto compartido: ${e.toString()}'));
      }
    });
  }

  /// Crea un gasto compartido
  Future<Result<SharedExpense>> createSharedExpense(SharedExpense sharedExpense) async {
    return await _lock.synchronized(() async {
      try {
        await _database.into(_database.sharedExpenses).insert(sharedExpense.toCompanion());
        return Right(sharedExpense);
      } catch (e) {
        appLogger.e('Error creating shared expense', error: e);
        return Left(DatabaseFailure('Error al crear gasto compartido: ${e.toString()}'));
      }
    });
  }

  /// Actualiza un gasto compartido
  Future<Result<SharedExpense>> updateSharedExpense(SharedExpense sharedExpense) async {
    return await _lock.synchronized(() async {
      try {
        final updated = sharedExpense.copyWith(updatedAt: DateTime.now());
        await (_database.update(_database.sharedExpenses)
          ..where((se) => se.id.equals(sharedExpense.id)))
          .write(updated.toCompanion());
        return Right(updated);
      } catch (e) {
        appLogger.e('Error updating shared expense', error: e);
        return Left(DatabaseFailure('Error al actualizar gasto compartido: ${e.toString()}'));
      }
    });
  }

  /// Elimina un gasto compartido (soft delete)
  Future<Result<void>> deleteSharedExpense(String id) async {
    return await _lock.synchronized(() async {
      try {
        await (_database.update(_database.sharedExpenses)
          ..where((se) => se.id.equals(id)))
          .write(db.SharedExpensesCompanion(
            isDeleted: const Value(true),
            updatedAt: Value(DateTime.now()),
          ));
        return const Right(null);
      } catch (e) {
        appLogger.e('Error deleting shared expense', error: e);
        return Left(DatabaseFailure('Error al eliminar gasto compartido: ${e.toString()}'));
      }
    });
  }

  /// Método interno para obtener un gasto por ID (sin lock, para uso interno)
  Future<Result<Expense?>> _getExpenseByIdInternal(String id) async {
    try {
      final result = await (_database.select(_database.expenses)
        ..where((e) => e.id.equals(id) & e.isDeleted.equals(false)))
        .getSingleOrNull();
      
      if (result == null) {
        return const Right(null);
      }
      
      // Cargar categoría
      final categoryMap = <String, Category>{};
      if (!categoryMap.containsKey(result.categoryId)) {
        final catResult = await _getCategoryByIdInternal(result.categoryId);
        catResult.fold(
          (l) => null,
          (r) => r?.let((cat) => categoryMap[result.categoryId] = cat),
        );
      }
      
      return Right(result.toEntity(category: categoryMap[result.categoryId]));
    } catch (e) {
      appLogger.e('Error getting expense by id internal', error: e);
      return Left(DatabaseFailure('Error al obtener gasto: ${e.toString()}'));
    }
  }

  /// Cierra la base de datos
  Future<void> close() async {
    await _database.close();
  }
}

/// Extensión para facilitar el uso de Option
extension OptionExtension<T> on T? {
  void let(void Function(T) action) {
    if (this != null) {
      action(this as T);
    }
  }
}

