import 'package:drift/drift.dart';
import 'package:app_contabilidad/data/models/database.dart' hide RecurringIncome;
import 'package:app_contabilidad/data/models/database.dart' as drift show RecurringIncome;
import 'package:app_contabilidad/domain/entities/recurring_income.dart' as domain;
import 'package:app_contabilidad/domain/entities/category.dart' as domain_cat;
import 'package:app_contabilidad/domain/entities/recurring_expense.dart';

/// Extensión para convertir RecurringIncome (entidad) a RecurringIncomesCompanion (modelo)
extension RecurringIncomeModelExtension on domain.RecurringIncome {
  RecurringIncomesCompanion toCompanion() {
    return RecurringIncomesCompanion.insert(
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

  int _recurrenceTypeToInt(RecurrenceType type) {
    switch (type) {
      case RecurrenceType.daily:
        return 0;
      case RecurrenceType.weekly:
        return 1;
      case RecurrenceType.monthly:
        return 2;
      case RecurrenceType.yearly:
        return 3;
    }
  }
}

/// Extensión para convertir RecurringIncome (modelo Drift) a RecurringIncome (entidad)
extension RecurringIncomeDataExtension on drift.RecurringIncome {
  domain.RecurringIncome toEntity({domain_cat.Category? category}) {
    return domain.RecurringIncome(
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

  RecurrenceType _intToRecurrenceType(int type) {
    switch (type) {
      case 0:
        return RecurrenceType.daily;
      case 1:
        return RecurrenceType.weekly;
      case 2:
        return RecurrenceType.monthly;
      case 3:
        return RecurrenceType.yearly;
      default:
        return RecurrenceType.monthly;
    }
  }
}

