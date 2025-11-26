import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_contabilidad/core/providers/providers.dart';
import 'package:app_contabilidad/data/datasources/local/database_service.dart';
import 'package:app_contabilidad/core/utils/result.dart';
import 'package:app_contabilidad/core/utils/logger.dart';
import 'package:app_contabilidad/domain/entities/expense.dart';
import 'package:app_contabilidad/domain/entities/income.dart';
import 'package:app_contabilidad/domain/entities/budget.dart';
import 'package:app_contabilidad/domain/entities/savings_goal.dart';

/// Estado del dashboard
class DashboardState {
  final double totalExpenses;
  final double totalIncomes;
  final double balance;
  final List<Expense> recentExpenses;
  final List<Income> recentIncomes;
  final List<Budget> activeBudgets;
  final List<SavingsGoal> savingsGoals;
  final Map<String, double> expensesByCategory;
  final Map<String, double> incomesByCategory;
  final bool isLoading;
  final String? error;

  DashboardState({
    this.totalExpenses = 0.0,
    this.totalIncomes = 0.0,
    this.balance = 0.0,
    this.recentExpenses = const [],
    this.recentIncomes = const [],
    this.activeBudgets = const [],
    this.savingsGoals = const [],
    this.expensesByCategory = const {},
    this.incomesByCategory = const {},
    this.isLoading = false,
    this.error,
  });

