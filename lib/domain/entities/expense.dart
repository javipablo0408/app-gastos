import 'package:equatable/equatable.dart';
import 'package:app_contabilidad/domain/entities/category.dart';

/// Entidad de gasto
class Expense extends Equatable {
  final String id;
  final double amount;
  final String description;
  final String categoryId;
  final Category? category;
  final DateTime date;
  final String? receiptImagePath;
  final String? billFilePath; // Ruta del archivo PDF de factura
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final String? syncId;
  final int version;

  const Expense({
    required this.id,
    required this.amount,
    required this.description,
    required this.categoryId,
    this.category,
    required this.date,
    this.receiptImagePath,
    this.billFilePath,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.syncId,
    this.version = 1,
  });

  Expense copyWith({
    String? id,
    double? amount,
    String? description,
    String? categoryId,
    Category? category,
    DateTime? date,
    String? receiptImagePath,
    String? billFilePath,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    String? syncId,
    int? version,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      date: date ?? this.date,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      billFilePath: billFilePath ?? this.billFilePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      syncId: syncId ?? this.syncId,
      version: version ?? this.version,
    );
  }

  @override
  List<Object?> get props => [
        id,
        amount,
        description,
        categoryId,
        category,
        date,
        receiptImagePath,
        billFilePath,
        createdAt,
        updatedAt,
        isDeleted,
        syncId,
        version,
      ];
}

