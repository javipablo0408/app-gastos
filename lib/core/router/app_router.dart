import 'package:go_router/go_router.dart';
import 'package:app_contabilidad/presentation/pages/splash_page.dart';
import 'package:app_contabilidad/presentation/pages/dashboard_page.dart';
import 'package:app_contabilidad/presentation/pages/expenses_list_page.dart';
import 'package:app_contabilidad/presentation/pages/incomes_list_page.dart';
import 'package:app_contabilidad/presentation/pages/expense_form_page.dart';
import 'package:app_contabilidad/presentation/pages/income_form_page.dart';
import 'package:app_contabilidad/presentation/pages/categories_page.dart';
import 'package:app_contabilidad/presentation/pages/budgets_page.dart';
import 'package:app_contabilidad/presentation/pages/settings_page.dart';
import 'package:app_contabilidad/presentation/pages/sync_page.dart';
import 'package:app_contabilidad/presentation/pages/search_page.dart';
import 'package:app_contabilidad/presentation/pages/recurring_expenses_page.dart';
import 'package:app_contabilidad/presentation/pages/recurring_incomes_page.dart';
import 'package:app_contabilidad/presentation/pages/savings_goals_page.dart';
import 'package:app_contabilidad/presentation/pages/statistics_page.dart';
import 'package:app_contabilidad/presentation/pages/tags_page.dart';
import 'package:app_contabilidad/presentation/pages/bills_page.dart';
import 'package:app_contabilidad/presentation/pages/shared_expenses_page.dart';
import 'package:app_contabilidad/presentation/pages/debt_analysis_page.dart';
import 'package:app_contabilidad/presentation/pages/period_comparison_page.dart';

/// Configuración de rutas de la aplicación
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: '/dashboard',
      name: 'dashboard',
      builder: (context, state) => const DashboardPage(),
    ),
    GoRoute(
      path: '/expenses',
      name: 'expenses',
      builder: (context, state) => const ExpensesListPage(),
    ),
    GoRoute(
      path: '/expenses/new',
      name: 'expense-new',
      builder: (context, state) => const ExpenseFormPage(),
    ),
    GoRoute(
      path: '/expenses/:id',
      name: 'expense-edit',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return ExpenseFormPage(expenseId: id);
      },
    ),
    GoRoute(
      path: '/incomes',
      name: 'incomes',
      builder: (context, state) => const IncomesListPage(),
    ),
    GoRoute(
      path: '/incomes/new',
      name: 'income-new',
      builder: (context, state) => const IncomeFormPage(),
    ),
    GoRoute(
      path: '/incomes/:id',
      name: 'income-edit',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return IncomeFormPage(incomeId: id);
      },
    ),
    GoRoute(
      path: '/categories',
      name: 'categories',
      builder: (context, state) => const CategoriesPage(),
    ),
    GoRoute(
      path: '/budgets',
      name: 'budgets',
      builder: (context, state) => const BudgetsPage(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: '/sync',
      name: 'sync',
      builder: (context, state) => const SyncPage(),
    ),
    GoRoute(
      path: '/search',
      name: 'search',
      builder: (context, state) => const SearchPage(),
    ),
    GoRoute(
      path: '/recurring-expenses',
      name: 'recurring-expenses',
      builder: (context, state) => const RecurringExpensesPage(),
    ),
    GoRoute(
      path: '/recurring-incomes',
      name: 'recurring-incomes',
      builder: (context, state) => const RecurringIncomesPage(),
    ),
    GoRoute(
      path: '/savings-goals',
      name: 'savings-goals',
      builder: (context, state) => const SavingsGoalsPage(),
    ),
    GoRoute(
      path: '/statistics',
      name: 'statistics',
      builder: (context, state) => const StatisticsPage(),
    ),
    GoRoute(
      path: '/tags',
      name: 'tags',
      builder: (context, state) => const TagsPage(),
    ),
    GoRoute(
      path: '/bills',
      name: 'bills',
      builder: (context, state) => const BillsPage(),
    ),
    GoRoute(
      path: '/shared-expenses',
      name: 'shared-expenses',
      builder: (context, state) => const SharedExpensesPage(),
    ),
    GoRoute(
      path: '/debt-analysis',
      name: 'debt-analysis',
      builder: (context, state) => const DebtAnalysisPage(),
    ),
    GoRoute(
      path: '/period-comparison',
      name: 'period-comparison',
      builder: (context, state) => const PeriodComparisonPage(),
    ),
  ],
);

