import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:app_contabilidad/presentation/viewmodels/dashboard_viewmodel.dart';
import 'package:app_contabilidad/presentation/viewmodels/expenses_viewmodel.dart';
import 'package:app_contabilidad/presentation/viewmodels/incomes_viewmodel.dart';
import 'package:app_contabilidad/presentation/viewmodels/recurring_expenses_viewmodel.dart';
import 'package:app_contabilidad/presentation/viewmodels/recurring_incomes_viewmodel.dart';
import 'package:app_contabilidad/presentation/viewmodels/categories_viewmodel.dart';
import 'package:app_contabilidad/domain/entities/recurring_expense.dart';
import 'package:app_contabilidad/domain/entities/recurring_income.dart';
import 'package:app_contabilidad/domain/entities/category.dart';
import 'package:app_contabilidad/domain/entities/expense.dart';
import 'package:app_contabilidad/domain/entities/income.dart';
import 'package:app_contabilidad/core/widgets/loading_widget.dart';
import 'package:app_contabilidad/core/widgets/error_widget.dart';
import 'package:app_contabilidad/presentation/widgets/bottom_navigation.dart';

/// Página principal del dashboard
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardViewModelProvider);
    final dashboardViewModel = ref.read(dashboardViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => context.push('/statistics'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => dashboardViewModel.refresh(),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: dashboardState.isLoading
          ? const LoadingWidget()
              : dashboardState.error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dashboardState.error!,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => dashboardViewModel.refresh(),
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    )
              : RefreshIndicator(
                  onRefresh: () => dashboardViewModel.refresh(),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Resumen financiero
                        _buildSummaryCards(context, dashboardState),
                        const SizedBox(height: 24),

                        // Calendario
                        _buildSectionTitle(context, 'Calendario'),
                        const SizedBox(height: 16),
                        _buildCalendar(context, dashboardState),
                        const SizedBox(height: 24),

                        // Gráfico de gastos por categoría
                        if (dashboardState.expensesByCategory.isNotEmpty) ...[
                          _buildSectionTitle(context, 'Gastos por Categoría'),
                          const SizedBox(height: 16),
                          _buildExpensesChart(context, dashboardState),
                          const SizedBox(height: 24),
                        ],

                        // Gráfico de ingresos por categoría
                        if (dashboardState.incomesByCategory.isNotEmpty) ...[
                          _buildSectionTitle(context, 'Ingresos por Categoría'),
                          const SizedBox(height: 16),
                          _buildIncomesChart(context, dashboardState),
                          const SizedBox(height: 24),
                        ],

                        // Presupuestos activos
                        if (dashboardState.activeBudgets.isNotEmpty) ...[
                          _buildSectionTitle(context, 'Presupuestos Activos'),
                          const SizedBox(height: 16),
                          _buildActiveBudgets(context, dashboardState),
                          const SizedBox(height: 24),
                        ],

                        // Objetivos de ahorro (siempre mostrar si hay)
                        _buildSectionTitle(context, 'Objetivos de Ahorro'),
                        const SizedBox(height: 16),
                        if (dashboardState.savingsGoals.isNotEmpty)
                          _buildSavingsGoals(context, dashboardState)
                        else
                          _buildEmptySavingsGoals(context),
                        const SizedBox(height: 24),

                        // Gastos recientes
                        if (dashboardState.recentExpenses.isNotEmpty) ...[
                          _buildSectionTitle(context, 'Gastos Recientes'),
                          const SizedBox(height: 16),
                          _buildRecentExpenses(context, dashboardState),
                          const SizedBox(height: 24),
                        ],

                        // Ingresos recientes
                        if (dashboardState.recentIncomes.isNotEmpty) ...[
                          _buildSectionTitle(context, 'Ingresos Recientes'),
                          const SizedBox(height: 16),
                          _buildRecentIncomes(context, dashboardState),
                        ],
                      ],
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
      bottomNavigationBar: BottomNavigation(currentIndex: 0),
    );
  }

  Widget _buildSummaryCards(BuildContext context, DashboardState state) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            context,
            'Ingresos',
            currencyFormat.format(state.totalIncomes),
            Colors.green,
            Icons.trending_up,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            context,
            'Gastos',
            currencyFormat.format(state.totalExpenses),
            Colors.red,
            Icons.trending_down,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            context,
            'Balance',
            currencyFormat.format(state.balance),
            state.balance >= 0 ? Colors.blue : Colors.orange,
            Icons.account_balance_wallet,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String amount,
    Color color,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              amount,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesChart(BuildContext context, DashboardState state) {
    final entries = state.expensesByCategory.entries.toList();
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.amber,
      Colors.yellow,
      Colors.lime,
      Colors.green,
      Colors.teal,
      Colors.blue,
      Colors.indigo,
      Colors.purple,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: entries.asMap().entries.map((entry) {
                    final index = entry.key;
                    final categoryEntry = entry.value;
                    final percentage = (categoryEntry.value / state.totalExpenses * 100);
                    return PieChartSectionData(
                      value: categoryEntry.value,
                      title: '${percentage.toStringAsFixed(1)}%',
                      color: colors[index % colors.length],
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Leyenda de categorías
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: entries.asMap().entries.map((entry) {
                final index = entry.key;
                final categoryName = entry.value.key;
                final amount = entry.value.value;
                final percentage = (amount / state.totalExpenses * 100);
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: colors[index % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$categoryName: ${currencyFormat.format(amount)} (${percentage.toStringAsFixed(1)}%)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomesChart(BuildContext context, DashboardState state) {
    final entries = state.incomesByCategory.entries.toList();
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final colors = [
      Colors.green,
      Colors.teal,
      Colors.cyan,
      Colors.blue,
      Colors.indigo,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: entries.asMap().entries.map((entry) {
                    final index = entry.key;
                    final categoryEntry = entry.value;
                    final percentage = (categoryEntry.value / state.totalIncomes * 100);
                    return PieChartSectionData(
                      value: categoryEntry.value,
                      title: '${percentage.toStringAsFixed(1)}%',
                      color: colors[index % colors.length],
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Leyenda de categorías
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: entries.asMap().entries.map((entry) {
                final index = entry.key;
                final categoryName = entry.value.key;
                final amount = entry.value.value;
                final percentage = (amount / state.totalIncomes * 100);
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: colors[index % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$categoryName: ${currencyFormat.format(amount)} (${percentage.toStringAsFixed(1)}%)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveBudgets(BuildContext context, DashboardState state) {
    return Column(
      children: state.activeBudgets.map((budget) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.account_balance_wallet, color: Colors.white),
            ),
            title: Text(budget.category?.name ?? 'Sin categoría'),
            subtitle: Text(
              '${NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(budget.amount)}',
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.push('/budgets'),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptySavingsGoals(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.savings, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No hay objetivos de ahorro',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea un objetivo para comenzar a ahorrar',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.push('/savings-goals'),
              icon: const Icon(Icons.add),
              label: const Text('Crear Objetivo'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavingsGoals(BuildContext context, DashboardState state) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    
    return Column(
      children: state.savingsGoals.take(3).map((goal) {
        final percentage = goal.getCompletionPercentage();
        final remaining = goal.getRemainingAmount();
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => context.push('/savings-goals'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              goal.name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            if (goal.description.isNotEmpty)
                              Text(
                                goal.description,
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      if (goal.isGoalReached())
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Completado',
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ahorrado',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            currencyFormat.format(goal.currentAmount),
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Objetivo',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            currencyFormat.format(goal.targetAmount),
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      goal.isGoalReached() ? Colors.green : Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${percentage.toStringAsFixed(1)}% completado',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (remaining > 0)
                        Text(
                          'Faltan ${currencyFormat.format(remaining)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                              ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentExpenses(BuildContext context, DashboardState state) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Column(
      children: state.recentExpenses.map((expense) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.red.shade100,
              child: const Icon(Icons.arrow_downward, color: Colors.red),
            ),
            title: Text(expense.description),
            subtitle: Text(
              '${expense.category?.name ?? 'Sin categoría'} • ${dateFormat.format(expense.date)}',
            ),
            trailing: Text(
              currencyFormat.format(expense.amount),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            onTap: () => context.push('/expenses/${expense.id}'),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentIncomes(BuildContext context, DashboardState state) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Column(
      children: state.recentIncomes.map((income) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade100,
              child: const Icon(Icons.arrow_upward, color: Colors.green),
            ),
            title: Text(income.description),
            subtitle: Text(
              '${income.category?.name ?? 'Sin categoría'} • ${dateFormat.format(income.date)}',
            ),
            trailing: Text(
              currencyFormat.format(income.amount),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            onTap: () => context.push('/incomes/${income.id}'),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildCalendar(BuildContext context, DashboardState state) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    
    // Crear mapas de eventos por fecha
    final Map<DateTime, List<dynamic>> events = {};
    
    // Agregar gastos
    for (final expense in state.recentExpenses) {
      final date = DateTime(expense.date.year, expense.date.month, expense.date.day);
      if (!events.containsKey(date)) {
        events[date] = [];
      }
      events[date]!.add({'type': 'expense', 'amount': expense.amount, 'description': expense.description});
    }
    
    // Agregar ingresos
    for (final income in state.recentIncomes) {
      final date = DateTime(income.date.year, income.date.month, income.date.day);
      if (!events.containsKey(date)) {
        events[date] = [];
      }
      events[date]!.add({'type': 'income', 'amount': income.amount, 'description': income.description});
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: DateTime.now(),
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.monday,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                outsideDaysVisible: false,
              ),
              eventLoader: (date) {
                final dateKey = DateTime(date.year, date.month, date.day);
                return events[dateKey] ?? [];
              },
              selectedDayPredicate: (day) {
                return isSameDay(DateTime.now(), day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                // Mostrar detalles del día seleccionado
                final dateKey = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
                final dayEvents = events[dateKey] ?? [];
                
                if (dayEvents.isNotEmpty) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(DateFormat('dd/MM/yyyy').format(selectedDay)),
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: dayEvents.map((event) {
                            final isExpense = event['type'] == 'expense';
                            return ListTile(
                              leading: Icon(
                                isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                                color: isExpense ? Colors.red : Colors.green,
                              ),
                              title: Text(event['description']),
                              trailing: Text(
                                currencyFormat.format(event['amount']),
                                style: TextStyle(
                                  color: isExpense ? Colors.red : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cerrar'),
                        ),
                      ],
                    ),
                  );
                }
              },
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (events.isNotEmpty) {
                    return Positioned(
                      bottom: 1,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Nuevo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.arrow_downward, color: Colors.red),
              title: const Text('Gasto'),
              onTap: () {
                Navigator.pop(context);
                context.push('/expenses/new');
              },
            ),
            ListTile(
              leading: const Icon(Icons.arrow_upward, color: Colors.green),
              title: const Text('Ingreso'),
              onTap: () {
                Navigator.pop(context);
                context.push('/incomes/new');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.repeat, color: Colors.red),
              title: const Text('Gasto Recurrente'),
              onTap: () {
                Navigator.pop(context);
                _showCreateRecurringExpenseDialog(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.repeat, color: Colors.green),
              title: const Text('Ingreso Recurrente'),
              onTap: () {
                Navigator.pop(context);
                _showCreateRecurringIncomeDialog(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateRecurringExpenseDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _RecurringExpenseFormDialog(
        onSave: (recurring) async {
          final viewModel = ref.read(recurringExpensesViewModelProvider.notifier);
          final result = await viewModel.createRecurringExpense(
            description: recurring.description,
            amount: recurring.amount,
            categoryId: recurring.categoryId,
            recurrenceType: recurring.recurrenceType,
            recurrenceValue: recurring.recurrenceValue,
            startDate: recurring.startDate,
            endDate: recurring.endDate,
          );
          if (context.mounted) {
            result.fold(
              (failure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(failure.message)),
                );
              },
              (_) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Gasto recurrente creado')),
                );
              },
            );
          }
        },
      ),
    );
  }

  void _showCreateRecurringIncomeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _RecurringIncomeFormDialog(
        onSave: (recurring) async {
          final viewModel = ref.read(recurringIncomesViewModelProvider.notifier);
          final result = await viewModel.createRecurringIncome(
            description: recurring.description,
            amount: recurring.amount,
            categoryId: recurring.categoryId,
            recurrenceType: recurring.recurrenceType,
            recurrenceValue: recurring.recurrenceValue,
            startDate: recurring.startDate,
            endDate: recurring.endDate,
          );
          if (context.mounted) {
            result.fold(
              (failure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(failure.message)),
                );
              },
              (_) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ingreso recurrente creado')),
                );
              },
            );
          }
        },
      ),
    );
  }
}

// Diálogo de formulario para gasto recurrente (reutilizado desde recurring_expenses_page)
class _RecurringExpenseFormDialog extends ConsumerStatefulWidget {
  final RecurringExpense? recurring;
  final Function(RecurringExpense) onSave;

  const _RecurringExpenseFormDialog({
    this.recurring,
    required this.onSave,
  });

  @override
  ConsumerState<_RecurringExpenseFormDialog> createState() => _RecurringExpenseFormDialogState();
}

class _RecurringExpenseFormDialogState extends ConsumerState<_RecurringExpenseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _recurrenceValueController = TextEditingController(text: '1');
  
  RecurrenceType _selectedRecurrenceType = RecurrenceType.monthly;
  String? _selectedCategoryId;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    if (widget.recurring != null) {
      final r = widget.recurring!;
      _descriptionController.text = r.description;
      _amountController.text = r.amount.toString();
      _recurrenceValueController.text = r.recurrenceValue.toString();
      _selectedRecurrenceType = r.recurrenceType;
      _selectedCategoryId = r.categoryId;
      _startDate = r.startDate;
      _endDate = r.endDate;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoriesViewModelProvider.notifier).loadCategories();
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _recurrenceValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(categoriesViewModelProvider);
    final categories = categoriesState.categories
        .where((c) => c.type == CategoryType.expense || c.type == CategoryType.both)
        .toList();

    return AlertDialog(
      title: Text(widget.recurring == null ? 'Nuevo Gasto Recurrente' : 'Editar Gasto Recurrente'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
              ),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Monto', prefixText: '\$ '),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Requerido';
                  if (double.tryParse(v!) == null) return 'Monto inválido';
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: categories.map((c) {
                  return DropdownMenuItem(value: c.id, child: Text(c.name));
                }).toList(),
                onChanged: (v) => setState(() => _selectedCategoryId = v),
                validator: (v) => v == null ? 'Requerido' : null,
              ),
              DropdownButtonFormField<RecurrenceType>(
                value: _selectedRecurrenceType,
                decoration: const InputDecoration(labelText: 'Tipo de recurrencia'),
                items: RecurrenceType.values.map((type) {
                  String label;
                  switch (type) {
                    case RecurrenceType.daily:
                      label = 'Diario';
                      break;
                    case RecurrenceType.weekly:
                      label = 'Semanal';
                      break;
                    case RecurrenceType.monthly:
                      label = 'Mensual';
                      break;
                    case RecurrenceType.yearly:
                      label = 'Anual';
                      break;
                  }
                  return DropdownMenuItem(value: type, child: Text(label));
                }).toList(),
                onChanged: (v) => setState(() => _selectedRecurrenceType = v!),
              ),
              TextFormField(
                controller: _recurrenceValueController,
                decoration: const InputDecoration(labelText: 'Cada cuántos'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Requerido';
                  if (int.tryParse(v!) == null || int.parse(v) <= 0) return 'Valor inválido';
                  return null;
                },
              ),
              ListTile(
                title: const Text('Fecha de inicio'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_startDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) setState(() => _startDate = date);
                },
              ),
              CheckboxListTile(
                title: const Text('Fecha de fin opcional'),
                value: _endDate != null,
                onChanged: (v) {
                  setState(() {
                    _endDate = v == true ? DateTime.now().add(const Duration(days: 365)) : null;
                  });
                },
              ),
              if (_endDate != null)
                ListTile(
                  title: const Text('Fecha de fin'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(_endDate!)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _endDate!,
                      firstDate: _startDate,
                      lastDate: DateTime(2100),
                    );
                    if (date != null) setState(() => _endDate = date);
                  },
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate() && _selectedCategoryId != null) {
              final recurring = RecurringExpense(
                id: widget.recurring?.id ?? '',
                description: _descriptionController.text,
                amount: double.parse(_amountController.text),
                categoryId: _selectedCategoryId!,
                recurrenceType: _selectedRecurrenceType,
                recurrenceValue: int.parse(_recurrenceValueController.text),
                startDate: _startDate,
                endDate: _endDate,
                lastExecuted: widget.recurring?.lastExecuted,
                isActive: widget.recurring?.isActive ?? true,
                createdAt: widget.recurring?.createdAt ?? DateTime.now(),
                updatedAt: DateTime.now(),
              );
              widget.onSave(recurring);
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

// Diálogo de formulario para ingreso recurrente (reutilizado desde recurring_incomes_page)
class _RecurringIncomeFormDialog extends ConsumerStatefulWidget {
  final RecurringIncome? recurring;
  final Function(RecurringIncome) onSave;

  const _RecurringIncomeFormDialog({
    this.recurring,
    required this.onSave,
  });

  @override
  ConsumerState<_RecurringIncomeFormDialog> createState() => _RecurringIncomeFormDialogState();
}

class _RecurringIncomeFormDialogState extends ConsumerState<_RecurringIncomeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _recurrenceValueController = TextEditingController(text: '1');
  
  RecurrenceType _selectedRecurrenceType = RecurrenceType.monthly;
  String? _selectedCategoryId;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    if (widget.recurring != null) {
      final r = widget.recurring!;
      _descriptionController.text = r.description;
      _amountController.text = r.amount.toString();
      _recurrenceValueController.text = r.recurrenceValue.toString();
      _selectedRecurrenceType = r.recurrenceType;
      _selectedCategoryId = r.categoryId;
      _startDate = r.startDate;
      _endDate = r.endDate;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoriesViewModelProvider.notifier).loadCategories();
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _recurrenceValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(categoriesViewModelProvider);
    final categories = categoriesState.categories
        .where((c) => c.type == CategoryType.income || c.type == CategoryType.both)
        .toList();

    return AlertDialog(
      title: Text(widget.recurring == null ? 'Nuevo Ingreso Recurrente' : 'Editar Ingreso Recurrente'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
              ),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Monto', prefixText: '\$ '),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Requerido';
                  if (double.tryParse(v!) == null) return 'Monto inválido';
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: categories.map((c) {
                  return DropdownMenuItem(value: c.id, child: Text(c.name));
                }).toList(),
                onChanged: (v) => setState(() => _selectedCategoryId = v),
                validator: (v) => v == null ? 'Requerido' : null,
              ),
              DropdownButtonFormField<RecurrenceType>(
                value: _selectedRecurrenceType,
                decoration: const InputDecoration(labelText: 'Tipo de recurrencia'),
                items: RecurrenceType.values.map((type) {
                  String label;
                  switch (type) {
                    case RecurrenceType.daily:
                      label = 'Diario';
                      break;
                    case RecurrenceType.weekly:
                      label = 'Semanal';
                      break;
                    case RecurrenceType.monthly:
                      label = 'Mensual';
                      break;
                    case RecurrenceType.yearly:
                      label = 'Anual';
                      break;
                  }
                  return DropdownMenuItem(value: type, child: Text(label));
                }).toList(),
                onChanged: (v) => setState(() => _selectedRecurrenceType = v!),
              ),
              TextFormField(
                controller: _recurrenceValueController,
                decoration: const InputDecoration(labelText: 'Cada cuántos'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Requerido';
                  if (int.tryParse(v!) == null || int.parse(v) <= 0) return 'Valor inválido';
                  return null;
                },
              ),
              ListTile(
                title: const Text('Fecha de inicio'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_startDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) setState(() => _startDate = date);
                },
              ),
              CheckboxListTile(
                title: const Text('Fecha de fin opcional'),
                value: _endDate != null,
                onChanged: (v) {
                  setState(() {
                    _endDate = v == true ? DateTime.now().add(const Duration(days: 365)) : null;
                  });
                },
              ),
              if (_endDate != null)
                ListTile(
                  title: const Text('Fecha de fin'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(_endDate!)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _endDate!,
                      firstDate: _startDate,
                      lastDate: DateTime(2100),
                    );
                    if (date != null) setState(() => _endDate = date);
                  },
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate() && _selectedCategoryId != null) {
              final recurring = RecurringIncome(
                id: widget.recurring?.id ?? '',
                description: _descriptionController.text,
                amount: double.parse(_amountController.text),
                categoryId: _selectedCategoryId!,
                recurrenceType: _selectedRecurrenceType,
                recurrenceValue: int.parse(_recurrenceValueController.text),
                startDate: _startDate,
                endDate: _endDate,
                lastExecuted: widget.recurring?.lastExecuted,
                isActive: widget.recurring?.isActive ?? true,
                createdAt: widget.recurring?.createdAt ?? DateTime.now(),
                updatedAt: DateTime.now(),
              );
              widget.onSave(recurring);
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

