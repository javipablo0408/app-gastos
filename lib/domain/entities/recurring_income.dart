import 'package:equatable/equatable.dart';
import 'package:app_contabilidad/domain/entities/category.dart';
import 'package:app_contabilidad/domain/entities/recurring_expense.dart';

/// Entidad de ingreso recurrente
class RecurringIncome extends Equatable {
  final String id;
  final String description;
  final double amount;
  final String categoryId;
  final Category? category;
  final RecurrenceType recurrenceType;
  final int recurrenceValue; // Cada cuántos días/semanas/meses
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? lastExecuted;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final String? syncId;

  const RecurringIncome({
    required this.id,
    required this.description,
    required this.amount,
    required this.categoryId,
    this.category,
    required this.recurrenceType,
    required this.recurrenceValue,
    required this.startDate,
    this.endDate,
    this.lastExecuted,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.syncId,
  });

  RecurringIncome copyWith({
    String? id,
    String? description,
    double? amount,
    String? categoryId,
    Category? category,
    RecurrenceType? recurrenceType,
    int? recurrenceValue,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? lastExecuted,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    String? syncId,
  }) {
    return RecurringIncome(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      recurrenceValue: recurrenceValue ?? this.recurrenceValue,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      lastExecuted: lastExecuted ?? this.lastExecuted,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      syncId: syncId ?? this.syncId,
    );
  }

  /// Calcula la próxima fecha de ejecución
  DateTime? getNextExecutionDate() {
    if (!isActive) return null;
    if (endDate != null && DateTime.now().isAfter(endDate!)) return null;

    final lastExec = lastExecuted ?? startDate;
    DateTime nextDate;

    switch (recurrenceType) {
      case RecurrenceType.daily:
        nextDate = lastExec.add(Duration(days: recurrenceValue));
        break;
      case RecurrenceType.weekly:
        nextDate = lastExec.add(Duration(days: recurrenceValue * 7));
        break;
      case RecurrenceType.monthly:
        nextDate = DateTime(
          lastExec.year,
          lastExec.month + recurrenceValue,
          lastExec.day,
        );
        break;
      case RecurrenceType.yearly:
        nextDate = DateTime(
          lastExec.year + recurrenceValue,
          lastExec.month,
          lastExec.day,
        );
        break;
    }

    if (endDate != null && nextDate.isAfter(endDate!)) {
      return null;
    }

    return nextDate;
  }

  /// Verifica si debe ejecutarse hoy
  bool shouldExecuteToday() {
    if (!isActive) return false;
    if (endDate != null && DateTime.now().isAfter(endDate!)) return false;
    
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    
    // Si nunca se ha ejecutado, verificar si la fecha de inicio es hoy o antes
    if (lastExecuted == null) {
      final startOnly = DateTime(startDate.year, startDate.month, startDate.day);
      // Si la fecha de inicio es hoy o antes, debe ejecutarse
      if (startOnly.isBefore(todayOnly) || startOnly.isAtSameMomentAs(todayOnly)) {
        return true;
      }
      return false;
    }
    
    // Si ya se ha ejecutado, verificar si la próxima fecha de ejecución es hoy
    final nextDate = getNextExecutionDate();
    if (nextDate == null) return false;
    
    final nextOnly = DateTime(nextDate.year, nextDate.month, nextDate.day);
    return nextOnly.isAtSameMomentAs(todayOnly);
  }

  @override
  List<Object?> get props => [
        id,
        description,
        amount,
        categoryId,
        category,
        recurrenceType,
        recurrenceValue,
        startDate,
        endDate,
        lastExecuted,
        isActive,
        createdAt,
        updatedAt,
        isDeleted,
        syncId,
      ];
}

