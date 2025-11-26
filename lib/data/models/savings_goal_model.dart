import 'package:drift/drift.dart';
import 'package:app_contabilidad/data/models/database.dart' hide SavingsGoal;
import 'package:app_contabilidad/data/models/database.dart' as drift show SavingsGoal;
import 'package:app_contabilidad/domain/entities/savings_goal.dart' as domain;

/// Extensión para convertir SavingsGoal (entidad) a SavingsGoalsCompanion (modelo)
extension SavingsGoalModelExtension on domain.SavingsGoal {
  SavingsGoalsCompanion toCompanion() {
    return SavingsGoalsCompanion.insert(
      id: id,
      name: name,
      description: description,
      targetAmount: targetAmount,
      currentAmount: Value(currentAmount),
      targetDate: targetDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isCompleted: Value(isCompleted),
      isDeleted: Value(isDeleted),
      syncId: Value(syncId),
    );
  }
}

/// Extensión para convertir SavingsGoal (modelo Drift) a SavingsGoal (entidad)
extension SavingsGoalDataExtension on drift.SavingsGoal {
  domain.SavingsGoal toEntity() {
    return domain.SavingsGoal(
      id: id,
      name: name,
      description: description,
      targetAmount: targetAmount,
      currentAmount: currentAmount,
      targetDate: targetDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isCompleted: isCompleted,
      isDeleted: isDeleted,
      syncId: syncId,
    );
  }
}