  DashboardState copyWith({
    double? totalExpenses,
    double? totalIncomes,
    double? balance,
    List<Expense>? recentExpenses,
    List<Income>? recentIncomes,
    List<Budget>? activeBudgets,
    List<SavingsGoal>? savingsGoals,
    Map<String, double>? expensesByCategory,
    Map<String, double>? incomesByCategory,
    bool? isLoading,
    String? error,
  }) {
    return DashboardState(
      totalExpenses: totalExpenses ?? this.totalExpenses,
      totalIncomes: totalIncomes ?? this.totalIncomes,
      balance: balance ?? this.balance,
      recentExpenses: recentExpenses ?? this.recentExpenses,
      recentIncomes: recentIncomes ?? this.recentIncomes,
      activeBudgets: activeBudgets ?? this.activeBudgets,
      savingsGoals: savingsGoals ?? this.savingsGoals,
      expensesByCategory: expensesByCategory ?? this.expensesByCategory,
      incomesByCategory: incomesByCategory ?? this.incomesByCategory,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// ViewModel del dashboard
class DashboardViewModel extends StateNotifier<DashboardState> {
  final DatabaseService _databaseService;

  DashboardViewModel(this._databaseService) : super(DashboardState()) {
    // Cargar datos iniciales
    loadDashboardData();
  }

  /// Carga todos los datos del dashboard
  Future<void> loadDashboardData({bool forceRefresh = false}) async {
    // Si ya hay datos y no es un refresh forzado, no cargar
    if (!forceRefresh && 
        state.totalExpenses != 0 && 
        state.totalIncomes != 0 && 
        !state.isLoading) {
      return;
    }
    
    // Si ya está cargando y no es un refresh forzado, no iniciar otra carga
    if (state.isLoading && !forceRefresh) {
      return;
    }
    
    // Si es un refresh forzado, siempre ejecutar (ignorar si está cargando)
    if (forceRefresh && state.isLoading) {
      // Esperar un poco para que termine cualquier operación en progreso
      await Future.delayed(const Duration(milliseconds: 300));
      // Continuar con el refresh forzado
    }
    
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Obtener fecha del mes actual
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1);
      final endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      // Cargar gastos del mes
      final expensesResult = await _databaseService.getAllExpenses(
        startDate: startDate,
        endDate: endDate,
      );

      // Cargar ingresos del mes
      final incomesResult = await _databaseService.getAllIncomes(
        startDate: startDate,
        endDate: endDate,
      );

      // Cargar presupuestos activos
      final budgetsResult = await _databaseService.getAllBudgets();

      // Cargar objetivos de ahorro (solo activos, no completados)
      final savingsGoalsResult = await _databaseService.getAllSavingsGoals(activeOnly: true);

      if (expensesResult.isFailure || incomesResult.isFailure || budgetsResult.isFailure || savingsGoalsResult.isFailure) {
        state = state.copyWith(
          isLoading: false,
          error: 'Error al cargar datos del dashboard',
        );
        return;
      }

      final expenses = (expensesResult.valueOrNull ?? []) as List<Expense>;
      final incomes = (incomesResult.valueOrNull ?? []) as List<Income>;
      final budgets = (budgetsResult.valueOrNull ?? []) as List<Budget>;
      final savingsGoals = (savingsGoalsResult.valueOrNull ?? []) as List<SavingsGoal>;

      // Calcular totales
      final totalExpenses = expenses.fold<double>(0, (sum, e) => sum + e.amount);
      final totalIncomes = incomes.fold<double>(0, (sum, i) => sum + i.amount);
      final balance = totalIncomes - totalExpenses;

      // Gastos recientes (últimos 5)
      final recentExpenses = expenses.take(5).toList();

      // Ingresos recientes (últimos 5)
      final recentIncomes = incomes.take(5).toList();

      // Presupuestos activos
      final activeBudgets = budgets.where((b) => b.isActive(now)).toList();

      // Gastos por categoría
      final expensesByCategory = <String, double>{};
      for (final expense in expenses) {
        final categoryName = expense.category?.name ?? 'Sin categoría';
        expensesByCategory[categoryName] =
            (expensesByCategory[categoryName] ?? 0) + expense.amount;
      }

      // Ingresos por categoría
      final incomesByCategory = <String, double>{};
      for (final income in incomes) {
        final categoryName = income.category?.name ?? 'Sin categoría';
        incomesByCategory[categoryName] =
            (incomesByCategory[categoryName] ?? 0) + income.amount;
      }

      state = state.copyWith(
        totalExpenses: totalExpenses,
        totalIncomes: totalIncomes,
        balance: balance,
        recentExpenses: recentExpenses,
        recentIncomes: recentIncomes,
        activeBudgets: activeBudgets,
        savingsGoals: savingsGoals,
        expensesByCategory: expensesByCategory,
        incomesByCategory: incomesByCategory,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      appLogger.e('Error loading dashboard data', error: e);
      state = state.copyWith(
        isLoading: false,
        error: 'Error inesperado: ${e.toString()}',
      );
    }
  }

  /// Refresca los datos del dashboard
  Future<void> refresh() async {
    // Forzar refresh incluso si está cargando
    await loadDashboardData(forceRefresh: true);
  }
  
  /// Actualiza el dashboard cuando se crea/actualiza/elimina un gasto o ingreso
  Future<void> updateOnDataChange() async {
    // Solo actualizar si no está cargando para evitar conflictos
    if (!state.isLoading) {
      await loadDashboardData(forceRefresh: true);
    }
  }
  
  /// Actualiza el dashboard con un nuevo gasto (sin recargar todo)
  Future<void> addExpenseToDashboard(Expense expense) async {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    final endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    
    // Solo actualizar si el gasto pertenece al mes actual
    if (expense.date.isBefore(startDate) || expense.date.isAfter(endDate)) {
      appLogger.w('Gasto no pertenece al mes actual, no se actualiza el dashboard');
      return;
    }
    
    // Cargar categoría si no está disponible
    Expense expenseWithCategory = expense;
    if (expense.category == null) {
      try {
        final catResult = await _databaseService.getCategoryById(expense.categoryId);
        await catResult.fold(
          (failure) async {
            appLogger.w('No se pudo cargar la categoría para el gasto: ${failure.message}');
          },
          (category) async {
            if (category != null) {
              expenseWithCategory = expense.copyWith(category: category);
            } else {
              appLogger.w('Categoría no encontrada para el gasto: ${expense.categoryId}');
            }
          },
        );
      } catch (e) {
        appLogger.e('Error cargando categoría para gasto', error: e);
      }
    }
    
    // Actualizar totales
    final newTotalExpenses = state.totalExpenses + expenseWithCategory.amount;
    final newBalance = state.totalIncomes - newTotalExpenses;
    
    // Agregar a gastos recientes (máximo 5)
    final newRecentExpenses = List<Expense>.from(state.recentExpenses);
    newRecentExpenses.insert(0, expenseWithCategory);
    if (newRecentExpenses.length > 5) {
      newRecentExpenses.removeLast();
    }
    
    // Actualizar gastos por categoría
    final newExpensesByCategory = Map<String, double>.from(state.expensesByCategory);
    final categoryName = expenseWithCategory.category?.name ?? 'Sin categoría';
    newExpensesByCategory[categoryName] = (newExpensesByCategory[categoryName] ?? 0) + expenseWithCategory.amount;
    
    state = state.copyWith(
      totalExpenses: newTotalExpenses,
      balance: newBalance,
      recentExpenses: newRecentExpenses,
      expensesByCategory: newExpensesByCategory,
    );
    
    appLogger.d('Dashboard actualizado con nuevo gasto: ${expenseWithCategory.description}');
  }
  
  /// Actualiza el dashboard con un nuevo ingreso (sin recargar todo)
  Future<void> addIncomeToDashboard(Income income) async {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    final endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    
    // Solo actualizar si el ingreso pertenece al mes actual
    if (income.date.isBefore(startDate) || income.date.isAfter(endDate)) {
      return;
    }
    
    // Cargar categoría si no está disponible
    Income incomeWithCategory = income;
    if (income.category == null) {
      try {
        final catResult = await _databaseService.getCategoryById(income.categoryId);
        catResult.fold(
          (failure) {
            appLogger.w('No se pudo cargar la categoría para el ingreso: ${failure.message}');
          },
          (category) {
            if (category != null) {
              incomeWithCategory = income.copyWith(category: category);
            } else {
              appLogger.w('Categoría no encontrada para el ingreso: ${income.categoryId}');
            }
          },
        );
      } catch (e) {
        appLogger.e('Error cargando categoría para ingreso', error: e);
      }
    }
    
    // Actualizar totales
    final newTotalIncomes = state.totalIncomes + incomeWithCategory.amount;
    final newBalance = newTotalIncomes - state.totalExpenses;
    
    // Agregar a ingresos recientes (máximo 5)
    final newRecentIncomes = List<Income>.from(state.recentIncomes);
    newRecentIncomes.insert(0, incomeWithCategory);
    if (newRecentIncomes.length > 5) {
      newRecentIncomes.removeLast();
    }
    
    // Actualizar ingresos por categoría
    final newIncomesByCategory = Map<String, double>.from(state.incomesByCategory);
    final categoryName = incomeWithCategory.category?.name ?? 'Sin categoría';
    newIncomesByCategory[categoryName] = (newIncomesByCategory[categoryName] ?? 0) + incomeWithCategory.amount;
    
    state = state.copyWith(
      totalIncomes: newTotalIncomes,
      balance: newBalance,
      recentIncomes: newRecentIncomes,
      incomesByCategory: newIncomesByCategory,
    );
  }
  
  /// Actualiza un objetivo de ahorro en el dashboard (sin recargar todo)
  void updateSavingsGoalInDashboard(SavingsGoal updatedGoal) {
    final currentGoals = List<SavingsGoal>.from(state.savingsGoals);
    final index = currentGoals.indexWhere((g) => g.id == updatedGoal.id);
    
    if (index != -1) {
      // Actualizar el objetivo existente
      currentGoals[index] = updatedGoal;
      state = state.copyWith(savingsGoals: currentGoals);
      appLogger.d('Dashboard actualizado con objetivo de ahorro: ${updatedGoal.name}');
    } else {
      // Si no está en la lista, podría ser nuevo, recargar todo
      appLogger.d('Objetivo no encontrado en dashboard, recargando...');
      loadDashboardData(forceRefresh: true);
    }
  }
}

/// Provider del ViewModel del dashboard
final dashboardViewModelProvider =
    StateNotifierProvider.autoDispose<DashboardViewModel, DashboardState>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  final viewModel = DashboardViewModel(databaseService);
  // Mantener el provider vivo para evitar recargas innecesarias
  ref.keepAlive();
  return viewModel;
});


