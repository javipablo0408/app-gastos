import 'package:drift/drift.dart';
import 'package:app_contabilidad/data/models/database.dart' hide Expense;
import 'package:app_contabilidad/data/models/database.dart' as drift show Expense;
import 'package:app_contabilidad/domain/entities/expense.dart' as domain;
import 'package:app_contabilidad/domain/entities/category.dart' as domain_cat;

/// Extensión para convertir Expense (entidad) a ExpenseCompanion (modelo)
extension ExpenseModelExtension on domain.Expense {
  ExpensesCompanion toCompanion() {
    return ExpensesCompanion.insert(
      id: id,
      amount: amount,
      description: description,
      categoryId: categoryId,
      date: date,
      receiptImagePath: Value(receiptImagePath),
      billFilePath: Value(billFilePath),
      createdAt: createdAt,
      updatedAt: updatedAt,
      isDeleted: Value(isDeleted),
      syncId: Value(syncId),
      version: Value(version),
    );
  }
}

/// Extensión para convertir Expense (modelo Drift) a Expense (entidad)
extension ExpenseDataExtension on drift.Expense {
  domain.Expense toEntity({domain_cat.Category? category}) {
    return domain.Expense(
      id: id,
      amount: amount,
      description: description,
      categoryId: categoryId,
      category: category,
      date: date,
      receiptImagePath: receiptImagePath,
      billFilePath: billFilePath,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isDeleted: isDeleted,
      syncId: syncId,
      version: version,
    );
  }
}

