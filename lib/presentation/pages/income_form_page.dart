import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:app_contabilidad/core/router/app_router.dart';
import 'package:app_contabilidad/presentation/viewmodels/incomes_viewmodel.dart';
import 'package:app_contabilidad/presentation/viewmodels/categories_viewmodel.dart';
import 'package:app_contabilidad/presentation/viewmodels/dashboard_viewmodel.dart';
import 'package:app_contabilidad/core/providers/providers.dart';
import 'package:app_contabilidad/domain/entities/income.dart';
import 'package:app_contabilidad/domain/entities/category.dart';

/// Página de formulario de ingreso
class IncomeFormPage extends ConsumerStatefulWidget {
  final String? incomeId;

  const IncomeFormPage({super.key, this.incomeId});

  @override
  ConsumerState<IncomeFormPage> createState() => _IncomeFormPageState();
}

class _IncomeFormPageState extends ConsumerState<IncomeFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _selectedCategoryId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Cargar categorías al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoriesViewModelProvider.notifier).loadCategories();
    });
    if (widget.incomeId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadIncome();
      });
    }
  }

  Future<void> _loadIncome() async {
    final incomesState = ref.read(incomesViewModelProvider);
    final income = incomesState.incomes.firstWhere(
      (i) => i.id == widget.incomeId,
      orElse: () => throw Exception('Ingreso no encontrado'),
    );

    if (mounted) {
      setState(() {
        _amountController.text = income.amount.toString();
        _descriptionController.text = income.description;
        _selectedDate = income.date;
        _selectedCategoryId = income.categoryId;
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(categoriesViewModelProvider);
    final incomesViewModel = ref.read(incomesViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.incomeId == null ? 'Nuevo Ingreso' : 'Editar Ingreso'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Monto
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Monto',
                prefixText: '\$ ',
                hintText: '0.00',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa un monto';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Ingresa un monto válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Descripción
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                hintText: 'Ej: Salario mensual',
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa una descripción';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Categoría
            categoriesState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : categoriesState.categories.isEmpty
                    ? const Text(
                        'No hay categorías disponibles. Por favor, crea una categoría primero.',
                        style: TextStyle(color: Colors.red),
                      )
                    : DropdownButtonFormField<String>(
                        value: _selectedCategoryId,
                        decoration: const InputDecoration(
                          labelText: 'Categoría',
                        ),
                        items: categoriesState.categories
                            .where((c) =>
                                c.type == CategoryType.income || c.type == CategoryType.both)
                            .map((category) {
                          return DropdownMenuItem(
                            value: category.id,
                            child: Text(category.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedCategoryId = value);
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Selecciona una categoría';
                          }
                          return null;
                        },
                      ),
            const SizedBox(height: 16),

            // Fecha
            ListTile(
              title: const Text('Fecha'),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                }
              },
            ),
            const SizedBox(height: 32),

            // Botón guardar
            ElevatedButton(
              onPressed: _isLoading ? null : () => _save(incomesViewModel),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(IncomesViewModel viewModel) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final amount = double.parse(_amountController.text);
    final description = _descriptionController.text;

    if (widget.incomeId == null) {
      // Crear nuevo
      final result = await viewModel.createIncome(
        amount: amount,
        description: description,
        categoryId: _selectedCategoryId!,
        date: _selectedDate,
      );

      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failure.message)),
          );
          setState(() => _isLoading = false);
        },
        (createdIncome) async {
          // Actualizar dashboard
          final dashboardViewModel = ref.read(dashboardViewModelProvider.notifier);
          await dashboardViewModel.addIncomeToDashboard(createdIncome);
          
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ingreso creado')),
            );
          }
        },
      );
    } else {
      // Actualizar existente
      final incomesState = ref.read(incomesViewModelProvider);
      final income = incomesState.incomes.firstWhere(
        (i) => i.id == widget.incomeId,
      );

      final updated = income.copyWith(
        amount: amount,
        description: description,
        categoryId: _selectedCategoryId!,
        date: _selectedDate,
      );

      final result = await viewModel.updateIncome(updated);

      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failure.message)),
          );
          setState(() => _isLoading = false);
        },
        (_) {
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ingreso actualizado')),
            );
          }
        },
      );
    }
  }
}


