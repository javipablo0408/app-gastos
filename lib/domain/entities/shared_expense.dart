import 'package:equatable/equatable.dart';
import 'package:app_contabilidad/domain/entities/expense.dart';

/// Entidad de gasto compartido
class SharedExpense extends Equatable {
  final String id;
  final String expenseId;
  final Expense? expense;
  final List<Participant> participants;
  final SplitType splitType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final String? syncId;

  const SharedExpense({
    required this.id,
    required this.expenseId,
    this.expense,
    required this.participants,
    required this.splitType,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.syncId,
  });

  SharedExpense copyWith({
    String? id,
    String? expenseId,
    Expense? expense,
    List<Participant>? participants,
    SplitType? splitType,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    String? syncId,
  }) {
    return SharedExpense(
      id: id ?? this.id,
      expenseId: expenseId ?? this.expenseId,
      expense: expense ?? this.expense,
      participants: participants ?? this.participants,
      splitType: splitType ?? this.splitType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      syncId: syncId ?? this.syncId,
    );
  }

  /// Calcula cuánto debe cada participante
  Map<String, double> calculateSplit() {
    final total = expense?.amount ?? 0.0;
    final split = <String, double>{};

    if (participants.isEmpty) {
      return split;
    }

    switch (splitType) {
      case SplitType.equal:
        final perPerson = participants.length > 0 ? total / participants.length : 0.0;
        for (final participant in participants) {
          split[participant.id] = perPerson;
        }
        break;
      case SplitType.percentage:
        for (final participant in participants) {
          split[participant.id] = total * (participant.percentage / 100);
        }
        break;
      case SplitType.amount:
        for (final participant in participants) {
          split[participant.id] = participant.amount;
        }
        break;
    }

    return split;
  }

  /// Calcula quién debe a quién
  List<Debt> calculateDebts() {
    final split = calculateSplit();
    final paid = <String, double>{};
    final debts = <Debt>[];

    // Calcular lo pagado por cada uno
    for (final participant in participants) {
      paid[participant.id] = participant.paidAmount;
    }

    // Calcular deudas
    final creditors = <String, double>{};
    final debtors = <String, double>{};

    for (final entry in split.entries) {
      final participantId = entry.key;
      final shouldPay = entry.value;
      final hasPaid = paid[participantId] ?? 0.0;
      final difference = shouldPay - hasPaid;

      if (difference > 0.01) {
        debtors[participantId] = difference;
      } else if (difference < -0.01) {
        creditors[participantId] = -difference;
      }
    }

    // Emparejar deudores con acreedores
    for (final debtorEntry in debtors.entries) {
      var remainingDebt = debtorEntry.value;
      final debtor = participants.firstWhere((p) => p.id == debtorEntry.key);

      for (final creditorEntry in creditors.entries) {
        if (remainingDebt <= 0.01) break;

        final creditor = participants.firstWhere((p) => p.id == creditorEntry.key);
        final availableCredit = creditorEntry.value;

        if (availableCredit > 0.01) {
          final amount = remainingDebt < availableCredit ? remainingDebt : availableCredit;
          debts.add(Debt(
            fromId: debtor.id,
            fromName: debtor.name,
            toId: creditor.id,
            toName: creditor.name,
            amount: amount,
          ));
          remainingDebt -= amount;
          creditors[creditorEntry.key] = availableCredit - amount;
        }
      }
    }

    return debts;
  }

  @override
  List<Object?> get props => [
        id,
        expenseId,
        expense,
        participants,
        splitType,
        createdAt,
        updatedAt,
        isDeleted,
        syncId,
      ];
}

/// Participante en un gasto compartido
class Participant extends Equatable {
  final String id;
  final String name;
  final double paidAmount;
  final double percentage;
  final double amount;

  const Participant({
    required this.id,
    required this.name,
    this.paidAmount = 0.0,
    this.percentage = 0.0,
    this.amount = 0.0,
  });

  Participant copyWith({
    String? id,
    String? name,
    double? paidAmount,
    double? percentage,
    double? amount,
  }) {
    return Participant(
      id: id ?? this.id,
      name: name ?? this.name,
      paidAmount: paidAmount ?? this.paidAmount,
      percentage: percentage ?? this.percentage,
      amount: amount ?? this.amount,
    );
  }

  @override
  List<Object?> get props => [id, name, paidAmount, percentage, amount];
}

/// Tipo de división
enum SplitType {
  equal, // Dividir igual
  percentage, // Por porcentaje
  amount, // Por monto específico
}

/// Deuda entre participantes
class Debt extends Equatable {
  final String fromId;
  final String fromName;
  final String toId;
  final String toName;
  final double amount;

  const Debt({
    required this.fromId,
    required this.fromName,
    required this.toId,
    required this.toName,
    required this.amount,
  });

  @override
  List<Object?> get props => [fromId, fromName, toId, toName, amount];
}

