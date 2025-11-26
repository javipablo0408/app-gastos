import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:app_contabilidad/presentation/viewmodels/financial_projection_viewmodel.dart';
import 'package:app_contabilidad/data/services/financial_projection_service.dart';
import 'package:app_contabilidad/core/widgets/loading_widget.dart';
import 'package:app_contabilidad/presentation/widgets/bottom_navigation.dart';

/// Página de proyecciones financieras
class FinancialProjectionPage extends ConsumerStatefulWidget {
  const FinancialProjectionPage({super.key});

  @override
  ConsumerState<FinancialProjectionPage> createState() => _FinancialProjectionPageState();
}

class _FinancialProjectionPageState extends ConsumerState<FinancialProjectionPage> {
  DateTime? _startDate;
  DateTime? _endDate;
  int _monthsToProject = 6;
  final _tabController = PageController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _endDate = now;
    _startDate = DateTime(now.year, now.month - 3, 1); // Últimos 3 meses
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(financialProjectionViewModelProvider);
    final viewModel = ref.read(financialProjectionViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Proyecciones Financieras'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(context, viewModel),
          ),
        ],
      ),
      body: state.isLoading
          ? const LoadingWidget()
          : state.error != null
              ? _buildErrorState(context, state.error!, viewModel)
              : state.projection == null
                  ? _buildEmptyState(context, viewModel)
                  : PageView(
                      controller: _tabController,
                      children: [
                        _buildProjectionView(context, state),
                        _buildScenarioView(context, state, viewModel),
                      ],
                    ),
      bottomNavigationBar: BottomNavigation(currentIndex: 3),
    );
  }

  Widget _buildEmptyState(BuildContext context, FinancialProjectionViewModel viewModel) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.trending_up,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Sin Proyecciones',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Calcula una proyección para ver tu balance futuro',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showSettingsDialog(context, viewModel),
            icon: const Icon(Icons.calculate),
            label: const Text('Calcular Proyección'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error, FinancialProjectionViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Error al calcular proyección',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.red[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showSettingsDialog(context, viewModel),
              icon: const Icon(Icons.refresh),
              label: const Text('Intentar de nuevo'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectionView(BuildContext context, FinancialProjectionState state) {
    final proj = state.projection!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumen
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumen Actual',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryRow(
                    context,
                    'Balance Actual',
                    proj.currentBalance,
                    proj.currentBalance >= 0 ? Colors.green : Colors.red,
                  ),
                  _buildSummaryRow(
                    context,
                    'Ingreso Promedio Mensual',
                    proj.averageMonthlyIncome,
                    Colors.blue,
                  ),
                  _buildSummaryRow(
                    context,
                    'Gasto Promedio Mensual',
                    proj.averageMonthlyExpense,
                    Colors.orange,
                  ),
                  _buildSummaryRow(
                    context,
                    'Ahorro Mensual',
                    proj.monthlySavings,
                    proj.monthlySavings >= 0 ? Colors.green : Colors.red,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Gráfico de proyección
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Proyección de Balance',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: proj.projections.isEmpty
                        ? Center(
                            child: Text(
                              'No hay datos para mostrar',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          )
                        : LineChart(
                            LineChartData(
                              gridData: FlGridData(show: true),
                              titlesData: FlTitlesData(
                                show: true,
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        '\$${value.toStringAsFixed(0)}',
                                        style: const TextStyle(fontSize: 10),
                                      );
                                    },
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      if (value.toInt() == 0) {
                                        return const Text('Actual', style: TextStyle(fontSize: 10));
                                      }
                                      if (value.toInt() <= proj.projections.length) {
                                        return Text(
                                          'M${value.toInt()}',
                                          style: const TextStyle(fontSize: 10),
                                        );
                                      }
                                      return const Text('');
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: true),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: [
                                    FlSpot(0, proj.currentBalance),
                                    ...proj.projections.asMap().entries.map((e) {
                                      return FlSpot(
                                        (e.key + 1).toDouble(),
                                        e.value.projectedBalance,
                                      );
                                    }),
                                  ],
                                  isCurved: true,
                                  color: Colors.blue,
                                  barWidth: 3,
                                  dotData: FlDotData(show: true),
                                  belowBarData: BarAreaData(show: false),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Tabla de proyecciones
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Proyección Mensual',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                ...proj.projections.map((p) => ListTile(
                      title: Text(DateFormat('MMMM yyyy', 'es').format(p.month)),
                      subtitle: Text('Balance: \$${p.projectedBalance.toStringAsFixed(2)}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Ing: \$${p.projectedIncome.toStringAsFixed(2)}',
                            style: TextStyle(color: Colors.blue, fontSize: 12),
                          ),
                          Text(
                            'Gas: \$${p.projectedExpense.toStringAsFixed(2)}',
                            style: TextStyle(color: Colors.orange, fontSize: 12),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioView(
    BuildContext context,
    FinancialProjectionState state,
    FinancialProjectionViewModel viewModel,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Simulador de Escenarios',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _showScenarioDialog(context, viewModel),
                    child: const Text('Simular Escenario'),
                  ),
                ],
              ),
            ),
          ),
          if (state.scenarioResult != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resultado del Escenario',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryRow(
                      context,
                      'Ahorro Mensual Actual',
                      state.scenarioResult!.currentMonthlySavings,
                      Colors.blue,
                    ),
                    _buildSummaryRow(
                      context,
                      'Ahorro Mensual Proyectado',
                      state.scenarioResult!.projectedMonthlySavings,
                      state.scenarioResult!.projectedMonthlySavings >=
                              state.scenarioResult!.currentMonthlySavings
                          ? Colors.green
                          : Colors.red,
                    ),
                    _buildSummaryRow(
                      context,
                      'Diferencia',
                      state.scenarioResult!.difference,
                      state.scenarioResult!.difference >= 0 ? Colors.green : Colors.red,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '\$${value.toStringAsFixed(2)}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context, FinancialProjectionViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Configurar Proyección'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Fecha Inicio del Período Histórico'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_startDate != null
                        ? DateFormat('dd/MM/yyyy').format(_startDate!)
                        : 'Seleccionar'),
                    const SizedBox(height: 4),
                    Text(
                      'Inicio del rango de datos históricos para calcular promedios',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _startDate ?? DateTime.now(),
                    firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _startDate = date);
                  }
                },
              ),
              ListTile(
                title: const Text('Fecha Fin del Período Histórico'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_endDate != null
                        ? DateFormat('dd/MM/yyyy').format(_endDate!)
                        : 'Seleccionar'),
                    const SizedBox(height: 4),
                    Text(
                      'Fin del rango de datos históricos (hasta hoy)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _endDate ?? DateTime.now(),
                    firstDate: _startDate ?? DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _endDate = date);
                  }
                },
              ),
              const Divider(),
              ListTile(
                title: const Text('Meses a Proyectar'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$_monthsToProject meses'),
                    const SizedBox(height: 4),
                    Text(
                      'Cantidad de meses futuros a proyectar',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        if (_monthsToProject > 1) {
                          setState(() => _monthsToProject--);
                        }
                      },
                    ),
                    Text('$_monthsToProject'),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        setState(() => _monthsToProject++);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_startDate == null || _endDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Selecciona las fechas')),
                  );
                  return;
                }

                if (_startDate!.isAfter(_endDate!)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('La fecha inicio debe ser anterior a la fecha fin')),
                  );
                  return;
                }

                Navigator.pop(context);
                
                // Calcular proyección
                await viewModel.calculateProjection(
                  startDate: _startDate!,
                  endDate: _endDate!,
                  monthsToProject: _monthsToProject,
                );
              },
              child: const Text('Calcular'),
            ),
          ],
        ),
      ),
    );
  }

  void _showScenarioDialog(BuildContext context, FinancialProjectionViewModel viewModel) {
    final additionalExpenseController = TextEditingController();
    final additionalIncomeController = TextEditingController();
    final expenseReductionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Simular Escenario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: additionalExpenseController,
              decoration: const InputDecoration(
                labelText: 'Gasto Adicional Mensual (opcional)',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: additionalIncomeController,
              decoration: const InputDecoration(
                labelText: 'Ingreso Adicional Mensual (opcional)',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: expenseReductionController,
              decoration: const InputDecoration(
                labelText: 'Reducción de Gasto Mensual (opcional)',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_startDate != null && _endDate != null) {
                viewModel.simulateScenario(
                  startDate: _startDate!,
                  endDate: _endDate!,
                  additionalExpense: double.tryParse(additionalExpenseController.text),
                  additionalIncome: double.tryParse(additionalIncomeController.text),
                  expenseReduction: double.tryParse(expenseReductionController.text),
                );
                Navigator.pop(context);
                _tabController.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Por favor, calcula una proyección primero'),
                  ),
                );
              }
            },
            child: const Text('Simular'),
          ),
        ],
      ),
    );
  }
}
