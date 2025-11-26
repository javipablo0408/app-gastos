import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:app_contabilidad/presentation/viewmodels/shared_expenses_viewmodel.dart';
import 'package:app_contabilidad/presentation/viewmodels/expenses_viewmodel.dart';
import 'package:app_contabilidad/presentation/viewmodels/categories_viewmodel.dart';
import 'package:app_contabilidad/domain/entities/shared_expense.dart';
import 'package:app_contabilidad/domain/entities/expense.dart';
import 'package:app_contabilidad/domain/entities/category.dart';
import 'package:app_contabilidad/core/widgets/loading_widget.dart';
import 'package:app_contabilidad/presentation/widgets/bottom_navigation.dart';
import 'package:uuid/uuid.dart';

/// Página de gastos compartidos
class SharedExpensesPage extends ConsumerStatefulWidget {
  const SharedExpensesPage({super.key});

  @override
  ConsumerState<SharedExpensesPage> createState() => _SharedExpensesPageState();
}

class _SharedExpensesPageState extends ConsumerState<SharedExpensesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sharedExpensesViewModelProvider.notifier).loadSharedExpenses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sharedExpensesViewModelProvider);
    final viewModel = ref.read(sharedExpensesViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gastos Compartidos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => viewModel.loadSharedExpenses(forceRefresh: true),
          ),
        ],
      ),
      body: state.isLoading
          ? const LoadingWidget()
          : state.error != null
              ? _buildErrorState(context, state.error!, viewModel)
              : state.sharedExpenses.isEmpty
                  ? _buildEmptyState(context, viewModel)
                  : RefreshIndicator(
                      onRefresh: () => viewModel.loadSharedExpenses(forceRefresh: true),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.sharedExpenses.length,
                        itemBuilder: (context, index) {
                          final sharedExpense = state.sharedExpenses[index];
                          return _buildSharedExpenseCard(context, sharedExpense, viewModel);
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSharedExpenseDialog(context, viewModel),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigation(currentIndex: 3),
    );
  }

  Widget _buildErrorState(BuildContext context, String error, SharedExpensesViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.red[600]),
            ),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => viewModel.loadSharedExpenses(forceRefresh: true),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, SharedExpensesViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay gastos compartidos',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega un gasto compartido para dividir gastos entre varias personas',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddSharedExpenseDialog(context, viewModel),
              icon: const Icon(Icons.add),
              label: const Text('Agregar Gasto Compartido'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSharedExpenseCard(
    BuildContext context,
    SharedExpense sharedExpense,
    SharedExpensesViewModel viewModel,
  ) {
    final expense = sharedExpense.expense;
    final debts = sharedExpense.calculateDebts();
    final split = sharedExpense.calculateSplit();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            expense?.description.substring(0, 1).toUpperCase() ?? '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(expense?.description ?? 'Sin descripción'),
        subtitle: Text(
          'Total: \$${expense?.amount.toStringAsFixed(2) ?? '0.00'} • ${sharedExpense.participants.length} participantes',
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
              onTap: () => Future.delayed(
                const Duration(milliseconds: 100),
                () => _showEditSharedExpenseDialog(context, sharedExpense, viewModel),
              ),
            ),
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                ],
              ),
              onTap: () => Future.delayed(
                const Duration(milliseconds: 100),
                () => _confirmDelete(context, sharedExpense.id, viewModel),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Participantes
                Text(
                  'Participantes:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                ...sharedExpense.participants.map((participant) {
                  final amount = split[participant.id] ?? 0.0;
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 16,
                      child: Text(participant.name.substring(0, 1).toUpperCase()),
                    ),
                    title: Text(participant.name),
                    subtitle: Text('Debe: \$${amount.toStringAsFixed(2)}'),
                    trailing: participant.paidAmount > 0
                        ? Chip(
                            label: Text('Pagó: \$${participant.paidAmount.toStringAsFixed(2)}'),
                            backgroundColor: Colors.green[100],
                          )
                        : null,
                  );
                }),
                // Deudas
                if (debts.isNotEmpty) ...[
                  const Divider(),
                  Text(
                    'Deudas:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  ...debts.map((debt) => Card(
                        color: Colors.orange[50],
                        child: ListTile(
                          dense: true,
                          leading: const Icon(Icons.arrow_forward, size: 20),
                          title: Text('${debt.fromName} debe a ${debt.toName}'),
                          trailing: Text(
                            '\$${debt.amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddSharedExpenseDialog(
    BuildContext context,
    SharedExpensesViewModel viewModel,
  ) {
    _showSharedExpenseDialog(context, viewModel);
  }

  void _showEditSharedExpenseDialog(
    BuildContext context,
    SharedExpense sharedExpense,
    SharedExpensesViewModel viewModel,
  ) {
    _showSharedExpenseDialog(context, viewModel, sharedExpense: sharedExpense);
  }

  void _showSharedExpenseDialog(
    BuildContext context,
    SharedExpensesViewModel viewModel, {
    SharedExpense? sharedExpense,
  }) {
    final isEditing = sharedExpense != null;
    final expenseViewModel = ref.read(expensesViewModelProvider.notifier);
    final categoriesState = ref.watch(categoriesViewModelProvider);

    final amountController = TextEditingController(
      text: sharedExpense?.expense?.amount.toString() ?? '',
    );
    final descriptionController = TextEditingController(
      text: sharedExpense?.expense?.description ?? '',
    );
    String? selectedCategoryId = sharedExpense?.expense?.categoryId;
    SplitType selectedSplitType = sharedExpense?.splitType ?? SplitType.equal;
    final participants = <Participant>[
      ...?sharedExpense?.participants,
    ];
    if (participants.isEmpty) {
      participants.add(Participant(
        id: const Uuid().v4(),
        name: 'Yo',
        paidAmount: 0.0,
      ));
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'Editar Gasto Compartido' : 'Nuevo Gasto Compartido'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Monto
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Monto Total',
                    prefixText: '\$ ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                // Descripción
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),
                const SizedBox(height: 16),
                // Categoría
                DropdownButtonFormField<String>(
                  value: selectedCategoryId,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  items: categoriesState.categories
                      .where((c) => c.type == CategoryType.expense || c.type == CategoryType.both)
                      .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => selectedCategoryId = value),
                ),
                const SizedBox(height: 16),
                // Tipo de división
                DropdownButtonFormField<SplitType>(
                  value: selectedSplitType,
                  decoration: const InputDecoration(labelText: 'Tipo de División'),
                  items: const [
                    DropdownMenuItem(value: SplitType.equal, child: Text('Dividir Igual')),
                    DropdownMenuItem(value: SplitType.percentage, child: Text('Por Porcentaje')),
                    DropdownMenuItem(value: SplitType.amount, child: Text('Por Monto')),
                  ],
                  onChanged: (value) => setState(() => selectedSplitType = value ?? SplitType.equal),
                ),
                const SizedBox(height: 16),
                // Participantes
                Text(
                  'Participantes (${participants.length})',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                ...participants.asMap().entries.map((entry) {
                  final index = entry.key;
                  final participant = entry.value;
                  return ListTile(
                    dense: true,
                    title: TextField(
                      controller: TextEditingController(text: participant.name),
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      onChanged: (value) {
                        participants[index] = participant.copyWith(name: value);
                      },
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        setState(() => participants.removeAt(index));
                      },
                    ),
                  );
                }),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      participants.add(Participant(
                        id: const Uuid().v4(),
                        name: '',
                        paidAmount: 0.0,
                      ));
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar Participante'),
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
              onPressed: () async {
                // Validar campos
                if (amountController.text.isEmpty ||
                    descriptionController.text.isEmpty ||
                    selectedCategoryId == null ||
                    participants.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Completa todos los campos')),
                  );
                  return;
                }

                // Validar que todos los participantes tengan nombre
                final participantsWithNames = participants.where((p) => p.name.trim().isNotEmpty).toList();
                if (participantsWithNames.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Al menos un participante debe tener nombre')),
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

                final expense = Expense(
                  id: isEditing ? sharedExpense!.expenseId : const Uuid().v4(),
                  amount: amount,
                  description: descriptionController.text,
                  categoryId: selectedCategoryId!,
                  date: DateTime.now(),
                  createdAt: isEditing ? sharedExpense!.expense!.createdAt : DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                // Mostrar indicador de carga
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator()),
                );

                try {
                  if (isEditing) {
                    final result = await viewModel.updateSharedExpense(
                      sharedExpense!.copyWith(
                        expense: expense,
                        participants: participantsWithNames,
                        splitType: selectedSplitType,
                      ),
                    );

                    if (context.mounted) {
                      Navigator.pop(context); // Cerrar diálogo de carga
                      
                      result.fold(
                        (failure) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: ${failure.message}')),
                          );
                        },
                        (_) {
                          Navigator.pop(context); // Cerrar diálogo de formulario
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Gasto compartido actualizado')),
                          );
                        },
                      );
                    }
                  } else {
                    final result = await viewModel.createSharedExpense(
                      expense: expense,
                      participants: participantsWithNames,
                      splitType: selectedSplitType,
                    );

                    if (context.mounted) {
                      Navigator.pop(context); // Cerrar diálogo de carga
                      
                      result.fold(
                        (failure) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: ${failure.message}')),
                          );
                        },
                        (_) {
                          Navigator.pop(context); // Cerrar diálogo de formulario
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Gasto compartido creado')),
                          );
                        },
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context); // Cerrar diálogo de carga si está abierto
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error inesperado: ${e.toString()}')),
                    );
                  }
                }
              },
              child: Text(isEditing ? 'Actualizar' : 'Crear'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id, SharedExpensesViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Gasto Compartido'),
        content: const Text('¿Estás seguro de que deseas eliminar este gasto compartido?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await viewModel.deleteSharedExpense(id);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
