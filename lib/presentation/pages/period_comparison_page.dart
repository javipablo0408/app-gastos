import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:app_contabilidad/presentation/viewmodels/period_comparison_viewmodel.dart';
import 'package:app_contabilidad/core/widgets/loading_widget.dart';
import 'package:app_contabilidad/presentation/widgets/bottom_navigation.dart';
import 'package:app_contabilidad/data/services/period_comparison_service.dart' as comp;

/// Página de comparación de períodos
class PeriodComparisonPage extends ConsumerStatefulWidget {
  const PeriodComparisonPage({super.key});

  @override
  ConsumerState<PeriodComparisonPage> createState() => _PeriodComparisonPageState();
}

class _PeriodComparisonPageState extends ConsumerState<PeriodComparisonPage> {
  DateTime? _period1Start;
  DateTime? _period1End;
  DateTime? _period2Start;
  DateTime? _period2End;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Período 1: mes pasado
    _period1Start = DateTime(now.year, now.month - 1, 1);
    _period1End = DateTime(now.year, now.month, 0);
    // Período 2: este mes
    _period2Start = DateTime(now.year, now.month, 1);
    _period2End = now;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(periodComparisonViewModelProvider);
    final viewModel = ref.read(periodComparisonViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comparación de Períodos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(context, viewModel),
          ),
        ],
      ),
      body: state.isLoading
          ? const LoadingWidget()
          : state.comparison == null
              ? _buildEmptyState(context, viewModel)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildComparisonSummary(context, state.comparison!),
                      const SizedBox(height: 16),
                      _buildComparisonChart(context, state.comparison!),
                      const SizedBox(height: 16),
                      _buildDetailedComparison(context, state.comparison!, state),
                    ],
                  ),
                ),
      bottomNavigationBar: BottomNavigation(currentIndex: 3),
    );
  }

  Widget _buildEmptyState(BuildContext context, PeriodComparisonViewModel viewModel) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.compare_arrows,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Sin Comparación',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Selecciona dos períodos para comparar',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showSettingsDialog(context, viewModel),
            icon: const Icon(Icons.compare),
            label: const Text('Comparar Períodos'),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonSummary(BuildContext context, comp.PeriodComparison comparison) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen de Comparación',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildComparisonRow(
              context,
              'Gastos',
              comparison.period1.totalExpenses,
              comparison.period2.totalExpenses,
              comparison.expenseChange,
              comparison.expenseChangePercent,
              Colors.red,
            ),
            const Divider(),
            _buildComparisonRow(
              context,
              'Ingresos',
              comparison.period1.totalIncomes,
              comparison.period2.totalIncomes,
              comparison.incomeChange,
              comparison.incomeChangePercent,
              Colors.green,
            ),
            const Divider(),
            _buildComparisonRow(
              context,
              'Balance',
              comparison.period1.balance,
              comparison.period2.balance,
              comparison.balanceChange,
              null,
              comparison.balanceChange >= 0 ? Colors.green : Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonRow(
    BuildContext context,
    String label,
    double period1Value,
    double period2Value,
    double change,
    double? changePercent,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
            child: Text(
              '\$${period1Value.toStringAsFixed(2)}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              '\$${period2Value.toStringAsFixed(2)}',
              textAlign: TextAlign.center,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  change >= 0 ? '+${change.toStringAsFixed(2)}' : change.toStringAsFixed(2),
                  style: TextStyle(
                    color: change >= 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (changePercent != null)
                  Text(
                    '${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: changePercent >= 0 ? Colors.green : Colors.red,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonChart(BuildContext context, comp.PeriodComparison comparison) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comparación Visual',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: [
                    comparison.period1.totalExpenses,
                    comparison.period1.totalIncomes,
                    comparison.period2.totalExpenses,
                    comparison.period2.totalIncomes,
                  ].reduce((a, b) => a > b ? a : b) * 1.2,
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: comparison.period1.totalExpenses,
                          color: Colors.red[300],
                          width: 20,
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: comparison.period1.totalIncomes,
                          color: Colors.green[300],
                          width: 20,
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 2,
                      barRods: [
                        BarChartRodData(
                          toY: comparison.period2.totalExpenses,
                          color: Colors.red,
                          width: 20,
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 3,
                      barRods: [
                        BarChartRodData(
                          toY: comparison.period2.totalIncomes,
                          color: Colors.green,
                          width: 20,
                        ),
                      ],
                    ),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          switch (value.toInt()) {
                            case 0:
                              return const Text('Gastos\nP1');
                            case 1:
                              return const Text('Ingresos\nP1');
                            case 2:
                              return const Text('Gastos\nP2');
                            case 3:
                              return const Text('Ingresos\nP2');
                            default:
                              return const Text('');
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedComparison(
    BuildContext context,
    comp.PeriodComparison comparison,
    PeriodComparisonState state,
  ) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Detalles por Período',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          ListTile(
            title: const Text('Período 1'),
            subtitle: Text(
              state.period1Start != null && state.period1End != null
                  ? '${DateFormat('dd/MM/yyyy').format(state.period1Start!)} - ${DateFormat('dd/MM/yyyy').format(state.period1End!)}'
                  : 'No seleccionado',
            ),
            trailing: Text(
              '\$${comparison.period1.balance.toStringAsFixed(2)}',
              style: TextStyle(
                color: comparison.period1.balance >= 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            title: const Text('Período 2'),
            subtitle: Text(
              state.period2Start != null && state.period2End != null
                  ? '${DateFormat('dd/MM/yyyy').format(state.period2Start!)} - ${DateFormat('dd/MM/yyyy').format(state.period2End!)}'
                  : 'No seleccionado',
            ),
            trailing: Text(
              '\$${comparison.period2.balance.toStringAsFixed(2)}',
              style: TextStyle(
                color: comparison.period2.balance >= 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context, PeriodComparisonViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Seleccionar Períodos'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Período 1:', style: TextStyle(fontWeight: FontWeight.bold)),
                ListTile(
                  title: const Text('Inicio'),
                  subtitle: Text(_period1Start != null
                      ? DateFormat('dd/MM/yyyy').format(_period1Start!)
                      : 'Seleccionar'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _period1Start ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _period1Start = date);
                    }
                  },
                ),
                ListTile(
                  title: const Text('Fin'),
                  subtitle: Text(_period1End != null
                      ? DateFormat('dd/MM/yyyy').format(_period1End!)
                      : 'Seleccionar'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _period1End ?? DateTime.now(),
                      firstDate: _period1Start ?? DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _period1End = date);
                    }
                  },
                ),
                const Divider(),
                const Text('Período 2:', style: TextStyle(fontWeight: FontWeight.bold)),
                ListTile(
                  title: const Text('Inicio'),
                  subtitle: Text(_period2Start != null
                      ? DateFormat('dd/MM/yyyy').format(_period2Start!)
                      : 'Seleccionar'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _period2Start ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _period2Start = date);
                    }
                  },
                ),
                ListTile(
                  title: const Text('Fin'),
                  subtitle: Text(_period2End != null
                      ? DateFormat('dd/MM/yyyy').format(_period2End!)
                      : 'Seleccionar'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _period2End ?? DateTime.now(),
                      firstDate: _period2Start ?? DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _period2End = date);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_period1Start != null &&
                    _period1End != null &&
                    _period2Start != null &&
                    _period2End != null) {
                  viewModel.comparePeriods(
                    period1Start: _period1Start!,
                    period1End: _period1End!,
                    period2Start: _period2Start!,
                    period2End: _period2End!,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Comparar'),
            ),
          ],
        ),
      ),
    );
  }
}
