import 'package:equatable/equatable.dart';
import 'package:app_contabilidad/domain/entities/category.dart';

/// Entidad de presupuesto
class Budget extends Equatable {
  final String id;
  final String categoryId;
  final Category? category;
  final double amount;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final String? syncId;

  const Budget({
    required this.id,
    required this.categoryId,
    this.category,
    required this.amount,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.syncId,
  });

  Budget copyWith({
    String? id,
    String? categoryId,
    Category? category,
    double? amount,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    String? syncId,
  }) {
    return Budget(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      syncId: syncId ?? this.syncId,
    );
  }

  /// Calcula el porcentaje usado del presupuesto
  double getUsedPercentage(double usedAmount) {
    if (amount == 0) return 0;
    return (usedAmount / amount * 100).clamp(0, 100);
  }

  /// Verifica si el presupuesto está activo
  bool isActive(DateTime date) {
    return date.isAfter(startDate.subtract(const Duration(days: 1))) &&
        date.isBefore(endDate.add(const Duration(days: 1)));
  }

  @override
  List<Object?> get props => [
        id,
        categoryId,
        category,
        amount,
        startDate,
        endDate,
        createdAt,
        updatedAt,
        isDeleted,
        syncId,
      ];
}

