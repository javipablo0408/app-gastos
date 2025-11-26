import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:app_contabilidad/presentation/viewmodels/bills_viewmodel.dart';
import 'package:app_contabilidad/core/widgets/loading_widget.dart';
import 'package:app_contabilidad/presentation/widgets/bottom_navigation.dart';
import 'package:app_contabilidad/domain/entities/bill.dart';
import 'package:app_contabilidad/core/providers/providers.dart';
import 'package:app_contabilidad/domain/entities/category.dart';
import 'package:app_contabilidad/presentation/viewmodels/categories_viewmodel.dart';

/// Página de gestión de facturas
class BillsPage extends ConsumerWidget {
  const BillsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsState = ref.watch(billsViewModelProvider);
    final billsViewModel = ref.read(billsViewModelProvider.notifier);
    final categoriesState = ref.watch(categoriesViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Facturas'),
        actions: [
          IconButton(
            icon: Icon(
              billsState.showUnpaidOnly ? Icons.filter_alt : Icons.filter_alt_outlined,
            ),
            onPressed: () => billsViewModel.toggleUnpaidOnly(),
            tooltip: billsState.showUnpaidOnly ? 'Mostrar todas' : 'Solo pendientes',
          ),
        ],
      ),
      body: billsState.isLoading
          ? const LoadingWidget()
          : billsState.bills.isEmpty
              ? _buildEmptyState(context)
              : RefreshIndicator(
                  onRefresh: () => billsViewModel.loadBills(forceRefresh: true),
                  child: Column(
                    children: [
                      // Resumen
                      _buildSummary(context, billsState),
                      // Lista
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: billsState.bills.length,
                          itemBuilder: (context, index) {
                            final bill = billsState.bills[index];
                            return _buildBillCard(context, bill, billsViewModel);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBillDialog(
          context,
          billsViewModel,
          categoriesState.categories,
        ),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigation(currentIndex: 3),
    );
  }

  Widget _buildSummary(BuildContext context, BillsState state) {
    final unpaid = state.unpaidBills.length;
    final overdue = state.overdueBills.length;
    final dueSoon = state.dueSoonBills.length;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(context, 'Pendientes', unpaid.toString(), Colors.orange),
          _buildSummaryItem(context, 'Vencidas', overdue.toString(), Colors.red),
          _buildSummaryItem(context, 'Próximas', dueSoon.toString(), Colors.blue),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildBillCard(
    BuildContext context,
    Bill bill,
    BillsViewModel viewModel,
  ) {
    final isOverdue = bill.isOverdue;
    final isDueSoon = bill.isDueSoon;
    final daysUntilDue = bill.daysUntilDue;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isOverdue
          ? Colors.red[50]
          : isDueSoon
              ? Colors.orange[50]
              : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isOverdue
              ? Colors.red
              : isDueSoon
                  ? Colors.orange
                  : bill.isPaid
                      ? Colors.green
                      : Colors.blue,
          child: Icon(
            bill.isPaid
                ? Icons.check
                : isOverdue
                    ? Icons.warning
                    : Icons.receipt,
            color: Colors.white,
          ),
        ),
        title: Text(
          bill.name,
          style: TextStyle(
            decoration: bill.isPaid ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (bill.description != null) Text(bill.description!),
            Text(
              'Vence: ${DateFormat('dd/MM/yyyy').format(bill.dueDate)}',
              style: TextStyle(
                color: isOverdue ? Colors.red : isDueSoon ? Colors.orange : null,
                fontWeight: isOverdue || isDueSoon ? FontWeight.bold : null,
              ),
            ),
            if (!bill.isPaid && daysUntilDue >= 0)
              Text(
                'Faltan $daysUntilDue días',
                style: TextStyle(
                  color: isDueSoon ? Colors.orange : Colors.grey[600],
                ),
              ),
            if (bill.isPaid && bill.paidDate != null)
              Text(
                'Pagada: ${DateFormat('dd/MM/yyyy').format(bill.paidDate!)}',
                style: const TextStyle(color: Colors.green),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${bill.amount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isOverdue ? Colors.red : null,
                  ),
            ),
            if (!bill.isPaid)
              IconButton(
                icon: const Icon(Icons.check_circle_outline),
                onPressed: () => viewModel.markAsPaid(bill.id),
                tooltip: 'Marcar como pagada',
              ),
          ],
        ),
        onTap: () => _showEditBillDialog(context, bill, viewModel),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay facturas',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega facturas para llevar un control de tus pagos',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showAddBillDialog(
    BuildContext context,
    BillsViewModel viewModel,
    List<Category> categories,
  ) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 30));
    String? selectedCategoryId;
    int reminderDays = 3;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nueva Factura'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Monto',
                    border: OutlineInputBorder(),
                    prefixText: '\$',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Categoría (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Sin categoría')),
                    ...categories.map((cat) => DropdownMenuItem(
                          value: cat.id,
                          child: Text(cat.name),
                        )),
                  ],
                  onChanged: (value) => setState(() => selectedCategoryId = value),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Fecha de vencimiento'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                    );
                    if (date != null) {
                      setState(() => selectedDate = date);
                    }
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Recordatorio (días antes)'),
                  subtitle: Text('$reminderDays días'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          if (reminderDays > 0) {
                            setState(() => reminderDays--);
                          }
                        },
                      ),
                      Text('$reminderDays'),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setState(() => reminderDays++);
                        },
                      ),
                    ],
                  ),
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
                final amount = double.tryParse(amountController.text);
                if (nameController.text.isNotEmpty && amount != null && amount > 0) {
                  viewModel.createBill(
                    name: nameController.text,
                    description: descriptionController.text.isEmpty
                        ? null
                        : descriptionController.text,
                    amount: amount,
                    categoryId: selectedCategoryId,
                    dueDate: selectedDate,
                    reminderDays: reminderDays,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditBillDialog(
    BuildContext context,
    Bill bill,
    BillsViewModel viewModel,
  ) {
    // Similar a _showAddBillDialog pero con valores prellenados
    // Por simplicidad, aquí solo mostramos un diálogo básico
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(bill.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Monto: \$${bill.amount.toStringAsFixed(2)}'),
            Text('Vence: ${DateFormat('dd/MM/yyyy').format(bill.dueDate)}'),
            if (bill.description != null) Text('Descripción: ${bill.description}'),
            Text('Estado: ${bill.isPaid ? "Pagada" : "Pendiente"}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          if (!bill.isPaid)
            ElevatedButton(
              onPressed: () {
                viewModel.markAsPaid(bill.id);
                Navigator.pop(context);
              },
              child: const Text('Marcar como pagada'),
            ),
        ],
      ),
    );
  }
}

