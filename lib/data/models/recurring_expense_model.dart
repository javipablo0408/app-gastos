import 'package:drift/drift.dart';
import 'package:app_contabilidad/data/models/database.dart' hide RecurringExpense;
import 'package:app_contabilidad/data/models/database.dart' as drift show RecurringExpense;
import 'package:app_contabilidad/domain/entities/recurring_expense.dart' as domain;
import 'package:app_contabilidad/domain/entities/category.dart' as domain_cat;

/// Extensión para convertir RecurringExpense (entidad) a RecurringExpensesCompanion (modelo)
extension RecurringExpenseModelExtension on domain.RecurringExpense {
  RecurringExpensesCompanion toCompanion() {
    return RecurringExpensesCompanion.insert(
      id: id,
      description: description,
      amount: amount,
      categoryId: categoryId,
      recurrenceType: _recurrenceTypeToInt(recurrenceType),
      recurrenceValue: recurrenceValue,
      startDate: startDate,
      endDate: endDate != null ? Value(endDate) : const Value.absent(),
      lastExecuted: lastExecuted != null ? Value(lastExecuted) : const Value.absent(),
      isActive: Value(isActive),
      createdAt: createdAt,
      updatedAt: updatedAt,
      isDeleted: Value(isDeleted),
      syncId: syncId != null ? Value(syncId) : const Value.absent(),
    );
  }

  int _recurrenceTypeToInt(domain.RecurrenceType type) {
    switch (type) {
      case domain.RecurrenceType.daily:
        return 0;
      case domain.RecurrenceType.weekly:
        return 1;
      case domain.RecurrenceType.monthly:
        return 2;
      case domain.RecurrenceType.yearly:
        return 3;
    }
  }
}

/// Extensión para convertir RecurringExpense (modelo Drift) a RecurringExpense (entidad)
extension RecurringExpenseDataExtension on drift.RecurringExpense {
  domain.RecurringExpense toEntity({domain_cat.Category? category}) {
    return domain.RecurringExpense(
      id: id,
      description: description,
      amount: amount,
      categoryId: categoryId,
      category: category,
      recurrenceType: _intToRecurrenceType(recurrenceType),
      recurrenceValue: recurrenceValue,
      startDate: startDate,
      endDate: endDate,
      lastExecuted: lastExecuted,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isDeleted: isDeleted,
      syncId: syncId,
    );
  }

  domain.RecurrenceType _intToRecurrenceType(int type) {
    switch (type) {
      case 0:
        return domain.RecurrenceType.daily;
      case 1:
        return domain.RecurrenceType.weekly;
      case 2:
        return domain.RecurrenceType.monthly;
      case 3:
        return domain.RecurrenceType.yearly;
      default:
        return domain.RecurrenceType.monthly;
    }
  }
}

