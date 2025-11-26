import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:app_contabilidad/core/providers/providers.dart';
import 'package:app_contabilidad/presentation/viewmodels/savings_goals_viewmodel.dart';
import 'package:app_contabilidad/domain/entities/savings_goal.dart';
import 'package:app_contabilidad/core/widgets/loading_widget.dart';
import 'package:app_contabilidad/core/widgets/error_widget.dart';

/// Página de objetivos de ahorro
class SavingsGoalsPage extends ConsumerWidget {
  const SavingsGoalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(savingsGoalsViewModelProvider);
    final viewModel = ref.read(savingsGoalsViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Objetivos de Ahorro'),
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
              : state.savingsGoals.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.savings, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No hay objetivos de ahorro',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Crea un objetivo para comenzar a ahorrar',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey,
                                ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => viewModel.loadSavingsGoals(forceRefresh: true),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.savingsGoals.length,
                        itemBuilder: (context, index) {
                          final goal = state.savingsGoals[index];
                          return _buildSavingsGoalCard(context, ref, goal, viewModel);
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSavingsGoalCard(
    BuildContext context,
    WidgetRef ref,
    SavingsGoal goal,
    SavingsGoalsViewModel viewModel,
  ) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFormat = DateFormat('dd/MM/yyyy');
    final percentage = goal.getCompletionPercentage();
    final remaining = goal.getRemainingAmount();
    final daysRemaining = goal.getDaysRemaining();
    final dailyNeeded = goal.getDailySavingsNeeded();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (goal.description.isNotEmpty)
                        Text(
                          goal.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                    ],
                  ),
                ),
                if (goal.isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Completado',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
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
                      'Objetivo',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      currencyFormat.format(goal.targetAmount),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Ahorrado',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      currencyFormat.format(goal.currentAmount),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                goal.isCompleted ? Colors.green : Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${percentage.toStringAsFixed(1)}% completado',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Restante',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      currencyFormat.format(remaining),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Fecha objetivo',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      dateFormat.format(goal.targetDate),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
            if (daysRemaining > 0 && !goal.isCompleted) ...[
              const SizedBox(height: 8),
              Text(
                'Días restantes: $daysRemaining • Necesitas ahorrar ${currencyFormat.format(dailyNeeded)}/día',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            ],
            if (goal.isNearLimit() && !goal.isCompleted)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '¡Estás cerca de tu objetivo!',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.orange.shade900,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showAddMoneyDialog(context, ref, goal.id, viewModel),
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar dinero'),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const Text('Editar'),
                      onTap: () => Future.delayed(
                        Duration.zero,
                        () => _showEditDialog(context, ref, goal),
                      ),
                    ),
                    PopupMenuItem(
                      child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                      onTap: () => Future.delayed(
                        Duration.zero,
                        () => _showDeleteDialog(context, ref, goal.id, viewModel),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _SavingsGoalFormDialog(
        onSave: (goal) async {
          final viewModel = ref.read(savingsGoalsViewModelProvider.notifier);
          final result = await viewModel.createSavingsGoal(
            name: goal.name,
            description: goal.description,
            targetAmount: goal.targetAmount,
            targetDate: goal.targetDate,
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
                const SnackBar(content: Text('Objetivo creado')),
              );
            },
          );
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, SavingsGoal goal) {
    showDialog(
      context: context,
      builder: (context) => _SavingsGoalFormDialog(
        goal: goal,
        onSave: (updated) async {
          final viewModel = ref.read(savingsGoalsViewModelProvider.notifier);
          final result = await viewModel.updateSavingsGoal(updated);
          result.fold(
            (failure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(failure.message)),
              );
            },
            (_) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Objetivo actualizado')),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddMoneyDialog(
    BuildContext context,
    WidgetRef ref,
    String goalId,
    SavingsGoalsViewModel viewModel,
  ) {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar dinero'),
        content: TextFormField(
          controller: amountController,
          decoration: const InputDecoration(
            labelText: 'Monto',
            prefixText: '\$ ',
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Monto inválido')),
                );
                return;
              }
              final result = await viewModel.addToSavingsGoal(goalId, amount);
              result.fold(
                (failure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(failure.message)),
                  );
                },
                (_) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Dinero agregado')),
                  );
                },
              );
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    String id,
    SavingsGoalsViewModel viewModel,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar objetivo'),
        content: const Text('¿Estás seguro de que deseas eliminar este objetivo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final result = await viewModel.deleteSavingsGoal(id);
              result.fold(
                (failure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(failure.message)),
                  );
                },
                (_) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Objetivo eliminado')),
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

class _SavingsGoalFormDialog extends StatefulWidget {
  final SavingsGoal? goal;
  final Function(SavingsGoal) onSave;

  const _SavingsGoalFormDialog({
    this.goal,
    required this.onSave,
  });

  @override
  State<_SavingsGoalFormDialog> createState() => _SavingsGoalFormDialogState();
}

class _SavingsGoalFormDialogState extends State<_SavingsGoalFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetAmountController = TextEditingController();
  DateTime _targetDate = DateTime.now().add(const Duration(days: 30));

  @override
  void initState() {
    super.initState();
    if (widget.goal != null) {
      final g = widget.goal!;
      _nameController.text = g.name;
      _descriptionController.text = g.description;
      _targetAmountController.text = g.targetAmount.toString();
      _targetDate = g.targetDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _targetAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.goal == null ? 'Nuevo Objetivo' : 'Editar Objetivo'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 2,
              ),
              TextFormField(
                controller: _targetAmountController,
                decoration: const InputDecoration(labelText: 'Monto objetivo', prefixText: '\$ '),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Requerido';
                  if (double.tryParse(v!) == null || double.parse(v) <= 0) return 'Monto inválido';
                  return null;
                },
              ),
              ListTile(
                title: const Text('Fecha objetivo'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_targetDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _targetDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) setState(() => _targetDate = date);
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
            if (_formKey.currentState!.validate()) {
              final goal = SavingsGoal(
                id: widget.goal?.id ?? '',
                name: _nameController.text,
                description: _descriptionController.text,
                targetAmount: double.parse(_targetAmountController.text),
                currentAmount: widget.goal?.currentAmount ?? 0.0,
                targetDate: _targetDate,
                createdAt: widget.goal?.createdAt ?? DateTime.now(),
                updatedAt: DateTime.now(),
                isCompleted: widget.goal?.isCompleted ?? false,
              );
              widget.onSave(goal);
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
