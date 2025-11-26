import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:app_contabilidad/core/providers/providers.dart';
import 'package:app_contabilidad/presentation/viewmodels/recurring_expenses_viewmodel.dart';
import 'package:app_contabilidad/presentation/viewmodels/categories_viewmodel.dart';
import 'package:app_contabilidad/domain/entities/recurring_expense.dart';
import 'package:app_contabilidad/domain/entities/category.dart';
import 'package:app_contabilidad/core/widgets/loading_widget.dart';
import 'package:app_contabilidad/core/widgets/error_widget.dart';

/// Página de gastos recurrentes
class RecurringExpensesPage extends ConsumerWidget {
  const RecurringExpensesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recurringExpensesViewModelProvider);
    final viewModel = ref.read(recurringExpensesViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gastos Recurrentes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            tooltip: 'Ejecutar gastos pendientes',
            onPressed: state.isLoading ? null : () async {
              final result = await viewModel.executeDueRecurringExpenses();
              if (context.mounted) {
                result.fold(
                  (failure) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${failure.message}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  },
                  (expenses) {
                    if (expenses.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No hay gastos recurrentes pendientes para ejecutar'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✓ ${expenses.length} gasto(s) creado(s) exitosamente'),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                );
              }
            },
          ),
        ],
      ),
      body: state.isLoading
          ? const LoadingWidget()
          : state.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(
                        state.error!,
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : state.recurringExpenses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.repeat, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No hay gastos recurrentes',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Crea un gasto recurrente para comenzar',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey,
                                ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => viewModel.loadRecurringExpenses(forceRefresh: true),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.recurringExpenses.length,
                        itemBuilder: (context, index) {
                          final recurring = state.recurringExpenses[index];
                          return _buildRecurringExpenseCard(context, ref, recurring, viewModel);
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildRecurringExpenseCard(
    BuildContext context,
    WidgetRef ref,
    RecurringExpense recurring,
    RecurringExpensesViewModel viewModel,
  ) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFormat = DateFormat('dd/MM/yyyy');
    final nextDate = recurring.getNextExecutionDate();

    String recurrenceText;
    switch (recurring.recurrenceType) {
      case RecurrenceType.daily:
        recurrenceText = 'Cada ${recurring.recurrenceValue} día(s)';
        break;
      case RecurrenceType.weekly:
        recurrenceText = 'Cada ${recurring.recurrenceValue} semana(s)';
        break;
      case RecurrenceType.monthly:
        recurrenceText = 'Cada ${recurring.recurrenceValue} mes(es)';
        break;
      case RecurrenceType.yearly:
        recurrenceText = 'Cada ${recurring.recurrenceValue} año(s)';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: recurring.isActive ? Colors.green : Colors.grey,
          child: Icon(
            recurring.isActive ? Icons.repeat : Icons.pause,
            color: Colors.white,
          ),
        ),
        title: Text(recurring.description),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${recurring.category?.name ?? 'Sin categoría'} • $recurrenceText'),
            Text('Monto: ${currencyFormat.format(recurring.amount)}'),
            if (nextDate != null)
              Text(
                'Próxima ejecución: ${dateFormat.format(nextDate)}',
                style: TextStyle(
                  color: recurring.shouldExecuteToday() ? Colors.orange : null,
                  fontWeight: recurring.shouldExecuteToday() ? FontWeight.bold : null,
                ),
              ),
            if (recurring.lastExecuted != null)
              Text(
                'Última ejecución: ${dateFormat.format(recurring.lastExecuted!)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Text('Editar'),
              onTap: () => Future.delayed(
                Duration.zero,
                () => _showEditDialog(context, ref, recurring),
              ),
            ),
            PopupMenuItem(
              child: Text(recurring.isActive ? 'Pausar' : 'Activar'),
              onTap: () => Future.delayed(
                Duration.zero,
                () => viewModel.updateRecurringExpense(
                  recurring.copyWith(isActive: !recurring.isActive),
                ),
              ),
            ),
            PopupMenuItem(
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
              onTap: () => Future.delayed(
                Duration.zero,
                () => _showDeleteDialog(context, ref, recurring.id, viewModel),
              ),
            ),
          ],
        ),
        onTap: () => _showEditDialog(context, ref, recurring),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
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
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, RecurringExpense recurring) {
    showDialog(
      context: context,
      builder: (context) => _RecurringExpenseFormDialog(
        recurring: recurring,
        onSave: (updated) async {
          final viewModel = ref.read(recurringExpensesViewModelProvider.notifier);
          final result = await viewModel.updateRecurringExpense(updated);
          result.fold(
            (failure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(failure.message)),
              );
            },
            (_) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Gasto recurrente actualizado')),
              );
            },
          );
        },
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    String id,
    RecurringExpensesViewModel viewModel,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar gasto recurrente'),
        content: const Text('¿Estás seguro de que deseas eliminar este gasto recurrente?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final result = await viewModel.deleteRecurringExpense(id);
              result.fold(
                (failure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(failure.message)),
                  );
                },
                (_) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gasto recurrente eliminado')),
                  );
                },
              );
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

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
