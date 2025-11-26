import 'package:drift/drift.dart';
import 'package:app_contabilidad/data/models/database.dart' hide Category;
import 'package:app_contabilidad/data/models/database.dart' as drift show Category;
import 'package:app_contabilidad/domain/entities/category.dart' as domain;

/// Extensión para convertir Category (entidad) a CategoryCompanion (modelo)
extension CategoryModelExtension on domain.Category {
  CategoriesCompanion toCompanion() {
    return CategoriesCompanion.insert(
      id: id,
      name: name,
      icon: icon,
      color: color,
      imagePath: imagePath != null ? Value(imagePath) : const Value.absent(),
      type: _mapCategoryTypeToInt(type),
      createdAt: createdAt,
      updatedAt: updatedAt,
      isDeleted: Value(isDeleted),
      syncId: Value(syncId),
    );
  }
}

/// Extensión para convertir Category (modelo Drift) a Category (entidad)
extension CategoryDataExtension on drift.Category {
  domain.Category toEntity() {
    return domain.Category(
      id: id,
      name: name,
      icon: icon,
      color: color,
      imagePath: imagePath,
      type: _mapCategoryTypeFromInt(type),
      createdAt: createdAt,
      updatedAt: updatedAt,
      isDeleted: isDeleted,
      syncId: syncId,
    );
  }
}

/// Mapea CategoryType a int
int _mapCategoryTypeToInt(domain.CategoryType type) {
  switch (type) {
    case domain.CategoryType.expense:
      return 0;
    case domain.CategoryType.income:
      return 1;
    case domain.CategoryType.both:
      return 2;
  }
}

/// Mapea int a CategoryType
domain.CategoryType _mapCategoryTypeFromInt(int value) {
  switch (value) {
    case 0:
      return domain.CategoryType.expense;
    case 1:
      return domain.CategoryType.income;
    case 2:
      return domain.CategoryType.both;
    default:
      return domain.CategoryType.expense;
  }
}

