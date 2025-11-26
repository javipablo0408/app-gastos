import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import 'package:dartz/dartz.dart';
import 'package:app_contabilidad/core/errors/failures.dart';
import 'package:app_contabilidad/core/utils/logger.dart';
import 'package:app_contabilidad/core/utils/result.dart';
import 'package:app_contabilidad/data/datasources/local/database_service.dart';

/// Servicio para exportar datos a CSV y JSON
class ExportService {
  final DatabaseService _databaseService;

  ExportService(this._databaseService);

  /// Exporta gastos e ingresos a CSV
  Future<Result<String>> exportToCsv({
    required DateTime startDate,
    required DateTime endDate,
    bool includeExpenses = true,
    bool includeIncomes = true,
  }) async {
    try {
      final List<List<dynamic>> rows = [];
      
      // Encabezados
      rows.add(['Tipo', 'Fecha', 'Descripción', 'Categoría', 'Monto', 'Imagen']);

      // Gastos
      if (includeExpenses) {
        final expensesResult = await _databaseService.getAllExpenses(
          startDate: startDate,
          endDate: endDate,
        );
        expensesResult.fold(
          (failure) => appLogger.e('Error obteniendo gastos', error: failure),
          (expenses) {
            for (final expense in expenses) {
              rows.add([
                'Gasto',
                DateFormat('yyyy-MM-dd').format(expense.date),
                expense.description,
                expense.category?.name ?? 'Sin categoría',
                expense.amount.toStringAsFixed(2),
                expense.receiptImagePath ?? '',
              ]);
            }
          },
        );
      }

      // Ingresos
      if (includeIncomes) {
        final incomesResult = await _databaseService.getAllIncomes(
          startDate: startDate,
          endDate: endDate,
        );
        incomesResult.fold(
          (failure) => appLogger.e('Error obteniendo ingresos', error: failure),
          (incomes) {
            for (final income in incomes) {
              rows.add([
                'Ingreso',
                DateFormat('yyyy-MM-dd').format(income.date),
                income.description,
                income.category?.name ?? 'Sin categoría',
                income.amount.toStringAsFixed(2),
                '',
              ]);
            }
          },
        );
      }

      // Convertir a CSV
      final csvString = const ListToCsvConverter().convert(rows);

      // Guardar archivo
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final filePath = p.join(directory.path, fileName);
      final file = File(filePath);
      await file.writeAsString(csvString);

      appLogger.i('CSV exportado a: $filePath');
      return Right(filePath);
    } catch (e) {
      appLogger.e('Error exportando a CSV', error: e);
      return Left(FileFailure('Error al exportar a CSV: ${e.toString()}'));
    }
  }

  /// Exporta gastos e ingresos a JSON
  Future<Result<String>> exportToJson({
    required DateTime startDate,
    required DateTime endDate,
    bool includeExpenses = true,
    bool includeIncomes = true,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'exportDate': DateTime.now().toIso8601String(),
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'expenses': <Map<String, dynamic>>[],
        'incomes': <Map<String, dynamic>>[],
      };

      // Gastos
      if (includeExpenses) {
        final expensesResult = await _databaseService.getAllExpenses(
          startDate: startDate,
          endDate: endDate,
        );
        expensesResult.fold(
          (failure) => appLogger.e('Error obteniendo gastos', error: failure),
          (expenses) {
            data['expenses'] = expenses.map((e) => {
              'id': e.id,
              'date': e.date.toIso8601String(),
              'description': e.description,
              'category': e.category?.name,
              'amount': e.amount,
              'receiptImagePath': e.receiptImagePath,
              'createdAt': e.createdAt.toIso8601String(),
            }).toList();
          },
        );
      }

      // Ingresos
      if (includeIncomes) {
        final incomesResult = await _databaseService.getAllIncomes(
          startDate: startDate,
          endDate: endDate,
        );
        incomesResult.fold(
          (failure) => appLogger.e('Error obteniendo ingresos', error: failure),
          (incomes) {
            data['incomes'] = incomes.map((i) => {
              'id': i.id,
              'date': i.date.toIso8601String(),
              'description': i.description,
              'category': i.category?.name,
              'amount': i.amount,
              'createdAt': i.createdAt.toIso8601String(),
            }).toList();
          },
        );
      }

      // Convertir a JSON
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);

      // Guardar archivo
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json';
      final filePath = p.join(directory.path, fileName);
      final file = File(filePath);
      await file.writeAsString(jsonString);

      appLogger.i('JSON exportado a: $filePath');
      return Right(filePath);
    } catch (e) {
      appLogger.e('Error exportando a JSON', error: e);
      return Left(FileFailure('Error al exportar a JSON: ${e.toString()}'));
    }
  }
}

