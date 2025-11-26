import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import 'package:app_contabilidad/core/errors/failures.dart';
import 'package:app_contabilidad/core/utils/logger.dart';
import 'package:app_contabilidad/core/utils/result.dart';
import 'package:app_contabilidad/data/datasources/local/database_service.dart';
import 'package:app_contabilidad/domain/entities/expense.dart';
import 'package:app_contabilidad/domain/entities/income.dart';
import 'package:app_contabilidad/domain/entities/category.dart';

/// Servicio para generar reportes en PDF y Excel
class ReportService {
  final DatabaseService _databaseService;

  ReportService(this._databaseService);

  // ==================== PDF ====================

  /// Genera un reporte PDF de gastos e ingresos
  Future<Result<String>> generatePdfReport({
    required DateTime startDate,
    required DateTime endDate,
    bool includeExpenses = true,
    bool includeIncomes = true,
  }) async {
    try {
      // Cargar datos
      final expensesResult = includeExpenses
          ? await _databaseService.getAllExpenses(
              startDate: startDate,
              endDate: endDate,
            )
          : null;
      final incomesResult = includeIncomes
          ? await _databaseService.getAllIncomes(
              startDate: startDate,
              endDate: endDate,
            )
          : null;

      if (expensesResult?.isFailure == true || incomesResult?.isFailure == true) {
        return Left(DatabaseFailure('Error al cargar datos para el reporte'));
      }

      final expenses = expensesResult?.valueOrNull ?? [];
      final incomes = incomesResult?.valueOrNull ?? [];

      // Crear PDF
      final pdf = pw.Document();
      final dateFormat = DateFormat('dd/MM/yyyy');
      final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Encabezado
              pw.Header(
                level: 0,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Reporte de Gastos e Ingresos',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Período: ${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
                      style: pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // Resumen
              _buildSummarySection(expenses, incomes, currencyFormat),
              pw.SizedBox(height: 24),

              // Gastos
              if (includeExpenses && expenses.isNotEmpty) ...[
                pw.Header(level: 1, child: pw.Text('Gastos')),
                pw.SizedBox(height: 12),
                _buildExpensesTable(expenses, currencyFormat, dateFormat),
                pw.SizedBox(height: 24),
              ],

              // Ingresos
              if (includeIncomes && incomes.isNotEmpty) ...[
                pw.Header(level: 1, child: pw.Text('Ingresos')),
                pw.SizedBox(height: 12),
                _buildIncomesTable(incomes, currencyFormat, dateFormat),
              ],
            ];
          },
        ),
      );

      // Guardar PDF
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'reporte_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = p.join(directory.path, fileName);
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      return Right(filePath);
    } catch (e) {
      appLogger.e('Error generating PDF report', error: e);
      return Left(FileFailure('Error al generar reporte PDF: ${e.toString()}'));
    }
  }

  pw.Widget _buildSummarySection(
    List<Expense> expenses,
    List<Income> incomes,
    NumberFormat currencyFormat,
  ) {
    final totalExpenses = expenses.fold<double>(0, (sum, e) => sum + e.amount);
    final totalIncomes = incomes.fold<double>(0, (sum, i) => sum + i.amount);
    final balance = totalIncomes - totalExpenses;

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Total Ingresos', totalIncomes, currencyFormat, PdfColors.green),
          _buildSummaryItem('Total Gastos', totalExpenses, currencyFormat, PdfColors.red),
          _buildSummaryItem('Balance', balance, currencyFormat, PdfColors.blue),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryItem(String label, double value, NumberFormat format, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        pw.SizedBox(height: 4),
        pw.Text(
          format.format(value),
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: color),
        ),
      ],
    );
  }

  pw.Widget _buildExpensesTable(
    List<Expense> expenses,
    NumberFormat currencyFormat,
    DateFormat dateFormat,
  ) {
    return pw.TableHelper.fromTextArray(
      headers: ['Fecha', 'Categoría', 'Descripción', 'Monto'],
      data: expenses.map((e) => [
        dateFormat.format(e.date),
        e.category?.name ?? 'Sin categoría',
        e.description,
        currencyFormat.format(e.amount),
      ]).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.all(8),
    );
  }

  pw.Widget _buildIncomesTable(
    List<Income> incomes,
    NumberFormat currencyFormat,
    DateFormat dateFormat,
  ) {
    return pw.TableHelper.fromTextArray(
      headers: ['Fecha', 'Categoría', 'Descripción', 'Monto'],
      data: incomes.map((i) => [
        dateFormat.format(i.date),
        i.category?.name ?? 'Sin categoría',
        i.description,
        currencyFormat.format(i.amount),
      ]).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.all(8),
    );
  }

  // ==================== EXCEL ====================

  /// Genera un reporte Excel de gastos e ingresos
  Future<Result<String>> generateExcelReport({
    required DateTime startDate,
    required DateTime endDate,
    bool includeExpenses = true,
    bool includeIncomes = true,
  }) async {
    try {
      // Cargar datos
      final expensesResult = includeExpenses
          ? await _databaseService.getAllExpenses(
              startDate: startDate,
              endDate: endDate,
            )
          : null;
      final incomesResult = includeIncomes
          ? await _databaseService.getAllIncomes(
              startDate: startDate,
              endDate: endDate,
            )
          : null;

      if (expensesResult?.isFailure == true || incomesResult?.isFailure == true) {
        return Left(DatabaseFailure('Error al cargar datos para el reporte'));
      }

      final expenses = expensesResult?.valueOrNull ?? [];
      final incomes = incomesResult?.valueOrNull ?? [];

      // Crear Excel
      final excel = Excel.createExcel();
      excel.delete('Sheet1'); // Eliminar hoja por defecto

      final dateFormat = DateFormat('dd/MM/yyyy');
      final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

      // Hoja de Resumen
      final summarySheet = excel['Resumen'];
      summarySheet.appendRow(['Reporte de Gastos e Ingresos']);
      summarySheet.appendRow(['Período', '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}']);
      summarySheet.appendRow([]);
      
      final totalExpenses = expenses.fold<double>(0, (sum, e) => sum + e.amount);
      final totalIncomes = incomes.fold<double>(0, (sum, i) => sum + i.amount);
      final balance = totalIncomes - totalExpenses;

      summarySheet.appendRow(['Total Ingresos', currencyFormat.format(totalIncomes)]);
      summarySheet.appendRow(['Total Gastos', currencyFormat.format(totalExpenses)]);
      summarySheet.appendRow(['Balance', currencyFormat.format(balance)]);

      // Hoja de Gastos
      if (includeExpenses && expenses.isNotEmpty) {
        final expensesSheet = excel['Gastos'];
        expensesSheet.appendRow(['Fecha', 'Categoría', 'Descripción', 'Monto']);
        
        for (final expense in expenses) {
          expensesSheet.appendRow([
            dateFormat.format(expense.date),
            expense.category?.name ?? 'Sin categoría',
            expense.description,
            expense.amount,
          ]);
        }
      }

      // Hoja de Ingresos
      if (includeIncomes && incomes.isNotEmpty) {
        final incomesSheet = excel['Ingresos'];
        incomesSheet.appendRow(['Fecha', 'Categoría', 'Descripción', 'Monto']);
        
        for (final income in incomes) {
          incomesSheet.appendRow([
            dateFormat.format(income.date),
            income.category?.name ?? 'Sin categoría',
            income.description,
            income.amount,
          ]);
        }
      }

      // Guardar Excel
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'reporte_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final filePath = p.join(directory.path, fileName);
      final file = File(filePath);
      await file.writeAsBytes(excel.encode()!);

      return Right(filePath);
    } catch (e) {
      appLogger.e('Error generating Excel report', error: e);
      return Left(FileFailure('Error al generar reporte Excel: ${e.toString()}'));
    }
  }
}

