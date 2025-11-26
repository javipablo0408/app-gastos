import 'package:drift/drift.dart';
import 'package:app_contabilidad/data/models/database.dart' as db;
import 'package:app_contabilidad/domain/entities/bill.dart';
import 'package:app_contabilidad/data/models/category_model.dart';

/// Extensión para convertir Bill a Companion de Drift
extension BillModelExtension on Bill {
  db.BillsCompanion toCompanion() {
    return db.BillsCompanion(
      id: Value(id),
      name: Value(name),
      description: Value(description),
      amount: Value(amount),
      categoryId: Value(categoryId),
      dueDate: Value(dueDate),
      paidDate: Value(paidDate),
      isPaid: Value(isPaid),
      reminderDays: Value(reminderDays),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      isDeleted: Value(isDeleted),
      syncId: Value(syncId),
    );
  }
}

/// Extensión para convertir Drift Bill a Entity
extension BillDataExtension on db.Bill {
  Bill toEntity({db.Category? category}) {
    return Bill(
      id: id,
      name: name,
      description: description,
      amount: amount,
      categoryId: categoryId,
      category: category?.toEntity(),
      dueDate: dueDate,
      paidDate: paidDate,
      isPaid: isPaid,
      reminderDays: reminderDays,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isDeleted: isDeleted,
      syncId: syncId,
    );
  }
}

