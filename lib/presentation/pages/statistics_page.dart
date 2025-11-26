import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:app_contabilidad/core/providers/providers.dart';
import 'package:app_contabilidad/data/services/statistics_service.dart';

import 'package:app_contabilidad/presentation/viewmodels/statistics_viewmodel.dart';

/// Página de estadísticas avanzadas
class StatisticsPage extends ConsumerWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsState = ref.watch(statisticsViewModelProvider);
    final statsViewModel = ref.read(statisticsViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas Avanzadas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () => _showDateRangeDialog(context, statsViewModel),
          ),
        ],
      ),
      body: statsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : statsState.error != null
              ? Center(child: Text('Error: ${statsState.error}'))
              : statsState.statistics == null
                  ? const Center(child: Text('No hay datos'))
                  : RefreshIndicator(
                      onRefresh: () => statsViewModel.loadStatistics(),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSummaryCards(context, statsState.statistics!),
                            const SizedBox(height: 24),
                            _buildTrendChart(context, statsState.statistics!),
                            const SizedBox(height: 24),
                            _buildCategoryStats(context, statsState.statistics!),
                            const SizedBox(height: 24),
                            _buildMonthlyComparison(context, statsState.statistics!),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, FinancialStatistics stats) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            'Promedio Diario',
            currencyFormat.format(stats.averageDailyExpense),
            Icons.today,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            'Promedio Semanal',
            currencyFormat.format(stats.averageWeeklyExpense),
            Icons.calendar_view_week,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            'Promedio Mensual',
            currencyFormat.format(stats.averageMonthlyExpense),
            Icons.calendar_month,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChart(BuildContext context, FinancialStatistics stats) {
    if (stats.expensesByMonth.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedMonths = stats.expensesByMonth.keys.toList()..sort();
    final spots = sortedMonths.asMap().entries.map((entry) {
      final index = entry.key;
      final monthKey = entry.value;
      final amount = stats.expensesByMonth[monthKey] ?? 0.0;
      return FlSpot(index.toDouble(), amount);
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tendencia de Gastos',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryStats(BuildContext context, FinancialStatistics stats) {
    if (stats.topCategory.isEmpty) {
      return const SizedBox.shrink();
    }

    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Categoría con Mayor Gasto',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.category, size: 40, color: Colors.red),
              title: Text(
                stats.topCategory,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              trailing: Text(
                currencyFormat.format(stats.topCategoryAmount),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyComparison(
    BuildContext context,
    FinancialStatistics stats,
  ) {
    if (stats.monthlyComparisons.isEmpty) {
      return const SizedBox.shrink();
    }

    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comparación Mensual',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...stats.monthlyComparisons.map((comparison) {
              final isPositive = comparison.changeFromPrevious >= 0;
              return ListTile(
                title: Text(comparison.month),
                subtitle: Text(
                  'Gastos: ${currencyFormat.format(comparison.expenses)} | '
                  'Ingresos: ${currencyFormat.format(comparison.incomes)}',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFormat.format(comparison.balance),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: comparison.balance >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                    if (comparison.changeFromPrevious != 0)
                      Text(
                        '${isPositive ? '+' : ''}${comparison.changeFromPrevious.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: isPositive ? Colors.red : Colors.green,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showDateRangeDialog(
    BuildContext context,
    StatisticsViewModel viewModel,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Período'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Este mes'),
              onTap: () {
                final now = DateTime.now();
                viewModel.loadStatistics(
                  startDate: DateTime(now.year, now.month, 1),
                  endDate: now,
                );
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Mes pasado'),
              onTap: () {
                final now = DateTime.now();
                final lastMonth = DateTime(now.year, now.month - 1, 1);
                final lastMonthEnd = DateTime(now.year, now.month, 0);
                viewModel.loadStatistics(
                  startDate: lastMonth,
                  endDate: lastMonthEnd,
                );
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Últimos 3 meses'),
              onTap: () {
                final now = DateTime.now();
                final threeMonthsAgo = DateTime(now.year, now.month - 3, 1);
                viewModel.loadStatistics(
                  startDate: threeMonthsAgo,
                  endDate: now,
                );
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Este año'),
              onTap: () {
                final now = DateTime.now();
                viewModel.loadStatistics(
                  startDate: DateTime(now.year, 1, 1),
                  endDate: now,
                );
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

