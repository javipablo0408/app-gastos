import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:app_contabilidad/presentation/viewmodels/budgets_viewmodel.dart';
import 'package:app_contabilidad/presentation/viewmodels/categories_viewmodel.dart';
import 'package:app_contabilidad/core/providers/providers.dart';
import 'package:app_contabilidad/core/utils/result.dart';
import 'package:app_contabilidad/core/widgets/loading_widget.dart';
import 'package:app_contabilidad/domain/entities/budget.dart';
import 'package:app_contabilidad/data/datasources/local/database_service.dart';

/// Página de gestión de presupuestos
class BudgetsPage extends ConsumerStatefulWidget {
  const BudgetsPage({super.key});

  @override
  ConsumerState<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends ConsumerState<BudgetsPage> {
  @override
  Widget build(BuildContext context) {
    final budgetsState = ref.watch(budgetsViewModelProvider);
    final budgetsViewModel = ref.read(budgetsViewModelProvider.notifier);
    final categoriesState = ref.watch(categoriesViewModelProvider);
    final databaseService = ref.read(databaseServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Presupuestos'),
      ),
      body: budgetsState.isLoading
          ? const LoadingWidget()
          : budgetsState.budgets.isEmpty
              ? _buildEmptyState(context)
              : RefreshIndicator(
                  onRefresh: () => budgetsViewModel.loadBudgets(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: budgetsState.budgets.length,
                    itemBuilder: (context, index) {
                      final budget = budgetsState.budgets[index];
                      return _buildBudgetCard(
                        context,
                        budget,
                        budgetsViewModel,
                        databaseService,
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBudgetDialog(
          context,
          budgetsViewModel,
          categoriesState.categories,
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBudgetCard(
    BuildContext context,
    Budget budget,
    BudgetsViewModel viewModel,
    DatabaseService databaseService,
  ) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFormat = DateFormat('dd/MM/yyyy');
    final now = DateTime.now();
    final isActive = budget.isActive(now);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                        budget.category?.name ?? 'Sin categoría',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${dateFormat.format(budget.startDate)} - ${dateFormat.format(budget.endDate)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _showDeleteDialog(context, budget, viewModel),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Presupuesto',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      currencyFormat.format(budget.amount),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                if (isActive)
                  FutureBuilder<double>(
                    future: _getUsedAmount(budget, databaseService),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }
                      final used = snapshot.data!;
                      final percentage = budget.getUsedPercentage(used);
                      final isOverBudget = used > budget.amount;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Usado: ${currencyFormat.format(used)}',
                            style: TextStyle(
                              color: isOverBudget ? Colors.red : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: (percentage / 100).clamp(0.0, 1.0),
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isOverBudget ? Colors.red : Colors.green,
                            ),
                          ),
                          Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<double> _getUsedAmount(
    Budget budget,
    DatabaseService databaseService,
  ) async {
    final expensesResult = await databaseService.getAllExpenses(
      startDate: budget.startDate,
      endDate: budget.endDate,
      categoryId: budget.categoryId,
    );

    if (expensesResult.isFailure) return 0.0;

    final expenses = expensesResult.valueOrNull ?? [];
    return expenses.fold<double>(0, (sum, expense) => sum + expense.amount);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay presupuestos',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Toca el botón + para agregar uno',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ],
      ),
    );
  }

  void _showAddBudgetDialog(
    BuildContext context,
    BudgetsViewModel viewModel,
    List categories,
  ) {
    final amountController = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;
    String? selectedCategoryId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nuevo Presupuesto'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  items: (categories as List).map<DropdownMenuItem<String>>((category) {
                    return DropdownMenuItem<String>(
                      value: category.id,
                      child: Text(category.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => selectedCategoryId = value);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Monto',
                    prefixText: '\$ ',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Fecha inicio'),
                  subtitle: Text(
                    startDate != null
                        ? DateFormat('dd/MM/yyyy').format(startDate!)
                        : 'Seleccionar',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      setState(() => startDate = date);
                    }
                  },
                ),
                ListTile(
                  title: const Text('Fecha fin'),
                  subtitle: Text(
                    endDate != null
                        ? DateFormat('dd/MM/yyyy').format(endDate!)
                        : 'Seleccionar',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: startDate ?? DateTime.now(),
                      firstDate: startDate ?? DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      setState(() => endDate = date);
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
            TextButton(
              onPressed: () async {
                if (selectedCategoryId == null ||
                    amountController.text.isEmpty ||
                    startDate == null ||
                    endDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Completa todos los campos')),
                  );
                  return;
                }

                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Monto inválido')),
                  );
                  return;
                }

                final result = await viewModel.createBudget(
                  categoryId: selectedCategoryId!,
                  amount: amount,
                  startDate: startDate!,
                  endDate: endDate!,
                );

                result.fold(
                  (failure) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(failure.message)),
                    );
                  },
                  (_) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Presupuesto creado')),
                    );
                  },
                );
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    Budget budget,
    BudgetsViewModel viewModel,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Presupuesto'),
        content: Text(
          '¿Estás seguro de eliminar el presupuesto de "${budget.category?.name ?? 'Sin categoría'}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await viewModel.deleteBudget(budget.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Presupuesto eliminado')),
                );
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}


