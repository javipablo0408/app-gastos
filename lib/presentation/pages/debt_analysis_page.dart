import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_contabilidad/presentation/viewmodels/debt_analysis_viewmodel.dart';
import 'package:app_contabilidad/core/widgets/loading_widget.dart';
import 'package:app_contabilidad/presentation/widgets/bottom_navigation.dart';
import 'package:app_contabilidad/data/services/debt_analysis_service.dart' as debt;

/// Página de análisis de deudas
class DebtAnalysisPage extends ConsumerWidget {
  const DebtAnalysisPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(debtAnalysisViewModelProvider);
    final viewModel = ref.read(debtAnalysisViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Análisis de Deudas'),
      ),
      body: state.isLoading
          ? const LoadingWidget()
          : state.allDebts == null || state.allDebts!.isEmpty
              ? _buildEmptyState(context)
              : RefreshIndicator(
                  onRefresh: () => viewModel.loadAllDebts(),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryCard(context, state),
                        const SizedBox(height: 16),
                        if (state.debtSummary != null)
                          _buildDebtSummaryCard(context, state.debtSummary!),
                        const SizedBox(height: 16),
                        _buildDebtsList(context, state),
                      ],
                    ),
                  ),
                ),
      bottomNavigationBar: BottomNavigation(currentIndex: 3),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay Deudas',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Las deudas aparecerán cuando tengas gastos compartidos',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, DebtAnalysisState state) {
    final totalDebts = state.allDebts?.values.fold<double>(
          0.0,
          (sum, debt) => sum + debt,
        ) ??
        0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen de Deudas',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      '\$${totalDebts.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Text('Total de Deudas'),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '${state.allDebts?.length ?? 0}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Text('Relaciones'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtSummaryCard(BuildContext context, debt.DebtSummary summary) {
    return Card(
      color: summary.netBalance >= 0 ? Colors.green[50] : Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen del Participante',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildSummaryRow(
              context,
              'Total que Debe',
              summary.totalOwed,
              Colors.red,
            ),
            _buildSummaryRow(
              context,
              'Total que le Deben',
              summary.totalOwing,
              Colors.green,
            ),
            const Divider(),
            _buildSummaryRow(
              context,
              'Balance Neto',
              summary.netBalance,
              summary.netBalance >= 0 ? Colors.green : Colors.red,
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    double value,
    Color color, {
    bool isBold = false,
  }) {
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
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 18 : 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtsList(BuildContext context, DebtAnalysisState state) {
    if (state.allDebts == null || state.allDebts!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Deudas Detalladas',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          ...state.allDebts!.entries.map((entry) {
            final parts = entry.key.split('_');
            final fromId = parts[0];
            final toId = parts[1];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.red[100],
                child: const Icon(Icons.arrow_forward, color: Colors.red),
              ),
              title: Text('De $fromId a $toId'),
              subtitle: Text('ID: ${entry.key}'),
              trailing: Text(
                '\$${entry.value.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
