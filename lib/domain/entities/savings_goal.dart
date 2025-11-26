import 'package:equatable/equatable.dart';

/// Entidad de objetivo de ahorro
class SavingsGoal extends Equatable {
  final String id;
  final String name;
  final String description;
  final double targetAmount;
  final double currentAmount;
  final DateTime targetDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isCompleted;
  final bool isDeleted;
  final String? syncId;

  const SavingsGoal({
    required this.id,
    required this.name,
    required this.description,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.targetDate,
    required this.createdAt,
    required this.updatedAt,
    this.isCompleted = false,
    this.isDeleted = false,
    this.syncId,
  });

  SavingsGoal copyWith({
    String? id,
    String? name,
    String? description,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isCompleted,
    bool? isDeleted,
    String? syncId,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      isDeleted: isDeleted ?? this.isDeleted,
      syncId: syncId ?? this.syncId,
    );
  }

  /// Calcula el porcentaje completado
  double getCompletionPercentage() {
    if (targetAmount == 0) return 0;
    return (currentAmount / targetAmount * 100).clamp(0, 100);
  }

  /// Calcula el monto restante
  double getRemainingAmount() {
    return (targetAmount - currentAmount).clamp(0, double.infinity);
  }

  /// Calcula días restantes
  int getDaysRemaining() {
    final now = DateTime.now();
    if (targetDate.isBefore(now)) return 0;
    return targetDate.difference(now).inDays;
  }

  /// Calcula el ahorro diario necesario
  double getDailySavingsNeeded() {
    final days = getDaysRemaining();
    if (days == 0) return 0;
    return getRemainingAmount() / days;
  }

  /// Verifica si está cerca del límite (80% o más)
  bool isNearLimit() {
    return getCompletionPercentage() >= 80 && !isCompleted;
  }

  /// Verifica si está completo
  bool isGoalReached() {
    return currentAmount >= targetAmount || isCompleted;
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        targetAmount,
        currentAmount,
        targetDate,
        createdAt,
        updatedAt,
        isCompleted,
        isDeleted,
        syncId,
      ];
}

