import 'package:equatable/equatable.dart';
import 'package:app_contabilidad/domain/entities/category.dart';

/// Entidad de factura/pago
class Bill extends Equatable {
  final String id;
  final String name;
  final String? description;
  final double amount;
  final String? categoryId;
  final Category? category;
  final DateTime dueDate;
  final DateTime? paidDate;
  final bool isPaid;
  final int reminderDays; // Días antes de la fecha de vencimiento para recordatorio
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final String? syncId;

  const Bill({
    required this.id,
    required this.name,
    this.description,
    required this.amount,
    this.categoryId,
    this.category,
    required this.dueDate,
    this.paidDate,
    this.isPaid = false,
    this.reminderDays = 3,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.syncId,
  });

  Bill copyWith({
    String? id,
    String? name,
    String? description,
    double? amount,
    String? categoryId,
    Category? category,
    DateTime? dueDate,
    DateTime? paidDate,
    bool? isPaid,
    int? reminderDays,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    String? syncId,
  }) {
    return Bill(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      paidDate: paidDate ?? this.paidDate,
      isPaid: isPaid ?? this.isPaid,
      reminderDays: reminderDays ?? this.reminderDays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      syncId: syncId ?? this.syncId,
    );
  }

  /// Verifica si la factura está vencida
  bool get isOverdue {
    if (isPaid) return false;
    return DateTime.now().isAfter(dueDate);
  }

  /// Verifica si la factura está próxima a vencer
  bool get isDueSoon {
    if (isPaid) return false;
    final daysUntilDue = dueDate.difference(DateTime.now()).inDays;
    return daysUntilDue <= reminderDays && daysUntilDue >= 0;
  }

  /// Días hasta el vencimiento
  int get daysUntilDue {
    if (isPaid) return 0;
    return dueDate.difference(DateTime.now()).inDays;
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        amount,
        categoryId,
        category,
        dueDate,
        paidDate,
        isPaid,
        reminderDays,
        createdAt,
        updatedAt,
        isDeleted,
        syncId,
      ];
}

