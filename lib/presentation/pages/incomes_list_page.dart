import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:app_contabilidad/presentation/viewmodels/incomes_viewmodel.dart';
import 'package:app_contabilidad/core/widgets/loading_widget.dart';
import 'package:app_contabilidad/presentation/widgets/bottom_navigation.dart';

/// Página de lista de ingresos
class IncomesListPage extends ConsumerStatefulWidget {
  const IncomesListPage({super.key});

  @override
  ConsumerState<IncomesListPage> createState() => _IncomesListPageState();
}

class _IncomesListPageState extends ConsumerState<IncomesListPage> {
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final incomesState = ref.watch(incomesViewModelProvider);
    final incomesViewModel = ref.read(incomesViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ingresos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context, incomesViewModel),
          ),
        ],
      ),
      body: incomesState.isLoading
          ? const LoadingWidget()
          : incomesState.incomes.isEmpty
              ? _buildEmptyState(context)
              : RefreshIndicator(
                  onRefresh: () => incomesViewModel.loadIncomes(
                        startDate: _startDate,
                        endDate: _endDate,
                        categoryId: _selectedCategoryId,
                      ),
                  child: Column(
                    children: [
                      // Resumen
                      _buildSummary(context, incomesState),
                      // Lista
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: incomesState.incomes.length,
                          itemBuilder: (context, index) {
                            final income = incomesState.incomes[index];
                            return _buildIncomeCard(context, income, incomesViewModel);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/incomes/new'),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigation(currentIndex: 2),
    );
  }

  Widget _buildSummary(BuildContext context, IncomesState state) {
    final total = state.incomes.fold<double>(
      0,
      (sum, income) => sum + income.amount,
    );
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Ingresos',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                currencyFormat.format(total),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),
          Text(
            '${state.incomes.length} ${state.incomes.length == 1 ? 'ingreso' : 'ingresos'}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeCard(
    BuildContext context,
    dynamic income,
    IncomesViewModel viewModel,
  ) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade100,
          child: const Icon(Icons.arrow_upward, color: Colors.green),
        ),
        title: Text(
          income.description,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              income.category?.name ?? 'Sin categoría',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              dateFormat.format(income.date),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: Text(
          currencyFormat.format(income.amount),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green,
            fontSize: 16,
          ),
        ),
        onTap: () => context.push('/incomes/${income.id}'),
        onLongPress: () => _showDeleteDialog(context, income, viewModel),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.trending_up,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay ingresos registrados',
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

  void _showFilterDialog(
    BuildContext context,
    IncomesViewModel viewModel,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrar Ingresos'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Fecha inicio'),
              subtitle: Text(
                _startDate != null
                    ? DateFormat('dd/MM/yyyy').format(_startDate!)
                    : 'Seleccionar',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _startDate = date);
                }
              },
            ),
            ListTile(
              title: const Text('Fecha fin'),
              subtitle: Text(
                _endDate != null
                    ? DateFormat('dd/MM/yyyy').format(_endDate!)
                    : 'Seleccionar',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: _startDate ?? DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _endDate = date);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _startDate = null;
                _endDate = null;
                _selectedCategoryId = null;
              });
              viewModel.loadIncomes();
              Navigator.pop(context);
            },
            child: const Text('Limpiar'),
          ),
          TextButton(
            onPressed: () {
              viewModel.loadIncomes(
                startDate: _startDate,
                endDate: _endDate,
                categoryId: _selectedCategoryId,
              );
              Navigator.pop(context);
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    dynamic income,
    IncomesViewModel viewModel,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Ingreso'),
        content: Text('¿Estás seguro de eliminar "${income.description}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await viewModel.deleteIncome(income.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ingreso eliminado')),
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

