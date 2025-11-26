import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:app_contabilidad/data/models/database.dart' hide SharedExpense;
import 'package:app_contabilidad/data/models/database.dart' as drift show SharedExpense;
import 'package:app_contabilidad/domain/entities/shared_expense.dart' as domain;
import 'package:app_contabilidad/domain/entities/expense.dart' as domain_expense;

/// Extensión para convertir SharedExpense (entidad) a SharedExpensesCompanion (modelo)
extension SharedExpenseModelExtension on domain.SharedExpense {
  SharedExpensesCompanion toCompanion() {
    return SharedExpensesCompanion.insert(
      id: id,
      expenseId: expenseId,
      participants: jsonEncode(participants.map((p) => {
        'id': p.id,
        'name': p.name,
        'paidAmount': p.paidAmount,
        'percentage': p.percentage,
        'amount': p.amount,
      }).toList()),
      splitType: _splitTypeToInt(splitType),
      createdAt: createdAt,
      updatedAt: updatedAt,
      isDeleted: Value(isDeleted),
      syncId: Value(syncId),
    );
  }

  int _splitTypeToInt(domain.SplitType type) {
    switch (type) {
      case domain.SplitType.equal:
        return 0;
      case domain.SplitType.percentage:
        return 1;
      case domain.SplitType.amount:
        return 2;
    }
  }
}

/// Extensión para convertir SharedExpense (modelo Drift) a SharedExpense (entidad)
extension SharedExpenseDataExtension on drift.SharedExpense {
  domain.SharedExpense toEntity({domain_expense.Expense? expense}) {
    final participantsJson = jsonDecode(participants) as List<dynamic>;
    final participantsList = participantsJson.map((p) {
      final map = p as Map<String, dynamic>;
      return domain.Participant(
        id: map['id'] as String,
        name: map['name'] as String,
        paidAmount: (map['paidAmount'] as num).toDouble(),
        percentage: (map['percentage'] as num).toDouble(),
        amount: (map['amount'] as num).toDouble(),
      );
    }).toList();

    return domain.SharedExpense(
      id: id,
      expenseId: expenseId,
      expense: expense,
      participants: participantsList,
      splitType: _intToSplitType(splitType),
      createdAt: createdAt,
      updatedAt: updatedAt,
      isDeleted: isDeleted,
      syncId: syncId,
    );
  }

  domain.SplitType _intToSplitType(int type) {
    switch (type) {
      case 0:
        return domain.SplitType.equal;
      case 1:
        return domain.SplitType.percentage;
      case 2:
        return domain.SplitType.amount;
      default:
        return domain.SplitType.equal;
    }
  }
}

