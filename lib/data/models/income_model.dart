import 'package:drift/drift.dart';
import 'package:app_contabilidad/data/models/database.dart' hide Income;
import 'package:app_contabilidad/data/models/database.dart' as drift show Income;
import 'package:app_contabilidad/domain/entities/income.dart' as domain;
import 'package:app_contabilidad/domain/entities/category.dart' as domain_cat;

/// Extensión para convertir Income (entidad) a IncomeCompanion (modelo)
extension IncomeModelExtension on domain.Income {
  IncomesCompanion toCompanion() {
    return IncomesCompanion.insert(
      id: id,
      amount: amount,
      description: description,
      categoryId: categoryId,
      date: date,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isDeleted: Value(isDeleted),
      syncId: Value(syncId),
      version: Value(version),
    );
  }
}

/// Extensión para convertir Income (modelo Drift) a Income (entidad)
extension IncomeDataExtension on drift.Income {
  domain.Income toEntity({domain_cat.Category? category}) {
    return domain.Income(
      id: id,
      amount: amount,
      description: description,
      categoryId: categoryId,
      category: category,
      date: date,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isDeleted: isDeleted,
      syncId: syncId,
      version: version,
    );
  }
}

