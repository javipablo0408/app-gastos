import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:app_contabilidad/core/router/app_router.dart';
import 'package:app_contabilidad/presentation/viewmodels/expenses_viewmodel.dart';
import 'package:app_contabilidad/presentation/viewmodels/categories_viewmodel.dart';
import 'package:app_contabilidad/presentation/viewmodels/dashboard_viewmodel.dart';
import 'package:app_contabilidad/core/providers/providers.dart';
import 'package:app_contabilidad/data/datasources/local/file_service.dart';
import 'package:app_contabilidad/data/services/ocr_service.dart';
import 'package:app_contabilidad/domain/entities/expense.dart';
import 'package:app_contabilidad/domain/entities/category.dart';
import 'package:open_filex/open_filex.dart';

/// Página de formulario de gasto
class ExpenseFormPage extends ConsumerStatefulWidget {
  final String? expenseId;

  const ExpenseFormPage({super.key, this.expenseId});

  @override
  ConsumerState<ExpenseFormPage> createState() => _ExpenseFormPageState();
}

class _ExpenseFormPageState extends ConsumerState<ExpenseFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _selectedCategoryId;
  String? _receiptImagePath;
  String? _billFilePath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Cargar categorías al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoriesViewModelProvider.notifier).loadCategories();
    });
    if (widget.expenseId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadExpense();
      });
    }
  }

  Future<void> _loadExpense() async {
    final expensesState = ref.read(expensesViewModelProvider);
    final expense = expensesState.expenses.firstWhere(
      (e) => e.id == widget.expenseId,
      orElse: () => throw Exception('Gasto no encontrado'),
    );

    if (mounted) {
      setState(() {
        _amountController.text = expense.amount.toString();
        _descriptionController.text = expense.description;
        _selectedDate = expense.date;
        _selectedCategoryId = expense.categoryId;
        _receiptImagePath = expense.receiptImagePath;
        _billFilePath = expense.billFilePath;
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
    final expensesViewModel = ref.read(expensesViewModelProvider.notifier);
    final fileService = ref.read(fileServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.expenseId == null ? 'Nuevo Gasto' : 'Editar Gasto'),
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
                hintText: 'Ej: Compra en supermercado',
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
                                c.type == CategoryType.expense || c.type == CategoryType.both)
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
            const SizedBox(height: 16),

            // Imagen de ticket
            if (_receiptImagePath != null)
              Card(
                child: Column(
                  children: [
                    Image.file(
                      File(_receiptImagePath!),
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.broken_image, size: 64);
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _recognizeText(_receiptImagePath!),
                          icon: const Icon(Icons.text_fields),
                          label: const Text('OCR'),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() => _receiptImagePath = null);
                          },
                          child: const Text('Eliminar'),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: () => _pickImage(fileService),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Adjuntar ticket'),
              ),
            const SizedBox(height: 16),

            // Factura PDF
            if (_billFilePath != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.picture_as_pdf, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              p.basename(_billFilePath!),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setState(() => _billFilePath = null);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => _openPDF(_billFilePath!),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Abrir PDF'),
                      ),
                    ],
                  ),
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: () => _pickPDF(fileService),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Adjuntar factura PDF'),
              ),
            const SizedBox(height: 32),

            // Botón guardar
            ElevatedButton(
              onPressed: _isLoading ? null : () => _save(expensesViewModel),
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

  Future<void> _pickImage(FileService fileService) async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar imagen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Cámara'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    setState(() => _isLoading = true);

    final result = source == ImageSource.gallery
        ? await fileService.pickImageFromGallery()
        : await fileService.takePhotoWithCamera();

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
        setState(() => _isLoading = false);
      },
      (imagePath) {
        setState(() {
          _receiptImagePath = imagePath;
          _isLoading = false;
        });
        // Ofrecer reconocimiento OCR
        _offerOCR(imagePath);
      },
    );
  }

  Future<void> _offerOCR(String imagePath) async {
    final shouldRecognize = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reconocer texto del ticket'),
        content: const Text(
          '¿Deseas extraer automáticamente el monto y la descripción del ticket?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reconocer'),
          ),
        ],
      ),
    );

    if (shouldRecognize == true) {
      _recognizeText(imagePath);
    }
  }

  Future<void> _recognizeText(String imagePath) async {
    setState(() => _isLoading = true);

    final ocrService = ref.read(ocrServiceProvider);
    final result = await ocrService.recognizeText(imagePath);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error OCR: ${failure.message}')),
        );
        setState(() => _isLoading = false);
      },
      (ocrResult) {
        setState(() {
          _isLoading = false;
        });

        // Rellenar campos con datos reconocidos
        if (ocrResult.amount != null) {
          _amountController.text = ocrResult.amount!;
        }
        if (ocrResult.description != null) {
          _descriptionController.text = ocrResult.description!;
        }
        if (ocrResult.date != null) {
          _selectedDate = ocrResult.date!;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Texto reconocido${ocrResult.amount != null || ocrResult.description != null ? ': ' : ''}'
              '${ocrResult.amount != null ? 'Monto: ${ocrResult.amount}' : ''}'
              '${ocrResult.amount != null && ocrResult.description != null ? ', ' : ''}'
              '${ocrResult.description != null ? 'Descripción: ${ocrResult.description}' : ''}',
            ),
          ),
        );
      },
    );
  }

  Future<void> _save(ExpensesViewModel viewModel) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final amount = double.parse(_amountController.text);
    final description = _descriptionController.text;

    if (widget.expenseId == null) {
      // Crear nuevo
      final result = await viewModel.createExpense(
        amount: amount,
        description: description,
        categoryId: _selectedCategoryId!,
        date: _selectedDate,
        receiptImagePath: _receiptImagePath,
        billFilePath: _billFilePath,
      );

      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failure.message)),
          );
          setState(() => _isLoading = false);
        },
        (createdExpense) async {
          // Actualizar dashboard
          final dashboardViewModel = ref.read(dashboardViewModelProvider.notifier);
          await dashboardViewModel.addExpenseToDashboard(createdExpense);
          
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Gasto creado')),
            );
          }
        },
      );
    } else {
      // Actualizar existente
      final expensesState = ref.read(expensesViewModelProvider);
      final expense = expensesState.expenses.firstWhere(
        (e) => e.id == widget.expenseId,
      );

      final updated = expense.copyWith(
        amount: amount,
        description: description,
        categoryId: _selectedCategoryId!,
        date: _selectedDate,
        receiptImagePath: _receiptImagePath,
        billFilePath: _billFilePath,
      );

      final result = await viewModel.updateExpense(updated);

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
              const SnackBar(content: Text('Gasto actualizado')),
            );
          }
        },
      );
    }
  }

  Future<void> _pickPDF(FileService fileService) async {
    setState(() => _isLoading = true);

    final result = await fileService.pickPDFFile();

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
        setState(() => _isLoading = false);
      },
      (filePath) {
        setState(() {
          _billFilePath = filePath;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Factura adjuntada correctamente')),
        );
      },
    );
  }

  Future<void> _openPDF(String filePath) async {
    final result = await OpenFilex.open(filePath);
    if (result.type != ResultType.done) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el archivo PDF')),
        );
      }
    }
  }
}

enum ImageSource { gallery, camera }

