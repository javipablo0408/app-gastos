import 'package:drift/drift.dart';
import 'package:app_contabilidad/data/models/database.dart' hide Budget;
import 'package:app_contabilidad/data/models/database.dart' as drift show Budget;
import 'package:app_contabilidad/domain/entities/budget.dart' as domain;
import 'package:app_contabilidad/domain/entities/category.dart' as domain_cat;

/// Extensión para convertir Budget (entidad) a BudgetCompanion (modelo)
extension BudgetModelExtension on domain.Budget {
  BudgetsCompanion toCompanion() {
    return BudgetsCompanion.insert(
      id: id,
      categoryId: categoryId,
      amount: amount,
      startDate: startDate,
      endDate: endDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isDeleted: Value(isDeleted),
      syncId: Value(syncId),
    );
  }
}

/// Extensión para convertir Budget (modelo Drift) a Budget (entidad)
extension BudgetDataExtension on drift.Budget {
  domain.Budget toEntity({domain_cat.Category? category}) {
    return domain.Budget(
      id: id,
      categoryId: categoryId,
      category: category,
      amount: amount,
      startDate: startDate,
      endDate: endDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isDeleted: isDeleted,
      syncId: syncId,
    );
  }
}

